/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIMiChatAccount.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "InstantMessageFramework.h"

//
extern void* objc_getClass(const char *name);
//

@interface AIMiChatAccount (PRIVATE)
- (void)processProperties:(NSArray *)inProperties;
- (void)removeAllStatusFlagsFromHandle:(AIContactHandle *)handle;
@end

@implementation AIMiChatAccount

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    NSArray	*services;

    //init
    buddyPropertiesQue = [[NSMutableArray alloc] init];

    //Connect to the iChatAgent
    connection = [NSConnection connectionWithRegisteredName:@"iChat" host:nil];
    FZDaemon = [[connection rootProxy] retain];

    //Get the AIM Service
    services = [FZDaemon allServices];
    AIMService = [[[FZDaemon allServices] objectAtIndex:0] retain];

    //Register as a listener
    [FZDaemon addListener:self capabilities:15]; //15 is what iChat uses... dunno the meaning    
    [AIMService addListener:self signature:@"com.adiumX.adium" capabilities:15]; //15 is what iChat uses... dunno the meaning
}

// Return a view for the connection window
- (NSView *)accountView
{
    return(nil);
}

// Return a unique ID for this account type and username
- (NSString *)accountID
{
    return([NSString stringWithFormat:@"iChat.%@",[[self accountDescription] compactedString]]);
}

// Return a readable description of this account's username
- (NSString *)accountDescription
{
    return([AIMService loginID]);
}

// AIAccount_Groups ----------------------------------------------------------------------------------
// Create a group in the specified groups
- (BOOL)addGroup:(AIContactGroup *)newGroup
{
    return(YES);
}

// Remove a group from the specified groups
- (BOOL)removeGroup:(AIContactGroup *)group
{
    return(YES);
}

// Rename a group
- (BOOL)renameGroup:(AIContactGroup *)group to:(NSString *)inName
{
    return(YES);
}

// AIAccount_Contacts --------------------------------------------------------------------------------
// Add an object to the specified groups
- (BOOL)addObject:(AIContactObject *)object
{
    return(YES);
}

// Remove a handle from the specified groups
- (BOOL)removeObject:(AIContactObject *)object
{
    return(YES);
}

- (BOOL)renameObject:(AIContactObject *)object to:(NSString *)inName
{
    return(YES);
}

- (BOOL)contactListEditable
{
    return(NO);
}

// AIAccount_Messaging --------------------------------------------------------------------------------
- (BOOL)sendContentObject:(id <AIContentObject>)object toHandle:(AIContactHandle *)inHandle
{
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSString	*message;
        id		chat;
        id		messageObject;

        message = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message]];

        //Create a chat & send the message
        //(I guess I could cache these chats)
	chat = [AIMService createChatForIMsWith:[inHandle UID] isDirect:NO];
        messageObject = [[FZMessage alloc] initWithSender:[self accountDescription] time:[NSDate date] format:2 body:message attributes:0 incomingFile:0 outgoingFile:0 inlineFiles:0 flags:5];
        [AIMService sendMessage:messageObject toChat:chat];

    }else{
        NSLog(@"Unknown message object subclass");
    }
    
    return(YES);
}


// AIAccount_Status --------------------------------------------------------------------------------
// Return the current connection status
- (ACCOUNT_STATUS)status
{
    return(status);
}

//Connects
- (void)connect
{
    if(status != STATUS_ONLINE){
        [AIMService login];
    }
}

//Disconnects or cancels
- (void)disconnect
{
    if(status != STATUS_OFFLINE){
        [AIMService logout];
    }
}

// Sets the status of this account
- (void)setStatus:(ACCOUNT_STATUS)inStatus
{
    status = inStatus;
    
    //Broadcast a status changed message
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_StatusChanged
                                                      object:self
                                                    userInfo:nil];
}

//Received when our login status changes
- (oneway void)service:(id)inService loginStatusChanged:(int)inStatus message:(id)inMessage reason:(int)inReason
{
    NSEnumerator	*enumerator;
    AIContactHandle	*handle;
    
    switch(inStatus){
        case 0: //Offline
            //Flush all our handle status flags
            enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES ownedBy:self] objectEnumerator];
            while((handle = [enumerator nextObject])){
                [self removeAllStatusFlagsFromHandle:handle];
            }

            //Clean up and close down
            [screenName release]; screenName = nil;
            [self setStatus:STATUS_OFFLINE];
        break;
            
        case 1: //Error
            NSLog(@"Error (status?): %@",inMessage);
        break;
            
        case 2: //Disconnecting
            [self setStatus:STATUS_DISCONNECTING];
        break;
            
        case 3: //Connecting
            [self setStatus:STATUS_CONNECTING];

            //Squelch sounds and updates while we sign on
            [[owner contactController] delayContactListUpdatesFor:10];
        break;

        case 4: //Online
            [self setStatus:STATUS_ONLINE];

            //
            if(screenName) [screenName release];
                screenName = [[AIMService loginID] copy];

            //Give iChatAgent 2 seconds to flood us with update events
            queEvents = YES;
            [NSTimer scheduledTimerWithTimeInterval:(2.0) target:self selector:@selector(finishSignOn:) userInfo:nil repeats:NO];
        break;

        default:
            NSLog(@"Unknown login status: (%i, %@, %i)",inStatus,inMessage,inReason);
        break;
    }
}

