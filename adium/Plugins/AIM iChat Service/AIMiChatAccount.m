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
- (void)removeAllStatusFlagsFromHandle:(AIContactHandle *)handle;
- (NSArray *)applyProperties:(NSDictionary *)inProperties toHandle:(AIHandle *)inHandle;
- (void)handle:(AIHandle *)inHandle isIdle:(BOOL)inIdle;
@end

@implementation AIMiChatAccount

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    NSArray	*services;

    //init
    handleDict = [[NSMutableDictionary alloc] init];
    idleHandleArray = nil;
    idleHandleTimer = nil;
    
    //Connect to the iChatAgent
    connection = [NSConnection connectionWithRegisteredName:@"iChat" host:nil];
    FZDaemon = [[connection rootProxy] retain];

    [connection setIndependentConversationQueueing:YES];
    
    //Get the AIM Service
    services   = [FZDaemon allServices];
    AIMService = [[[FZDaemon allServices] objectAtIndex:0] retain];
	
	NSLog (@"Number of services: %i", [services count]);

    //Register as a listener
    [FZDaemon addListener:self capabilities:15]; //15 is what iChat uses... dunno the meaning    
    [AIMService addListener:self signature:@"com.adiumX.adium" capabilities:15]; //15 is what iChat uses... dunno the meaning

    //Clear the online state flag - this account should always load as offline (online state is not restored)
    //Option 2:Clearing the online state, and using the classic 'auto-Connect' option system
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
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
/*- (BOOL)addGroup:(AIContactGroup *)newGroup
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
}*/

// AIAccount_Contacts --------------------------------------------------------------------------------
// Add an object to the specified groups
/*- (BOOL)addObject:(AIContactObject *)object
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
}*/

- (NSDictionary *)availableHandles
{
    return(handleDict);
}

- (BOOL)contactListEditable
{
    return(YES);
}

- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
{
    return(nil);
}

- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    return(YES);
}




// AIAccount_Messaging --------------------------------------------------------------------------------
- (BOOL)sendContentObject:(id <AIContentObject>)object
{
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSString	*message;
        id		chat;
        id		messageObject;

        message = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message]];
		//message = [NSString stringWithFormat:@"<html><body ichatballooncolor=\"#F4DE1F\" ichattextcolor=\"#000000\"><font ABSZ=\"12\" color=\"#000000\" face=\"Helvetica\">%@</font></body></html>", [[(AIContentMessage *) object message] string]];

        //Create a chat & send the message
        //(I guess I could cache these chats)
	chat = [AIMService createChatForIMsWith:[[object destination] UID] isDirect:NO];
        messageObject = [[FZMessage alloc] initWithSender:[self accountDescription] time:[NSDate date] format:2 body:message attributes:0 incomingFile:0 outgoingFile:0 inlineFiles:0 flags:5];
        [AIMService sendMessage:messageObject toChat:chat];

    }else{
        NSLog(@"Unknown message object subclass");
    }
    
    return(YES);
}

- (BOOL)availableForSendingContentType:(NSString *)inType toHandle:(AIHandle *)inHandle
{
    BOOL available = NO;

    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        //If we're online, ("and the contant is online" - implement later), return YES
        if([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_ONLINE){
            available = YES;
        }
    }

    return(available);
}

// AIAccount_Status --------------------------------------------------------------------------------
- (NSArray *)supportedStatusKeys
{
    return([NSArray arrayWithObjects:@"Online", nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    NSLog(@"(%@) \"%@\" changing to [%@]", [self accountDescription], key, inValue);

    if([key compare:@"Online"] == 0){
        ACCOUNT_STATUS status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];

        if([inValue boolValue]){ //Connect
            if((status != STATUS_ONLINE)||(status != STATUS_CONNECTING)){
                [AIMService login];
            }
        }else{ //Disconnect
            if((status != STATUS_OFFLINE)||(status != STATUS_DISCONNECTING)){
                [AIMService logout];
            }
        }
    }
}




// Private --------------------------------------------------------------------------------------------
//Received when our login status changes
- (oneway void)service:(id)inService loginStatusChanged:(int)inStatus message:(id)inMessage reason:(int)inReason
{
    NSEnumerator	*enumerator;
    AIContactHandle	*handle;
    
    switch(inStatus){
        case 0: //Offline
            //Flush all our handle status flags
            [[owner contactController] setHoldContactListUpdates:YES];
            enumerator = [[handleDict allValues] objectEnumerator];
            while((handle = [enumerator nextObject])){
                [self removeAllStatusFlagsFromHandle:handle];
            }
            [[owner contactController] setHoldContactListUpdates:NO];

            //Clean up and close down
            [screenName release]; screenName = nil;
            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
        break;

        case 1: //Error
            NSLog(@"Error (status?): %@",inMessage);
        break;

        case 2: //Disconnecting
            //Squelch sounds and updates while we sign off
//            [[owner contactController] delayContactListUpdatesFor:5];
            NSLog(@"Disconnecting");
            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_DISCONNECTING] forKey:@"Status" account:self];
        break;
            
        case 3: //Connecting
            //Squelch sounds and updates while we sign on
//            [[owner contactController] delayContactListUpdatesFor:10];
            NSLog(@"Connecting");

            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];
        break;

        case 4: //Online
            NSLog(@"Online");
            [[owner contactController] setHoldContactListUpdates:YES];

            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self];
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:self];


            numberOfSignOnUpdates = 0;
            processingSignOnUpdates = YES;

    //        [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(temp:) userInfo:nil repeats:NO];
            
            //Hold onto the account name
            if(screenName) [screenName release];
                screenName = [[AIMService loginID] copy];

            //Check every 0.2 seconds for additional updates
            [NSTimer scheduledTimerWithTimeInterval:(0.2)
                                             target:self
                                           selector:@selector(waitForLastSignOnUpdate:)
                                           userInfo:nil
                                            repeats:YES];

        break;

        default:
            NSLog(@"Unknown login status: (%i, %@, %i)",inStatus,inMessage,inReason);
        break;
    }
}

