/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define SIGN_ON_MAX_WAIT	5.0		//Max amount of time to wait for first sign on packet
#define SIGN_ON_UPKEEP_INTERVAL	1.6		//Max wait before sign up updates

//
extern void* objc_getClass(const char *name);
//

@interface AIMiChatAccount (PRIVATE)
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle;
- (NSArray *)applyProperties:(NSDictionary *)inProperties toHandle:(AIHandle *)inHandle;
- (void)firstSignOnUpdateReceived;
- (void)waitForLastSignOnUpdate:(NSTimer *)inTimer;
- (void)_sendTyping:(BOOL)typing to:(AIListContact *)object;
@end

@implementation AIMiChatAccount

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    NSArray	*services;

    //init
    handleDict = [[NSMutableDictionary alloc] init];
    typingDict = [[NSMutableDictionary alloc] init];
    
    //Connect to the iChatAgent
    connection = [NSConnection connectionWithRegisteredName:@"iChat" host:nil];
    FZDaemon = [[connection rootProxy] retain];
    
    //Get the AIM Service
    services   = [FZDaemon allServices];
    AIMService = [[[FZDaemon allServices] objectAtIndex:0] retain];

    //Register as a listener
    [FZDaemon addListener:self capabilities:15];
    [AIMService addListener:self signature:@"com.apple.iChat" capabilities:15];

    //Clear the online state flag - this account should always load as offline (online state is not restored)
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
}

- (NSView *)accountView{
    return(nil); // Return a view for the connection window
}
- (NSString *)accountID{
    return([NSString stringWithFormat:@"iChat.%@",[[AIMService loginID] compactedString]]); // The user's account name
}
- (NSString *)UID{
    return([[AIMService loginID] compactedString]); //The user's account name
}
- (NSString *)serviceID{
    return(@"AIM"); //The service ID (shared by any account code accessing this service)
}
- (NSString *)UIDAndServiceID{
    return([NSString stringWithFormat:@"%@.%@",[self serviceID],[self UID]]); //ServiceID.UID
}
- (NSString *)accountDescription{
    return([AIMService loginID]); //Readable description of this account's username
}



// AIAccount_Contacts --------------------------------------------------------------------------------
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
    AIHandle	*handle;

    if(inTemporary) inGroup = @"__Strangers";
    if(!inGroup) inGroup = @"Unknown";

    //Check to see if the handle already exists
    if([handleDict objectForKey:inUID]){
        [self removeHandleWithUID:inUID]; //If it goes, remove it
    }

    //Create the handle
    handle = [AIHandle handleWithServiceID:[[[self service] handleServiceType] description] UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:self];

    //Add the handle
    [handleDict setObject:handle forKey:[handle UID]]; //Add it locally
    //Add it server-side
    [AIMService addBuddies:[NSArray arrayWithObject:[handle UID]] toGroups:[NSArray arrayWithObject:@"iChat"]];

    //Update the contact list
    [[owner contactController] handle:handle addedToAccount:self];

    return(handle);
}

- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    AIHandle	*handle = [handleDict objectForKey:inUID];
    
    //Remove the handle
    [AIMService removeBuddies:[NSArray arrayWithObject:[handle UID]] fromGroups:[NSArray arrayWithObject:@""]]; //Remove it server-side
    [handleDict removeObjectForKey:[handle UID]]; //Remove it locally

    //Update the contact list
    [[owner contactController] handle:handle removedFromAccount:self];

    return(YES);
}

- (BOOL)addServerGroup:(NSString *)inGroup
{
    return(YES);
}

- (BOOL)removeServerGroup:(NSString *)inGroup
{
    return(YES);
}

- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
{
    return(YES);
}