- (oneway void)service:(id)inService chat:(id)chat messageReceived:(id)inMessage
{
    AIContactHandle	*handle;
    NSAttributedString	*messageText;
    AIContentMessage	*messageObject;
    int			flags = [inMessage flags];
    
//    NSLog(@"(%i)%@:%@ [%i,%@]", [inMessage bodyFormat], [inMessage sender], [inMessage body], [inMessage flags], [inMessage time]);

    if(flags & kMessageTypingFlag){
        if(!(flags & kMessageOutgoingFlag)){
            NSLog(@"(iChat) %@ is typing",[inMessage sender]);
        }
    }else{
        if(!([inMessage flags] & kMessageOutgoingFlag)){//Ignore echoed messages (anything outgoing)
                                                        //Get the handle and message
            handle = [[owner contactController] handleWithService:[service handleServiceType] UID:[inMessage sender] forAccount:self];
            messageText = [AIHTMLDecoder decodeHTML:[inMessage body]];

            //Add the message
            messageObject = [AIContentMessage messageWithSource:handle destination:self date:nil message:messageText];
            [[owner contentController] addIncomingContentObject:messageObject toHandle:handle];
        }
    }
}

- (oneway void)service:(id)inService buddyPropertiesChanged:(NSArray *)inProperties
{
    /* If we take too long in here, iChatAgent will attempt to call it again, and things will pause for 5 seconds or so.  This mainly causes problems during sign on (where tons of events are happening at once), so during sign on we que all the messages until the flood is complete, and then process them */    

    if(!queEvents){
        //Handle the properties immedientally
        [self processProperties:inProperties];
    }else{
        //Add the properties to our que
        [buddyPropertiesQue addObjectsFromArray:inProperties];
    }
}

- (void)finishSignOn:(NSTimer *)inTimer
{
    queEvents = NO;
    [self processProperties:buddyPropertiesQue];
    [buddyPropertiesQue release]; buddyPropertiesQue = [[NSMutableArray alloc] init];
}