- (void)waitForLastSignOnUpdate:(NSTimer *)inTimer
{
    if(numberOfSignOnUpdates == 0){
        NSLog(@"Done.");
        //No updates received, sign on is complete
        [inTimer invalidate]; //Stop this timer
        [[owner contactController] handlesChangedForAccount:self]; //
        [[owner contactController] setHoldContactListUpdates:NO]; //Resume contact list updates

    }else{
        NSLog(@"Connecting... (%i)",(int)numberOfSignOnUpdates);
        numberOfSignOnUpdates = 0;
    }
}

/*- (void)temp:(NSTimer *)timer
{
    NSLog(@"tmp unhold");
    
    processingSignOnUpdates = NO;

}*/

- (oneway void)service:(id)inService chat:(id)chat messageReceived:(id)inMessage
{
    AIContactHandle	*handle;
    NSAttributedString	*messageText;
    AIContentMessage	*messageObject;
    int			flags = [inMessage flags];
    
    NSLog(@"(%i)%@:%@ [%i,%@]", [inMessage bodyFormat], [inMessage sender], [inMessage body], [inMessage flags], [inMessage time]);

    if(flags & kMessageTypingFlag){
        if(!(flags & kMessageOutgoingFlag)){
            NSLog(@"(iChat) %@ is typing",[inMessage sender]);
        }
    }else{
        if(!([inMessage flags] & kMessageOutgoingFlag)){//Ignore echoed messages (anything outgoing)
                                                        //Get the handle and message
            handle = [handleDict objectForKey:[inMessage sender]];
            messageText = [AIHTMLDecoder decodeHTML:[inMessage body]];

            //Add the message
            messageObject = [AIContentMessage messageWithSource:handle destination:self date:nil message:messageText];
            [[owner contentController] addIncomingContentObject:messageObject];
        }
    }
}

- (oneway void)service:(id)inService buddyPropertiesChanged:(NSArray *)inProperties
{
    NSEnumerator	*buddyEnumerator;
    NSDictionary	*buddyPropertiesDict;
    
//    NSLog(@"Update %i %@",(int)[inProperties count],inProperties);
    
    buddyEnumerator = [inProperties objectEnumerator];
    while((buddyPropertiesDict = [buddyEnumerator nextObject])){
        NSString	*compactedName = [buddyPropertiesDict objectForKey:@"FZPersonID"];
        AIHandle	*handle;
        NSArray		*modifiedStatusKeys;

        if(processingSignOnUpdates) numberOfSignOnUpdates++; //Keep track of updates during signon
        
        //Get the handle
        handle = [handleDict objectForKey:compactedName];
        if(!handle){ //If the handle doesn't exist
            //Create and add the handle
            handle = [AIHandle handleWithServiceID:[[service handleServiceType] identifier]
                                                UID:compactedName
                                        serverGroup:@"iChat"
                                            temporary:[[buddyPropertiesDict objectForKey:@"FZPersonIsBuddy"] boolValue]
                                        forAccount:self];
            [handleDict setObject:handle forKey:compactedName];

            //Let the contact controller know about the new handle
            // (This is not necessary when signing on, since we let the controller know about all the new handles at once after signon is complete)
            if(!processingSignOnUpdates){
                [[owner contactController] handle:handle addedToAccount:self];
            }

        }

        //Apply the properties, and inform the contact controller of any changes
        modifiedStatusKeys = [self applyProperties:buddyPropertiesDict toHandle:handle];
        if([modifiedStatusKeys count]){
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:modifiedStatusKeys];
        }
        
    }
}