// AIAccount_Messaging --------------------------------------------------------------------------------
- (BOOL)sendContentObject:(id <AIContentObject>)object
{
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSString	*message;
        AIHandle	*handle;
        id		chat;
        id		messageObject;

        //Get the message & destination handle
        message = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message] encodeFullString:YES];
        handle = [[object destination] handleForAccount:self];
 
        //Create a chat & send the message
        chat = [[handle statusDictionary] objectForKey:@"iChat_Chat"];
        if(chat == nil || chat != chat){
            chat = [AIMService createChatForIMsWith:[handle UID] isDirect:NO];
            [[handle statusDictionary] setObject:chat forKey:@"iChat_Chat"];
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"iChat_Chat"]];
        }
        
        //(I guess I could cache these chats)
        messageObject = [[[FZMessage alloc] initWithSender:[self accountDescription] time:[NSDate date] format:2 body:message attributes:0 incomingFile:0 outgoingFile:0 inlineFiles:0 flags:5] autorelease];
        [AIMService sendMessage:messageObject toChat:chat];

    }else if([[object type] compare:CONTENT_TYPING_TYPE] == 0){
        id		messageObject;
        AIHandle	*handle;
        id		chat;
        BOOL		typing;

        //Get the dest handle & cached chat
        handle = [[object destination] handleForAccount:self];
        chat = [[handle statusDictionary] objectForKey:@"iChat_Chat"];
        typing = [(AIContentTyping *)object typing];
        
        //Send the 'typing' message
        if(chat){
            messageObject = [[[FZMessage alloc] initWithSender:[self accountDescription]
                                                          time:[NSDate date]
                                                        format:2
                                                          body:@""
                                                    attributes:0
                                                  incomingFile:0
                                                  outgoingFile:0
                                                   inlineFiles:0
                                                         flags:(typing ? 12 : 13)] autorelease];

            [AIMService sendMessage:messageObject toChat:chat];
        }

    }
    
    return(YES);
}

// Return YES if we're available for sending the specified content
- (BOOL)availableForSendingContentType:(NSString *)inType toHandle:(AIHandle *)inHandle
{
    BOOL available = NO;

    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        //If we're online, ("and the contact is online", nil, or not on our list), return YES
        if([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_ONLINE && //If we're online
           (![[handleDict allValues] containsObject:inHandle] || [[[inHandle statusDictionary] objectForKey:@"Online"] intValue])){
            available = YES;
        }
    }

    return(available);
}


// AIAccount_Status --------------------------------------------------------------------------------
- (NSArray *)supportedStatusKeys
{
    return([NSArray arrayWithObjects:@"Online", @"AwayMessage", @"IdleSince", nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    ACCOUNT_STATUS 	status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];

    if([key compare:@"Online"] == 0){
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
        
    //Ignore the following keys unless we're online
    if(status == STATUS_ONLINE){
        NSMutableDictionary	*myStatusDict = [[[NSMutableDictionary alloc] init] autorelease];
        BOOL 			away, idle;

        //Idle
        if([key compare:@"IdleSince"] == 0){
            //There must be a better way to set idle time.  iChat inserts some kind of NSDate (2139-05-29 00:52:50 -0500) with the key "FZPersonAwaySince", but if I insert the same date it has no effect (other than making the iChat app think it's idle).  I found this private function in AIMService, but obviously it's internal to AIMService, and most likely called in response to whatever triggers an idle value.  I'm missing something somewhere, but this'll do for now.
            if(inValue){
                [AIMService _setIdleTime:(unsigned int)(-[inValue timeIntervalSinceNow])];
            }else{
                [AIMService _setIdleTime:(unsigned int)0];
            }
            
            idle = (inValue != nil);
        }else{
            idle = ([self statusObjectForKey:@"IdleSince"] != nil);
        }

        //Away
        if([key compare:@"AwayMessage"] == 0){
            NSString	*awayMessage = [[NSAttributedString stringWithData:inValue] string];

            [myStatusDict setObject:(awayMessage != nil ? awayMessage : @"") forKey:@"FZPersonStatusMessage"];
            away = (inValue != nil);
        }else{
            away = ([NSAttributedString stringWithData:[self statusObjectForKey:@"AwayMessage"]] != nil);
        }

        //State (Online/offline/idle/away)
        if([key compare:@"IdleSince"] == 0 || [key compare:@"AwayMessage"] == 0){ 
            if(idle && away || idle){ //iChat treats these as the same :(
                [myStatusDict setObject:[NSNumber numberWithInt:2] forKey:@"FZPersonStatus"];
            }else if(away){
                [myStatusDict setObject:[NSNumber numberWithInt:3] forKey:@"FZPersonStatus"];
            }else{
                [myStatusDict setObject:[NSNumber numberWithInt:4] forKey:@"FZPersonStatus"];
            }
        }

        //Set the status
        if([myStatusDict count]){
            [FZDaemon changeMyStatus:myStatusDict];
        }
    }
}



// Private --------------------------------------------------------------------------------------------
//Received when our login status changes
- (oneway void)service:(id)inService loginStatusChanged:(int)inStatus message:(id)inMessage reason:(int)inReason
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;

//    NSLog(@"(iChat)loginStatusChanged %i message:%@ reason:%i",inStatus,inMessage,inReason);
    
    switch(inStatus){
        case 0: //Offline
            //Flush all our handle status flags
            [[owner contactController] setHoldContactListUpdates:YES];
            enumerator = [[handleDict allValues] objectEnumerator];
            while((handle = [enumerator nextObject])){
                [self removeAllStatusFlagsFromHandle:handle];
            }
            [[owner contactController] setHoldContactListUpdates:NO];

            //Remove all our handles
            [handleDict release]; handleDict = [[NSMutableDictionary alloc] init];
            [[owner contactController] handlesChangedForAccount:self];
            
            //Clean up and close down
            [screenName release]; screenName = nil;
            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
        break;

        case 1: //Error
            [[owner interfaceController] handleErrorMessage:[NSString stringWithFormat:@"iChat Error (%@)", screenName] withDescription:inMessage];
        break;

        case 2: //Disconnecting
            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_DISCONNECTING] forKey:@"Status" account:self];
        break;
            
        case 3: //Connecting
            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];

            //Hold onto the account name
            [screenName release];
            screenName = [[[AIMService loginID] compactedString] copy];

        break;

        case 4: //Online
            [[owner contactController] setHoldContactListUpdates:YES];

            [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self];
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:self];

            //Adium waits for the first sign on update, and then checks for aditional updates every X seconds.  When the stream of updates stops, the account can be assumed online, and contact list updates resumed.
            //If no updates are receiced for X seconds, we assume 'no available contacts' and resume contact list updates.
            numberOfSignOnUpdates = 0;
            processingSignOnUpdates = YES;
            waitingForFirstUpdate = 2;
            [NSTimer scheduledTimerWithTimeInterval:(SIGN_ON_MAX_WAIT) //5 Seconds max
                                             target:self
                                           selector:@selector(firstSignOnUpdateReceived)
                                           userInfo:nil
                                            repeats:NO];

        break;

        default:
            NSLog(@"Unknown login status: (%i, %@, %i)",inStatus,inMessage,inReason);
        break;
    }
}