- (void)processProperties:(NSArray *)inProperties
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;

    enumerator = [inProperties objectEnumerator];
    while((dict = [enumerator nextObject])){
        AIContactHandle	*handle;
        NSString	*compactedName;
        
        //Get the handle
        compactedName = [dict objectForKey:@"FZPersonID"];

        //(we should check the 'ISBuddy' key, and if it's NO, use the 'handleWithService' method.)
        if([[dict objectForKey:@"FZPersonIsBuddy"] boolValue]){ //Create them as a buddy
            handle = [[owner contactController] createHandleWithService:[service handleServiceType] UID:compactedName inGroup:nil forAccount:self];
        }else{ //Create them as a stranger
            handle = [[owner contactController] handleWithService:[service handleServiceType] UID:compactedName forAccount:self];
        }
        
        if(handle){
            NSNumber		*storedValue;
            NSMutableArray	*alteredStatusKeys;
            AIMutableOwnerArray	*ownerArray;
        
            alteredStatusKeys = [[NSMutableArray alloc] init];
    
            //-- Update the handle's status --
            if((storedValue = [dict objectForKey:@"FZPersonStatus"])){
                int		buddyStatus = [storedValue intValue];
                NSString	*awayMessage = [dict objectForKey:@"FZPersonStatusMessage"];
                BOOL		online;
                BOOL		away;
                double		idleTime;

                switch(buddyStatus){
                    case 1: //Offline, signed OFF
                        online = NO;
                        away = NO;
                        idleTime = 0;
                    break;
                    case 2: //Idle (or Idle & Away)
                        online = YES;
                        idleTime = 12; //TEMP FOR NOW

                        if(awayMessage){
                            away = YES;
                            NSLog(@"(IDLE & AWAY) %@ Away Message: \"%@\"",compactedName,awayMessage);
                        }else{
                            away = NO;
                        }
                        
                    break;
                    case 3: //Away
                        online = YES;
                        away = YES;
                        idleTime = 0;

                        NSLog(@"(AWAY) %@ Away Message: \"%@\"",compactedName,awayMessage);

                    break;
                    case 4: //Online, signed ON (no ailments)
                        online = YES;
                        away = NO;
                        idleTime = 0;
                    break;
                    default:
                        NSLog(@"%@: unknown status %i",compactedName, buddyStatus);
                    break;
                }
                
                //Online/Offline
                ownerArray = [handle statusArrayForKey:@"Online"];
                storedValue = [ownerArray objectWithOwner:self];
                if(storedValue == nil || online != [storedValue intValue]){
                    [ownerArray removeObjectsWithOwner:self];
                    [ownerArray addObject:[NSNumber numberWithInt:online] withOwner:self];
                    [alteredStatusKeys addObject:@"Online"];
                }
    
                //Idle time (seconds)
                ownerArray = [handle statusArrayForKey:@"Idle"];
                storedValue = [ownerArray objectWithOwner:self];   
                if(storedValue == nil || idleTime != [storedValue doubleValue]){
                    [ownerArray removeObjectsWithOwner:self];
                    [ownerArray addObject:[NSNumber numberWithDouble:idleTime] withOwner:self];
                    [alteredStatusKeys addObject:@"Idle"];
                }
    
                //Away
                ownerArray = [handle statusArrayForKey:@"Away"];
                storedValue = [ownerArray objectWithOwner:self];   
                if(storedValue == nil || away != [storedValue intValue]){
                    [ownerArray removeObjectsWithOwner:self];
                    [ownerArray addObject:[NSNumber numberWithBool:away] withOwner:self];
                    [alteredStatusKeys addObject:@"Away"];
                }
                
            }
            
            //Let the contact list know a handle's status changed
            if([alteredStatusKeys count]){
                [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:alteredStatusKeys];
            }
        }
    }
}

- (oneway void)service:(id)inService requestOutgoingFileXfer:(id)file{
//    NSLog(@"Woot: requestOutgoingFileXfer (%@)",file);
}
- (oneway void)service:(id)inService requestIncomingFileXfer:(id)file{
//    NSLog(@"Woot: requestIncomingFileXfer (%@)",file);
}
- (oneway void)service:(id)inService chat:(id)chat member:(id)member statusChanged:(int)inStatus{
//    NSLog(@"Woot: chat:member:statusChanged (%@, %@, %i)",chat,member,inStatus);
}
- (oneway void)service:(id)inService chat:(id)chat showError:(id)error{
    [[owner interfaceController] handleErrorMessage:[NSString stringWithFormat:@"iChat Error (%@)", screenName] withDescription:error];
}
- (oneway void)service:(id)inService chat:(id)chat statusChanged:(int)inStatus{
//    NSLog(@"Woot: chat:statusChanged (%@, %i)",chat,inStatus);
}
- (oneway void)service:(id)inService directIMRequestFrom:(id)from invitation:(id)invitation{
//    NSLog(@"Woot: directIMRequestFrom (%@, %@)",from,invitation);
}
- (oneway void)service:(id)inService invitedToChat:(id)chat isChatRoom:(char)isRoom invitation:(id)invitation{
    if(!isRoom){
        //Forward new messages to the message recieve code
        [self service:inService chat:chat messageReceived:invitation];

    }else{
//        NSLog(@"Woot: invitedToChat (%@, %i, %@)",chat,isRoom,invitation);
    }    
}
- (oneway void)service:(id)inService youAreDesignatedNotifier:(char)notifier{
    NSLog(@"(iChat)Adium is designated notifier (%i)",(int)notifier);
}
- (oneway void)service:(id)inService buddyPictureChanged:(id)buddy imageData:(id)image{
//    NSLog(@"Woot: buddyPictureChanged (%@)",buddy);
}
- (oneway void)openNotesChanged:(id)unknown{
//    NSLog(@"(iChat)openNotesChanged (%@)",unknown);
}
- (oneway void)myStatusChanged:(id)unknown{
//    NSLog(@"(iChat)myStatusChanged (%@)",unknown);
}

//Removes all the possible status flags (that are valid on AIM/iChat) from the passed handle
- (void)removeAllStatusFlagsFromHandle:(AIContactHandle *)handle
{
    NSArray	*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"Idle",@"Signon Date",@"Away",@"Client",nil];
    int		loop;

    for(loop = 0;loop < [keyArray count];loop++){
        [[handle statusArrayForKey:[keyArray objectAtIndex:loop]] removeObjectsWithOwner:self];
    }

    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray];
}

@end