- (NSArray *)applyProperties:(NSDictionary *)inProperties toHandle:(AIHandle *)inHandle
{
    NSNumber		*storedValue;
    NSDate		*storedDate;
    NSMutableArray	*alteredStatusKeys = [[[NSMutableArray alloc] init] autorelease];

    //Status (Online, Away, and Idle)
    if((storedValue = [inProperties objectForKey:@"FZPersonStatusMessage"])){
        NSLog(@"%@ Away Message: \"%@\"",[inHandle UID],storedValue);
    }

    if((storedValue = [inProperties objectForKey:@"FZPersonStatus"])){
        NSMutableDictionary	*handleStatusDict = [inHandle statusDictionary];
        BOOL			online;
        BOOL			away;
        double			idleTime;

        switch([storedValue intValue]){
            case 1: //Offline, signed OFF
                online = NO;
                away = NO;
                idleTime = 0;
            break;
            case 2: //Idle (or Idle & Away)
                online = YES;

                storedDate = [inProperties objectForKey:@"FZPersonAwaySince"];
                idleTime = -([storedDate timeIntervalSinceNow] / 60.0);

                away = NO; //iChat doesn't differentiate between idle and idle+away :(
            break;
            case 3: //Away
                online = YES;
                away = YES;
                idleTime = 0;
            break;
            case 4: //Online, signed ON (no ailments)
                online = YES;
                away = NO;
                idleTime = 0;
            break;
            default:
                NSLog(@"%@: unknown status %i",[inHandle UID], [storedValue intValue]);
            break;
        }

        //Online/Offline
        storedValue = [handleStatusDict objectForKey:@"Online"];
        if(storedValue == nil || online != [storedValue intValue]){
            [handleStatusDict setObject:[NSNumber numberWithInt:online] forKey:@"Online"];
            [alteredStatusKeys addObject:@"Online"];
        }

        //Idle time (seconds)
        storedValue = [handleStatusDict objectForKey:@"Idle"];
        if(storedValue == nil || idleTime != [storedValue doubleValue]){
            [handleStatusDict setObject:[NSNumber numberWithDouble:idleTime] forKey:@"Idle"];
            [alteredStatusKeys addObject:@"Idle"];
            [self handle:inHandle isIdle:(idleTime != 0)]; //Set up the idle tracking for this handle
        }

        //Away
        storedValue = [handleStatusDict objectForKey:@"Away"];
        if(storedValue == nil || away != [storedValue intValue]){
            [handleStatusDict setObject:[NSNumber numberWithBool:away] forKey:@"Away"];
            [alteredStatusKeys addObject:@"Away"];
        }
    }

    return(alteredStatusKeys);
}


//Adds or removes a handle from our idle tracking array
//Handles in the array have their idle times increased every minute
- (void)handle:(AIHandle *)inHandle isIdle:(BOOL)inIdle
{
    if(inIdle){
        if(!idleHandleArray){
            idleHandleArray = [[NSMutableArray alloc] init];
            idleHandleTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateIdleHandlesTimer:) userInfo:nil repeats:YES] retain];
        }
        [idleHandleArray addObject:inHandle];
    }else{
        [idleHandleArray removeObject:inHandle];
        if([idleHandleArray count] == 0){
            [idleHandleTimer invalidate]; [idleHandleTimer release];
            [idleHandleArray release];
        }
    }
}

- (void)updateIdleHandlesTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;

    [[owner contactController] setHoldContactListUpdates:YES]; //Hold updates to prevent multiple updates and re-sorts

    enumerator = [idleHandleArray objectEnumerator];
    while((handle = [enumerator nextObject])){
        NSMutableDictionary	*handleStatusDict = [handle statusDictionary];
        double			idleValue = [[handleStatusDict objectForKey:@"Idle"] doubleValue];

        //Increase the stored idle time
        [handleStatusDict setObject:[NSNumber numberWithDouble:++idleValue] forKey:@"Idle"];

        //Post a status changed message
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Idle"]];
    }

    [[owner contactController] setHoldContactListUpdates:NO]; //Resume updates
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
 /*   NSArray	*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"Idle",@"Signon Date",@"Away",@"Client",nil];
    int		loop;

    for(loop = 0;loop < [keyArray count];loop++){
        [[handle statusArrayForKey:[keyArray objectAtIndex:loop]] removeObjectsWithOwner:self];
    }

    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray];*/
}

@end