- (void)firstSignOnUpdateReceived
{
//    NSLog(@"firstSignOnUpdateReceived");
    if(waitingForFirstUpdate){
        waitingForFirstUpdate = 0;
    
        if(numberOfSignOnUpdates == 0){
            //No available contacts after 5 seconds, assume noone is online and resume contact list updates
            [self waitForLastSignOnUpdate:nil];
        }else{
            //Check every X seconds for additional updates
            [NSTimer scheduledTimerWithTimeInterval:(SIGN_ON_UPKEEP_INTERVAL)
                                            target:self
                                        selector:@selector(waitForLastSignOnUpdate:)
                                        userInfo:nil
                                            repeats:YES];
        }
    }
}

- (void)waitForLastSignOnUpdate:(NSTimer *)inTimer
{
    if(numberOfSignOnUpdates == 0){
//        NSLog(@"waitForLastSignOnUpdate Done");
        processingSignOnUpdates = NO;
        //No updates received, sign on is complete
        [inTimer invalidate]; //Stop this timer
        [[owner contactController] handlesChangedForAccount:self]; //Let Adium know of our new handles
        [[owner contactController] setHoldContactListUpdates:NO]; //Resume contact list updates
        
    }else{
//        NSLog(@"waitForLastSignOnUpdate %i",numberOfSignOnUpdates);
        numberOfSignOnUpdates = 0;
    }
}

