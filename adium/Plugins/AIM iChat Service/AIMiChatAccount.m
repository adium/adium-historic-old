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

//
extern void* objc_getClass(const char *name);
//

@implementation AIMiChatAccount

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    NSArray	*services;

    //Connect to the iChatAgent
    connection = [NSConnection connectionWithRegisteredName:@"iChat" host:nil];

//    [connection setReplyTimeout:-1];
//    [connection setRequestTimeout:0];
//    [connection setIndependentConversationQueueing:YES];

buddyPropertiesQue = [[NSMutableArray alloc] init];

    FZDaemon = [[connection rootProxy] retain];

    //Get the AIM Service
    services = [FZDaemon allServices];
    AIMService = [[[FZDaemon allServices] objectAtIndex:0] retain];

    //Register as a listener
    [FZDaemon addListener:self  capabilities:15]; //15 is what iChat uses... dunno the meaning    
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
    return([NSString stringWithFormat:@"AIM.%@",[[self accountDescription] compactedString]]);
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

// AIAccount_Handles --------------------------------------------------------------------------------
// Add a handle to the specified groups
- (BOOL)addHandle:(AIContactHandle *)handle toGroup:(AIContactGroup *)group
{
    return(YES);
}

// Remove a handle from the specified groups
- (BOOL)removeHandle:(AIContactHandle *)handle fromGroup:(AIContactGroup *)group
{
    return(YES);
}

// AIAccount_Messaging
- (BOOL)sendContentObject:(id <AIContentObject>)object toHandle:(AIContactHandle *)inHandle
{
    if([object isKindOfClass:[AIContentMessage class]]){
        NSString	*message;
        id		chat;
        id		messageObject;

        message = [[(AIContentMessage *)object message] string];
        //Convert to HTML

        //Create a chat & send the message
        #warning I guess I could cache these chats
	chat = [AIMService createChatForIMsWith:[inHandle UID] isDirect:NO];
        messageObject = [[objc_getClass("FZMessage") alloc] initWithSender:[self accountDescription] time:[NSDate date] format:2 body:message attributes:0 incomingFile:0 outgoingFile:0 inlineFiles:0 flags:5];
        [AIMService sendMessage:messageObject toChat:chat];

    }else{
        NSLog(@"Uknown message object subclass");
        #warning call default handler
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

//Received when out login status changes
- (oneway void)service:(id)inService loginStatusChanged:(int)inStatus message:(id)inMessage reason:(int)inReason
{
    switch(inStatus){
        case 3: //Connecting
            [self setStatus:STATUS_CONNECTING];
            NSLog(@"Connecting: %@",inMessage);
        break;

        case 4: //Online
            [self setStatus:STATUS_ONLINE];
            NSLog(@"Connected: %@",inMessage);
            
            #warning give iChatAgent 2 seconds to flood us with update events
            queEvents = YES;
            [NSTimer scheduledTimerWithTimeInterval:(2.0) target:self selector:@selector(finishSignOn:) userInfo:nil repeats:NO];
            
//            [self service:nil buddyPropertiesChanged:[AIMService buddyProperties]];

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
    
    
    NSLog(@"(%i)%@:%@ [%i,%@]", [inMessage bodyFormat], [inMessage sender], [inMessage body], [inMessage flags], [inMessage time]);

    //Get the handle and message
    handle = [[owner contactController] handleWithService:[service handleServiceType] UID:[inMessage sender] forAccount:self];
    messageText = [AIHTMLDecoder decodeHTML:[inMessage body]];

    //Add the message
    messageObject = [AIContentMessage messageWithSource:handle destination:self date:nil message:messageText];
    [[owner contentController] addIncomingContentObject:messageObject toHandle:handle];
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
        #warning check the 'ISBuddy' key, and if it's NO, use the 'handleWithService' method.
        handle = [[owner contactController] createHandleWithService:[service handleServiceType] UID:compactedName inGroup:[[owner contactController] contactList] forAccount:self];

        if(handle){
            NSNumber		*storedValue;
            NSMutableArray	*alteredStatusKeys;
            AIMutableOwnerArray	*ownerArray;
        
            alteredStatusKeys = [[NSMutableArray alloc] init];
    
            //-- Update the handle's status --
            if((storedValue = [dict objectForKey:@"FZPersonStatus"])){
                int		buddyStatus = [storedValue intValue];
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
                        away = NO;		//TEMP FOR NOW!
                        idleTime = 12;		//TEMP FOR NOW!
                    break;
                    case 3: //Away
                        online = YES;
                        away = YES;
                        idleTime = 0;

                        NSLog(@"%@ Away Message: \"%@\"",compactedName,[dict objectForKey:@"FZPersonStatusMessage"]);

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
            
            //Update the handle's.....
//            NSLog(@"%@ (%i) caps",compactedName, [[dict objectForKey:@"FZPersonCapabilities"] intValue]);
            
            //Update the handle's.....
            
            //Let the contact list know a handle's status changed
            if([alteredStatusKeys count]){
                [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:alteredStatusKeys];
            }
        }
    }
}

- (oneway void)service:(id)service requestOutgoingFileXfer:(id)file{
    NSLog(@"Woot: requestOutgoingFileXfer (%@)",file);
}
- (oneway void)service:(id)service requestIncomingFileXfer:(id)file{
    NSLog(@"Woot: requestIncomingFileXfer (%@)",file);
}
- (oneway void)service:(id)service chat:(id)chat member:(id)member statusChanged:(int)status{
    NSLog(@"Woot: chat:member:statusChanged (%@, %@, %i)",chat,member,status);
}
- (oneway void)service:(id)service chat:(id)chat showError:(id)error{
    NSLog(@"Woot: showError (%@, %i)",chat,error);
}
- (oneway void)service:(id)service chat:(id)chat statusChanged:(int)status{
    NSLog(@"Woot: chat:statusChanged (%@, %i)",chat,status);
}
- (oneway void)service:(id)service directIMRequestFrom:(id)from invitation:(id)invitation{
    NSLog(@"Woot: directIMRequestFrom (%@, %@)",from,invitation);
}
- (oneway void)service:(id)service invitedToChat:(id)chat isChatRoom:(char)isRoom invitation:(id)invitation{
    NSLog(@"Woot: invitedToChat (%@, %i, %@)",chat,isRoom,invitation);
}
- (oneway void)service:(id)service youAreDesignatedNotifier:(char)notifier{
    NSLog(@"Woot: youAreDesignatedNotifier (%i)",(int)notifier);
}
- (oneway void)service:(id)service buddyPictureChanged:(id)buddy imageData:(id)image{
    NSLog(@"Woot: buddyPictureChanged (%@)",buddy);
}
- (oneway void)openNotesChanged:(id)unknown{
    NSLog(@"Woot: openNotesChanged (%@)",unknown);
}
- (oneway void)myStatusChanged:(id)unknown{
    NSLog(@"Woot: myStatusChanged (%@)",unknown);
}


@end