//A message was received
- (oneway void)service:(id)inService chat:(id)chat messageReceived:(id)inMessage
{
    int			flags = [inMessage flags];
    NSString		*compactedName = [[inMessage sender] compactedString];

//    NSLog(@"(iChat)messageReceived:(%i)%@:%@ [%i,%@]", [inMessage bodyFormat], [inMessage sender], [inMessage body], [inMessage flags], [inMessage time]);

    //Ignore echoed messages (anything outgoing)
    if(!(flags & kMessageOutgoingFlag)){
        AIHandle		*handle;
        NSAttributedString	*messageText;
        AIContentMessage	*messageObject;
        id			cachedChat;
        
        //Get the handle sending this message
        handle = [handleDict objectForKey:compactedName];
        if(!handle){ //Stranger
            handle = [self addHandleWithUID:compactedName serverGroup:nil temporary:YES];
        }
        
        //Ensure the handle's cached 'chat' is correct
        cachedChat = [[handle statusDictionary] objectForKey:@"iChat_Chat"];
        if(cachedChat == nil || cachedChat != chat){
            [[handle statusDictionary] setObject:chat forKey:@"iChat_Chat"];
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"iChat_Chat"]];
        }

        //If the buddy is typing
        if((flags & kMessageTypingFlag) && !(flags & kMessageStoppedTypingFlag)){
            NSNumber	*isTyping = [[handle statusDictionary] objectForKey:@"Typing"];
            if(!isTyping || [isTyping boolValue] == NO){
                [[handle statusDictionary] setObject:[NSNumber numberWithInt:YES] forKey:@"Typing"];
                [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]];
            }
        }

        //If the buddy is not typing
        if(flags & kMessageStoppedTypingFlag){
            NSNumber	*isTyping = [[handle statusDictionary] objectForKey:@"Typing"];
            if(isTyping && [isTyping boolValue] == YES){
                [[handle statusDictionary] setObject:[NSNumber numberWithInt:NO] forKey:@"Typing"];
                [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]];
            }
        }

        //If this is not just a "typing" message, Process the received message string
        if(!(flags & kMessageTypingFlag)){
            messageText = [AIHTMLDecoder decodeHTML:[inMessage body]];
            messageObject = [AIContentMessage messageWithSource:[handle containingContact] destination:self date:nil message:messageText];
            [[owner contentController] addIncomingContentObject:messageObject];
        }
    }


    
}

- (oneway void)service:(id)inService buddyPropertiesChanged:(NSArray *)inProperties
{
    NSEnumerator	*buddyEnumerator;
    NSDictionary	*buddyPropertiesDict;

    //Sign on update monitoring
    if(processingSignOnUpdates) numberOfSignOnUpdates++;
    if(waitingForFirstUpdate == 1) [self firstSignOnUpdateReceived];
    if(waitingForFirstUpdate) waitingForFirstUpdate--;

    buddyEnumerator = [inProperties objectEnumerator];
    while((buddyPropertiesDict = [buddyEnumerator nextObject])){
        NSString	*compactedName = [buddyPropertiesDict objectForKey:@"FZPersonID"];
        AIHandle	*handle;
        NSArray		*modifiedStatusKeys;

        if([compactedName compare:screenName] != 0){ //Ignore our own name
            //Get the handle
            handle = [handleDict objectForKey:compactedName];
            if(!handle){ //If the handle doesn't exist
                //Create and add the handle
                handle = [AIHandle handleWithServiceID:[[service handleServiceType] identifier]
                                                    UID:compactedName
                                            serverGroup:@"iChat"
                                                temporary:![[buddyPropertiesDict objectForKey:@"FZPersonIsBuddy"] boolValue]
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
}

- (NSArray *)applyProperties:(NSDictionary *)inProperties toHandle:(AIHandle *)inHandle
{
    NSNumber		*storedValue;
    NSString		*storedString;
    NSDate		*storedDate;
    NSMutableArray	*alteredStatusKeys = [[[NSMutableArray alloc] init] autorelease];
    NSMutableDictionary	*handleStatusDict = [inHandle statusDictionary];

    //Away message
    if((storedString = [inProperties objectForKey:@"FZPersonStatusMessage"])){
        NSAttributedString	*statusMessage;

        statusMessage = [handleStatusDict objectForKey:@"StatusMessage"];
        if(!statusMessage || [[statusMessage string] compare:storedString] != 0){
            [handleStatusDict setObject:[[[NSAttributedString alloc] initWithString:storedString] autorelease] forKey:@"StatusMessage"];
            [alteredStatusKeys addObject:@"StatusMessage"];
        }
    }

    //Status (Online, Away, and Idle)
    if((storedValue = [inProperties objectForKey:@"FZPersonStatus"])){
        BOOL			touchAway = YES;
        BOOL			online;
        BOOL			away;
        NSDate			*idleSince;

        switch([storedValue intValue]){
            case 1: //Offline, signed OFF
                online = NO;
                away = NO;
                idleSince = nil;
            break;
            case 2: //Idle (or Idle & Away)
                online = YES;
                idleSince = [inProperties objectForKey:@"FZPersonAwaySince"];
                away = NO;
                touchAway = NO; //iChat doesn't differentiate between idle and idle+away :(  So we leave away alone.
            break;
            case 3: //Away
                online = YES;
                away = YES;
                idleSince = nil;
            break;
            case 4: //Online, signed ON (no ailments)
                online = YES;
                away = NO;
                idleSince = nil;
            break;
            default:
                NSLog(@"%@: unknown status %i",[inHandle UID], [storedValue intValue]);
            break;
        }

        //If the handle was AWAY or IDLE, and is no longer, remove its status message
        if(([handleStatusDict objectForKey:@"IdleSince"] || [[handleStatusDict objectForKey:@"Away"] intValue]) && (!idleSince && !away)){
            [handleStatusDict removeObjectForKey:@"StatusMessage"];
            [alteredStatusKeys addObject:@"StatusMessage"];
        }
        
        //Online/Offline
        storedValue = [handleStatusDict objectForKey:@"Online"];
        if(storedValue == nil || online != [storedValue intValue]){
            [handleStatusDict setObject:[NSNumber numberWithInt:online] forKey:@"Online"];
            [alteredStatusKeys addObject:@"Online"];
        }

        //Idle time (seconds)
        storedDate = [handleStatusDict objectForKey:@"IdleSince"];
        if(storedDate == nil || ![storedDate isEqualToDate:idleSince]){
            if(!idleSince && storedDate){
                [handleStatusDict removeObjectForKey:@"IdleSince"];
                [alteredStatusKeys addObject:@"IdleSince"];
            }else if(idleSince){
                [handleStatusDict setObject:idleSince forKey:@"IdleSince"];
                [alteredStatusKeys addObject:@"IdleSince"];
            }
        }

        //Away
        if(touchAway){
            storedValue = [handleStatusDict objectForKey:@"Away"];
            if(storedValue == nil || away != [storedValue intValue]){
                [handleStatusDict setObject:[NSNumber numberWithBool:away] forKey:@"Away"];
                [alteredStatusKeys addObject:@"Away"];
            }
        }
    }

    return(alteredStatusKeys);
}



- (oneway void)service:(id)inService requestOutgoingFileXfer:(id)file{
//    NSLog(@"(iChat)requestOutgoingFileXfer (%@)",file);
}
- (oneway void)service:(id)inService requestIncomingFileXfer:(id)file{
//    NSLog(@"(iChat)requestIncomingFileXfer (%@)",file);
}
- (oneway void)service:(id)inService chat:(id)chat member:(id)member statusChanged:(int)inStatus{
//    NSLog(@"(iChat)chat:member:statusChanged (%@, %@, %i)",chat,member,inStatus);
}
- (oneway void)service:(id)inService chat:(id)chat showError:(id)error{
//    NSLog(@"(iChat)chat:showError (%@, %@)",chat,error);
    [[owner interfaceController] handleErrorMessage:[NSString stringWithFormat:@"iChat Error (%@)", screenName] withDescription:error];
}
- (oneway void)service:(id)inService chat:(id)chat statusChanged:(int)inStatus{
//    NSLog(@"(iChat)chat:statusChanged (%@, %i)",chat,inStatus);
}
- (oneway void)service:(id)inService directIMRequestFrom:(id)from invitation:(id)invitation{
//    NSLog(@"(iChat)directIMRequestFrom (%@, %@)",from,invitation);
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
//    NSLog(@"(iChat)Adium is designated notifier (%i)",(int)notifier);
}

- (oneway void)service:(id)inService buddyPictureChanged:(id)buddy imageData:(id)data{
    NSString	*compactedName = [buddy compactedString];
    AIHandle	*handle;

//    NSLog(@"(iChat)buddyPictureChanged (%@)",buddy);

    //Sign on update monitoring
    if(processingSignOnUpdates) numberOfSignOnUpdates++;

    //Get the handle
    handle = [handleDict objectForKey:compactedName];
    if(handle){
        NSImage	*image = [[[NSImage alloc] initWithData:data] autorelease];

        if(image){
            [[handle statusDictionary] setObject:image forKey:@"BuddyImage"];
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"BuddyImage"]];
        }
    }
}

- (oneway void)openNotesChanged:(id)unknown{
//    NSLog(@"(iChat)openNotesChanged (%@)",unknown);
}
- (oneway void)myStatusChanged:(id)unknown{
//    NSLog(@"(iChat)myStatusChanged (%@)",unknown);
}

//Removes all the possible status flags (that are valid on AIM/iChat) from the passed handle
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle
{
    NSArray	*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"IdleSince",@"Signon Date",@"Away",@"Client",@"TextProfile",@"StatusMessage",@"BuddyImage",nil];

    [[handle statusDictionary] removeObjectsForKeys:keyArray];
    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray];
}

@end
