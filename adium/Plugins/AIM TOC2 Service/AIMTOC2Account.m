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

//Includes
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AIMTOC2Account.h"
#import "AIMTOC2Packet.h"
#import "AIMTOC2StringAdditions.h"
#import "AIMTOC2AccountViewController.h"
#import "AIMTOC2ServicePlugin.h"

static char *hash_password(const char * const password);

@interface AIMTOC2Account (PRIVATE)
- (void)update:(NSTimer *)timer;
- (void)signOnUpdate;
- (void)flushMessageDelayQue:(NSTimer *)inTimer;
- (void)removeAllStatusFlagsFromHandle:(AIContactHandle *)handle;
- (void)AIM_AddHandle:(NSString *)handleUID toGroup:(NSString *)groupName;
- (void)AIM_RemoveHandle:(NSString *)handleUID fromGroup:(NSString *)groupName;
- (void)AIM_HandleUpdateBuddy:(NSString *)message;
- (void)AIM_HandleNick:(NSString *)message;
- (void)AIM_HandleSignOn:(NSString *)message;
- (void)AIM_HandleError:(NSString *)message;
- (void)AIM_HandleConfig:(NSString *)message;
- (void)AIM_HandleMessageIn:(NSString *)inCommand;
- (void)AIM_SendMessage:(NSString *)inMessage toHandle:(NSString *)handleUID;
- (void)AIM_SetIdle:(double)inSeconds;
- (NSString *)validCopyOfString:(NSString *)inString;
@end

@implementation AIMTOC2Account

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    AIPreferenceController	*preferenceController = [owner preferenceController];

    //Outgoing message que
    outQue = [[NSMutableArray alloc] init];

    //Delayed handle modification
    deleteDict = [[NSMutableDictionary alloc] init];
    addDict = [[NSMutableDictionary alloc] init];
    messageDelayTimer = nil;

    //Load our preferences
    preferencesDict = [[preferenceController preferencesForGroup:AIM_TOC2_PREFS] retain];
}

// Return a view for the connection window
- (id <AIAccountViewController>)accountView
{
    return([AIMTOC2AccountViewController accountViewForOwner:owner account:self]);
}

// Return a unique ID for this account type and username
- (NSString *)accountID
{
    return([NSString stringWithFormat:@"AIM.%@",[[propertiesDict objectForKey:@"Handle"] compactedString]]);
}

// Return a readable description of this account's username
- (NSString *)accountDescription
{
    NSString	*description = [propertiesDict objectForKey:@"Handle"];
    
    if(description){
        return(description);
    }else{
        return(@"");
    }
}


// AIAccount_GroupedHandles ---------------------------------------------------------------------------
- (BOOL)contactListEditable
{
    if([self status] == STATUS_ONLINE){
        return(YES);
        
    }else{
        return(NO);

    }
}

// Create a group in the specified groups
- (BOOL)addGroup:(AIContactGroup *)newGroup
{
    //AIM automatically creates groups (when we attempt to add to them), so nothing needs to be done here.

    return(YES);
}

// Remove a group from the specified groups
- (BOOL)removeGroup:(AIContactGroup *)group
{
    //AIM automatically removes groups (once they are emptied), so nothing needs to be done here.

    return(YES);
}

// Rename a group
- (BOOL)renameGroup:(AIContactGroup *)group to:(NSString *)inName
{
    int	loop;

    //Remove all the handles from the group
    for(loop = 0;loop < [group count];loop++){
        [self AIM_RemoveHandle:[[group objectAtIndex:loop] UID] fromGroup:[group displayName]];
    }

    //Re-add all the handles into a new group (with the new name)
    for(loop = 0;loop < [group count];loop++){
        [self AIM_AddHandle:[[group objectAtIndex:loop] UID] toGroup:inName];
    }

    return(YES);
}

// Add a handle to the specified groups
- (BOOL)addHandle:(AIContactHandle *)handle toGroup:(AIContactGroup *)group
{
    NSParameterAssert(handle != nil);

    //Place it on the server side list
    [self AIM_AddHandle:[handle UID] toGroup:[group displayName]];
    
    return(YES);
}

// Remove a handle from the specified groups
- (BOOL)removeHandle:(AIContactHandle *)handle fromGroup:(AIContactGroup *)group
{
    NSString	*groupName;

    NSParameterAssert(handle != nil);
    
    [self removeAllStatusFlagsFromHandle:handle];
    
    //Remove the handle
    groupName = [group displayName];
    [self AIM_RemoveHandle:[handle UID] fromGroup:groupName];

    return(YES);
}

// Rename a handle
- (BOOL)renameHandle:(AIContactHandle *)handle inGroup:(AIContactGroup *)group to:(NSString *)inName
{
    NSParameterAssert(handle != nil);
    NSParameterAssert(group != nil);
    NSParameterAssert(inName != nil); NSParameterAssert([inName length] != 0);

    //Remove the handle
    [self AIM_RemoveHandle:[handle UID] fromGroup:[group displayName]];

    //Remove any status flags from this account (The AIM server will automatically send an update buddy message)
    [self removeAllStatusFlagsFromHandle:handle];

    //Re-add the handle (with the new name)
    [self AIM_AddHandle:inName toGroup:[group displayName]];

    return(YES);
}

- (BOOL)moveHandle:(AIContactHandle *)handle fromGroup:(AIContactGroup *)sourceGroup toGroup:(AIContactGroup *)destGroup
{
    NSLog(@"Move '%@' from '%@' to '%@'",[handle UID],[sourceGroup displayName],[destGroup displayName]);
}


// AIAccount_Messaging ---------------------------------------------------------------------------
- (BOOL)sendContentObject:(id <AIContentObject>)object toHandle:(AIContactHandle *)inHandle
{
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSString	*message;

        message = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message]];

        [self AIM_SendMessage:message toHandle:[inHandle UID]];

    }else{
        NSLog(@"Unknown message object subclass");
        #warning accounts should respond to a 'SendingOfContentTypeAvailable:', or something like that... and 'SendContentObjectTo:...' can return an error if it's not available with that contact at the moment.... I'll also need a 'sendingOfContentTypeAvailableWithHandle:' type deal... figure this out later...
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
    //get password
    [[owner accountController] passwordForAccount:self notifyingTarget:self selector:@selector(finishConnect:)];
}

- (void)finishConnect:(NSString *)inPassword
{
    if(inPassword && [inPassword length] != 0){
        NSString	*host = [preferencesDict objectForKey:AIM_TOC2_KEY_HOST];
        int		port = [[preferencesDict objectForKey:AIM_TOC2_KEY_PORT] intValue];
    
        //Connect
        [self setStatus:STATUS_CONNECTING];
    
        //Setup and init
        socket = [[AISocket socketWithHost:host port:port] retain];
        screenName = [[propertiesDict objectForKey:@"Handle"] copy];
        password = [inPassword copy];//[[AIKeychain getPasswordFromKeychainForService:[NSString stringWithFormat:@"Adium.%@",[self accountID]] account:[self accountID]] copy];
    
        //Start connecting
        connectionPhase = 1;
        updateTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / 10.0) //(1.0 / x) x times per second
                                                        target:self
                                                        selector:@selector(update:)
                                                        userInfo:nil
                                                        repeats:YES] retain];
    }
}

//Disconnects or cancels
- (void)disconnect
{
    NSEnumerator	*enumerator;
    AIContactHandle	*handle;

    //Disconnect, or abort connecting/disconnecting
    [self setStatus:STATUS_DISCONNECTING];
    
    //Flush all our handle status flags
    enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES ownedBy:self] objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self removeAllStatusFlagsFromHandle:handle];
    }

    //Clean up and close down
    [screenName release]; screenName = nil;
    [password release]; password = nil;

    [socket release]; socket = nil;
    [self setStatus:STATUS_OFFLINE];

    [updateTimer invalidate];
    [updateTimer release]; updateTimer = nil;

    //We are now offline
    [self setStatus:STATUS_OFFLINE];
}

- (void)setIdleTime:(double)inSeconds manually:(BOOL)setManually
{
    idleWasSetManually = setManually;
    [self AIM_SetIdle:0];
    [self AIM_SetIdle:inSeconds];

    if(inSeconds>0) idle = TRUE;
    else idle = FALSE;
    
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_IdleStatusChanged
                                                                         object:self
                                                                       userInfo:nil];
}

- (BOOL)idleWasSetManually
{
    return(idleWasSetManually);
}

- (BOOL)isIdle
{
    return(idle);
}

// Internal --------------------------------------------------------------------------------
//Dealloc
- (void)dealloc
{
    [outQue release];
    [screenName release];
    [password release];
    [addDict release];
    [deleteDict release];
    [preferencesDict release];
    [accountViewController release];
    [socket release];
    [messageDelayTimer release];

    [super dealloc];
}

//Removes all the possible status flags (that are valid on AIM/TOC) from the passed handle
- (void)removeAllStatusFlagsFromHandle:(AIContactHandle *)handle
{
    NSArray	*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"Idle",@"Signon Date",@"Away",@"Client",nil];
    int		loop;
    
    for(loop = 0;loop < [keyArray count];loop++){
        [[handle statusArrayForKey:[keyArray objectAtIndex:loop]] removeObjectsWithOwner:self];
    }
    
    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray];
}

// Sets the status of this account
- (void)setStatus:(ACCOUNT_STATUS)inStatus
{
    status = inStatus;
    
    //Configure the account view
    if(accountViewController != nil){
        [accountViewController configureViewForStatus:inStatus];
    }

    //Broadcast a status changed message
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_StatusChanged
                                                      object:self
                                                    userInfo:nil];
}

// Sends packets, receives packets, and dispatches commands 
- (void)update:(NSTimer *)timer
{
    AIMTOC2Packet	*packet;

    if(![socket isValid]){
        [self disconnect];
        return;
    }
    
    if(connectionPhase == 0){ //Send & Receive regular AIM commands
        //Receive any incoming packets
        while([socket readyForReceiving] && (packet = [AIMTOC2Packet packetFromSocket:socket sequence:&remoteSequence])){
            NSString		*message = [packet string];
            NSString		*command = [message TOCStringArgumentAtIndex:0];

  //          NSLog(@"<- %@",[packet string]);

            if([command compare:@"SIGN_ON"] == 0){
                [self AIM_HandleSignOn:message];

            }else if([command compare:@"ERROR"] == 0){
                [self AIM_HandleError:message];

            }else if([command compare:@"NICK"] == 0){
                [self AIM_HandleNick:message];

            }else if([command compare:@"CONFIG2"] == 0){
                [self AIM_HandleConfig:message];

                //Send AIM the init done message (at this point we become visible to other buddies)
                [outQue addObject:[AIMTOC2Packet dataPacketWithString:@"toc_init_done" sequence:&localSequence]];

                [self setStatus:STATUS_ONLINE];

            }else if([command compare:@"PAUSE"] == 0){
            }else if([command compare:@"NEW_BUDDY_REPLY2"] == 0){
            }else if([command compare:@"IM_IN2"] == 0){
                [self AIM_HandleMessageIn:message];
            
            }else if([command compare:@"UPDATE_BUDDY2"] == 0){
                [self AIM_HandleUpdateBuddy:message];

            }else if([command compare:@"GOTO_URL"] == 0){
            }else if([command compare:@"EVILED"] == 0){
            }else if([command compare:@"CHAT_JOIN"] == 0){
            }else if([command compare:@"CHAT_LEFT"] == 0){
            }else if([command compare:@"CHAT_IN"] == 0){
            }else if([command compare:@"CHAT_INVITE"] == 0){
            }else if([command compare:@"CHAT_UPDATE_BUDDY"] == 0){
            }else if([command compare:@"ADMIN_NICK_STATUS"] == 0){
            }else if([command compare:@"ADMIN_PASSWD_STATUS"] == 0){
            }else if([command compare:@"RVOUS_PROPOSE"] == 0){
                NSLog(@"RVOUS_PROPOSE");
            }else{
                //NSLog(@"Unknown TOC command %@",command);
            }

        }

    }else{ //Send & Receive the sign on commands
        [self signOnUpdate];
    }

    //Send any packets in the outQue
    while([outQue count] && [socket readyForSending]){
        [[outQue objectAtIndex:0] sendToSocket:socket];
    //    NSLog(@"-> %@",[[outQue objectAtIndex:0] string]);
        [outQue removeObjectAtIndex:0];
    }
}

//Check for sign on packets and update status
- (void)signOnUpdate
{
    AIMTOC2Packet	*packet;

    switch(connectionPhase){
        case 1: //Send the "flap on" packet
            if([socket readyForSending]){
                [socket sendData:[@"FLAPON\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                connectionPhase++;
            }
        break;
        case 2: //Receive the server version
            if([socket readyForReceiving] && (packet = [AIMTOC2Packet packetFromSocket:socket sequence:0])){
                if([packet dataByte:0] != 0 ||
                    [packet dataByte:1] != 0 ||
                    [packet dataByte:2] != 0 ||
                    [packet dataByte:3] != 1){
                    NSLog(@"ADIUM_ERROR:Invalid Server Version");
                    [self disconnect]; return;
                }
    
                //Start the sequence generators
                remoteSequence = [packet sequence] + 1;
                srand(time(NULL));
                localSequence = 1+(short) (65536.0*rand()/(RAND_MAX+1.0));
    
                connectionPhase++;
            }
        break;
        case 3: //Send the sign on packets
            if([socket readyForSending]){
                NSString 	*message;
                unsigned long 	a,b,d,o;
    
                //Send the first sign on packet
                [[AIMTOC2Packet signOnPacketForScreenName:[screenName compactedString] sequence:&localSequence] sendToSocket:socket];
    
                //Add the sign on string, and begin the regular update loop
                a = ([[screenName compactedString] cString][0] - 96) * 7696 + 738816; 	//first SN letter
                b = ([[screenName compactedString] cString][0] - 96) * 746512; 		//first SN letter
                d = ([password cString][0] - 96) * a; 			//pass first letter
                o = d - a + b + 71665152;
    
                message = [NSString stringWithFormat:@"toc2_signon login.oscar.aol.com 5190 %@ %s english TIC:AIMM 160 %lu",[screenName compactedString],hash_password([password cString]),o];
    
                [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
    
                connectionPhase = 0;
            }
        break;
    }
}


// Buddy list modification ---------------------------------------------------------------------------
// AIM only lets us send messages so fast, sending too fast will result in an error and disconnect.
// Unfortunately, this also applies to buddy list management and non-IM related messages.  When
// modifying the buddy list, it's best to send as few messages as possible, and AIM helps out by
// letting the add and remove messages be clumped.
//
// The clumping of messages happens at the lowest level of the AIM code (with the AIM_AddHandle and 
// AIM_RemoveHandle methods).  When one of the methods is called, the code waits 1 second before
// sending the change to AIM.  If another change comes in before the second is up, Adium appends it
// to the existing qued up change, and waits another second.  As soon as there is a 1 second lapse
// in the requests, the messages are sent (and when possible clumped together).
//
// Since this happens at the lowest level, only these two functions (AIM_AddHandle and 
// AIM_RemoveHandle need to worry about the clumping and delays.

- (void)AIM_AddHandle:(NSString *)handleUID toGroup:(NSString *)groupName
{
    NSMutableArray	*contentsArray;

    //If this handle is in the delete dict, it is removed, otherwise the handle is placed in the add dict.
    contentsArray = [deleteDict objectForKey:groupName];
    if(contentsArray && [contentsArray containsObject:handleUID]){
        //unQue the handle from deleting
        [contentsArray removeObject:handleUID];
    }else{
        //Que the handle for adding
        contentsArray = [addDict objectForKey:groupName];
        if(!contentsArray){
            contentsArray = [[[NSMutableArray alloc] init] autorelease];
            [addDict setObject:contentsArray forKey:groupName];            
        }
        
        //Add this handle to the group
        [contentsArray addObject:handleUID];
    }

    //Install (or reset) the 1 second delay
    if(messageDelayTimer){
        [messageDelayTimer invalidate]; [messageDelayTimer release]; messageDelayTimer = nil;
    }
    
    messageDelayTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(flushMessageDelayQue:) userInfo:nil repeats:NO] retain];
}

- (void)AIM_RemoveHandle:(NSString *)handleUID fromGroup:(NSString *)groupName
{
    NSMutableArray	*contentsArray;

    //If this handle is in the add dict, it is removed, otherwise the handle is placed in the delete dict.
    contentsArray = [addDict objectForKey:groupName];
    if(contentsArray && [contentsArray containsObject:handleUID]){
        //unQue the handle from adding
        [contentsArray removeObject:handleUID];
    }else{
        //Que the handle for deleting
        contentsArray = [deleteDict objectForKey:groupName];
        if(!contentsArray){
            contentsArray = [[[NSMutableArray alloc] init] autorelease];
            [deleteDict setObject:contentsArray forKey:groupName];            
        }
        
        //Add this handle to the group
        [contentsArray addObject:handleUID];
    }

    //Install (or reset) the 1 second delay
    if(messageDelayTimer){
        [messageDelayTimer invalidate]; [messageDelayTimer release]; messageDelayTimer = nil;
    }
    
    messageDelayTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(flushMessageDelayQue:) userInfo:nil repeats:NO] retain];
}

- (void)flushMessageDelayQue:(NSTimer *)inTimer
{
    NSArray	*keys;
    int 	loop;
    
    //make this code watch out for, and handle large packets
    //Flush the timer
    if(messageDelayTimer){
        [messageDelayTimer invalidate]; [messageDelayTimer release]; messageDelayTimer = nil;
    }

    //Delete handles to the server side list
    keys = [deleteDict allKeys];
    for(loop = 0;loop < [keys count];loop++){
        NSString	*groupName;
        NSArray		*groupArray;
        NSMutableString	*message;
        int		handle;
        
        //Get the group and group contents
        groupName = [keys objectAtIndex:loop];
        groupArray = [deleteDict objectForKey:groupName];
        
        if([groupArray count] != 0){
            //Create the message string
            message = [NSMutableString stringWithFormat:@"toc2_remove_buddy ",groupName];
            
            //Add the handles
            for(handle = 0;handle < [groupArray count];handle++){
                [message appendString:[NSString stringWithFormat:@"\"%@\" ",[[groupArray objectAtIndex:handle] validAIMStringCopy]]];
            }

            //Add the group name to the end
            [message appendString:[NSString stringWithFormat:@"\"%@\"",[groupName validAIMStringCopy]]];
    
            //Send the message
            [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
        }
    }
    [deleteDict removeAllObjects];
    
    //Add handles to the server side list
    {
        NSMutableString	*message;
        int		totalNames = 0;
        
        //Create the message string
        message = [NSMutableString stringWithString:@"toc2_new_buddies {"];

        keys = [addDict allKeys];
        for(loop = 0;loop < [keys count];loop++){
            NSString	*groupName;
            NSArray		*groupArray;
            int		handle;
            
            //Get the group and group contents
            groupName = [keys objectAtIndex:loop];
            groupArray = [addDict objectForKey:groupName];
            
            //Add the group
                [message appendString:[NSString stringWithFormat:@"g:%@\012",groupName]];
            
            //Add the handles
            for(handle = 0;handle < [groupArray count];handle++){
                [message appendString:[NSString stringWithFormat:@"b:%@\012",[groupArray objectAtIndex:handle]]];
                totalNames++;
            }
        }
    
        //Add the ending '}'
        [message appendString:@"}"];
    
        //Send the message
        if(totalNames != 0){
            [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
        }
    }
    [addDict removeAllObjects];

}


//Server -> Client Command Handlers
- (void)AIM_HandleMessageIn:(NSString *)inCommand
{
    AIContactHandle		*handle;
    NSString			*name;
    NSString			*rawMessage;
    NSAttributedString		*messageText;
    AIContentMessage		*messageObject;

    //Extract the handle and message from the command
    name = [inCommand TOCStringArgumentAtIndex:1];
    rawMessage = [inCommand nonBreakingTOCStringArgumentAtIndex:4];
    
    handle = [[owner contactController] handleWithService:[service handleServiceType] UID:[name compactedString] forAccount:self];
    messageText = [AIHTMLDecoder decodeHTML:rawMessage];

    //Add the message
    messageObject = [AIContentMessage messageWithSource:handle destination:self date:nil message:messageText];
    [[owner contentController] addIncomingContentObject:messageObject toHandle:handle];
}         

- (void)AIM_SendMessage:(NSString *)inMessage toHandle:(NSString *)handleUID
{
    NSString	*command;

    //Create the message string
    command = [NSString stringWithFormat:@"toc2_send_im %@ \"%@\"",handleUID,[self validCopyOfString:inMessage]];
    
    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:command sequence:&localSequence]];
}


- (void)AIM_HandleUpdateBuddy:(NSString *)message
{
//UPDATE_BUDDY2:<screenname>:<online>:<warning>:<signon Time>:<idletime>:<userclass>:<???>
    NSString		*name = [message TOCStringArgumentAtIndex:1];
    NSString		*compactedName = [name compactedString];
    AIContactHandle	*handle = nil;
    NSMutableArray	*alteredStatusKeys;

    //Get the handle
    handle = [[owner contactController] handleWithService:[service handleServiceType] UID:compactedName forAccount:self];

    if(handle){
        NSString	*userFlags = [message TOCStringArgumentAtIndex:6];
        BOOL		online;
        BOOL		away;
        int		warning;
        double		idleTime;
        NSDate		*signOnDate;        
        char		clientA, clientB;
        NSNumber	*storedValue;
        NSDate		*storedDate;
        NSString	*storedString;
        NSString	*client;
        AIMutableOwnerArray	*ownerArray;
                
        alteredStatusKeys = [[[NSMutableArray alloc] init] autorelease];

        //Get the handle's status from the update event
        online = ([[message TOCStringArgumentAtIndex:2] characterAtIndex:0] == 'T');
        warning = [[message TOCStringArgumentAtIndex:3] intValue];
        idleTime = [[message TOCStringArgumentAtIndex:5] doubleValue];
        signOnDate = [NSDate dateWithTimeIntervalSince1970:[[message TOCStringArgumentAtIndex:4] doubleValue]];

        if([userFlags length] < 3){
            away = NO;
        }else{
            away = ([userFlags characterAtIndex:2] == 'U');
        }

        clientA = [userFlags characterAtIndex:0];
        clientB = [userFlags characterAtIndex:1];
        if(clientA == 'A' && clientB == 'O'){
            client = @"America Online (And) AOL Instant Messenger";
        }else if(clientA == 'A' && clientB == 'U'){
            client = @"America Online (And) AOL Instant Messenger (Unconfirmed)";
        }else if(clientA == 'A'){
            client = @"America Online";
        }else if(clientB == 'O'){
            client = @"AOL Instant Messenger";
        }else if(clientB == 'U'){
            client = @"AOL Instant Messenger (Unconfirmed)";
        }else if(clientA == ' ' && clientB == 'C'){
            client = @"AOL Mobile Device";
        }else{
            client = @"Unknown Client";
        }
        
        //There is an extra unknown parameter at the end of the update message.  In my experience, the only possible value is '0'.  I'm sure the value has some purpose though, and if it's ever activated, this code will log.
        if([[message TOCStringArgumentAtIndex:7] compare:@"0"] != 0){
            NSLog(@"****%@ has a mystery value of [%@]****",name,[message TOCStringArgumentAtIndex:7]);
        }

        //Online/Offline
        ownerArray = [handle statusArrayForKey:@"Online"];
        storedValue = [ownerArray objectWithOwner:self];
        if(storedValue == nil || online != [storedValue intValue]){
            [ownerArray removeObjectsWithOwner:self];
            [ownerArray addObject:[NSNumber numberWithInt:online] withOwner:self];
            [alteredStatusKeys addObject:@"Online"];
        }

        //Warning
        ownerArray = [handle statusArrayForKey:@"Warning"];
        storedValue = [ownerArray objectWithOwner:self];
        if(storedValue == nil || warning != [storedValue intValue]){
            [ownerArray removeObjectsWithOwner:self];
            [ownerArray addObject:[NSNumber numberWithInt:warning] withOwner:self];
            [alteredStatusKeys addObject:@"Warning"];
        }

        //Idle time (seconds)
        ownerArray = [handle statusArrayForKey:@"Idle"];
        storedValue = [ownerArray objectWithOwner:self];   
        if(storedValue == nil || idleTime != [storedValue doubleValue]){
            [ownerArray removeObjectsWithOwner:self];
            [ownerArray addObject:[NSNumber numberWithDouble:idleTime] withOwner:self];
            [alteredStatusKeys addObject:@"Idle"];
        }

        //Sign on date
        ownerArray = [handle statusArrayForKey:@"Signon Date"];
        storedDate = [ownerArray objectWithOwner:self];   
        if(storedDate == nil || ![signOnDate isEqualToDate:storedDate]){
            [ownerArray removeObjectsWithOwner:self];
            [ownerArray addObject:signOnDate withOwner:self];
            [alteredStatusKeys addObject:@"Signon Date"];
        }

        //Away
        ownerArray = [handle statusArrayForKey:@"Away"];
        storedValue = [ownerArray objectWithOwner:self];   
        if(storedValue == nil || away != [storedValue intValue]){
            [ownerArray removeObjectsWithOwner:self];
            [ownerArray addObject:[NSNumber numberWithBool:away] withOwner:self];
            [alteredStatusKeys addObject:@"Away"];
        }

        //Client
        ownerArray = [handle statusArrayForKey:@"Client"];
        storedString = [ownerArray objectWithOwner:self];   
        if(storedString == nil || [client compare:storedString] != 0){
            [ownerArray removeObjectsWithOwner:self];
            [ownerArray addObject:client withOwner:self];
            [alteredStatusKeys addObject:@"Client"];
        }
        
        //Display Name
        ownerArray = [handle statusArrayForKey:@"Display Name"];
        storedString = [ownerArray objectWithOwner:self];   
        if(storedString == nil || [name compare:storedString] != 0){
            [ownerArray removeObjectsWithOwner:self];
            [ownerArray addObject:name withOwner:self];
            [alteredStatusKeys addObject:@"Display Name"];
        }

        //Let the contact list know a handle's status changed
        if([alteredStatusKeys count]){
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:alteredStatusKeys];
        }
        
    }else{
        NSLog(@"Unknown handle %@",name);
    }

}

- (void)AIM_HandleNick:(NSString *)message
{
    if([screenName compare:[message TOCStringArgumentAtIndex:1]] != 0){
        NSString *message = [NSString stringWithFormat:@"toc_format_nickname \"%@\"",screenName];
        [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
    }
}

- (void)AIM_HandleSignOn:(NSString *)message
{
    //Check the protocol version
    if([[message TOCStringArgumentAtIndex:1] compare:@"TOC2.0"] != 0){
        NSLog(@"Server is reporting '%@', expected 'TOC2.0'",[message TOCStringArgumentAtIndex:1]);
    }
}

- (void)AIM_HandleError:(NSString *)message
{
    int error = [[message TOCStringArgumentAtIndex:1] intValue];

    switch(error){
        //Minor errors
        case 901: NSLog(@"ERROR: User is currently unavailable"); break;
        case 902: NSLog(@"ERROR: User information is currently unavilable"); break;
        case 903: NSLog(@"ERROR: (1) You are sending messages too fast; last message was dropped"); break;
        case 911: NSLog(@"ERROR: Invalid username (or) Unable to change password"); break;
        case 915: NSLog(@"ERROR: (2) You are sending messages too fast; last message was dropped"); break;
        case 931: NSLog(@"ERROR: Your buddy list is full, can't fit user"); break;
        case 950: NSLog(@"ERROR: Chat room is currently unavailable"); break;
        case 960: NSLog(@"ERROR: (3) You are sending messages too fast; last message was dropped"); break;
        case 961: NSLog(@"ERROR: Incoming message delivery failure (Message too big)"); break;
        case 962: NSLog(@"ERROR: Incoming message delivery failure (Message sent too fast)"); break;
        case 970: NSLog(@"ERROR: User information is currently unavilable (1)"); break;
        case 971: NSLog(@"ERROR: User information is currently unavilable (Too many matches)"); break;
        case 972: NSLog(@"ERROR: User information is currently unavilable (Need more qualifiers)"); break;
        case 973: NSLog(@"ERROR: User information is currently unavilable (Directory service unavailable)"); break;
        case 974: NSLog(@"ERROR: User information is currently unavilable (Email lookup restricted)"); break;
        case 975: NSLog(@"ERROR: User information is currently unavilable (Keyword ignored)"); break;
        case 976: NSLog(@"ERROR: User information is currently unavilable (No keywords)"); break;
        case 977: NSLog(@"ERROR: User information is currently unavilable (Language not supported)"); break;
        case 978: NSLog(@"ERROR: User information is currently unavilable (Country not supported)"); break;
        case 979: NSLog(@"ERROR: User information is currently unavilable (2)"); break;
        
        //Disconnecting Errors
        case 904:
            NSLog(@"ERROR: You've been bumped off because your screenname has signed on from somewhere else");
            [self disconnect];
        break;
        case 980:
            NSLog(@"ERROR: Invalid username or password");
            [self disconnect];

            APPKIT_EXTERN int NSRunAlertPanel(NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, ...);
            
            
            //Prompt error
            //choices to -reenter pass, cancel, try again
            
        break;
        case 981:
            NSLog(@"ERROR: Unknown error (Service temporarily unavailable)");
            [self disconnect];
        break;
        case 982:
            NSLog(@"ERROR: You are blocked (Your warning level is too high to sign on)");
            [self disconnect];
        break;
        case 983:
            NSLog(@"ERROR: You are blocked (You have been connected and disconnecting too frequently)");
            [self disconnect];
        break;
        case 989:
            NSLog(@"ERROR: That account is currently suspended (or) The host has refused this connection");
            [self disconnect];
        break;

        //Unkonwn Error
        default: NSLog(@"ERROR: Unknown error %i",error); break;
    }
}

- (void)AIM_HandleConfig:(NSString *)message
{
    NSScanner		*scanner;
    NSCharacterSet	*endlines = [NSCharacterSet characterSetWithCharactersInString:@"\r\n:"];
    NSString		*configString = [message nonBreakingTOCStringArgumentAtIndex:1];
    NSString		*type;
    NSString		*value;
    AIContactGroup	*currentGroup = nil;

    [[owner contactController] delayContactListUpdatesFor:10]; //Delay updates until we're finished signing on
    //10 seconds should be long enough for even the slowest net connections.

    //Create a scanner
    scanner = [NSScanner scannerWithString:configString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    
    while(![scanner isAtEnd]){
        //Scan the type (the text before the : )
        [scanner scanUpToString:@":" intoString:&type];
        if([scanner scanString:@":" intoString:nil]){
            //scan the value (the text after the : )
            [scanner scanUpToCharactersFromSet:endlines intoString:&value];
            if([scanner scanCharactersFromSet:endlines intoString:nil]){

                //Parse the information
                if([type compare:@"m"] == 0){
                    NSLog(@"Privacy Mode:%@",value);
                    
                }else if([type compare:@"g"] == 0){ //GROUP
                    //Create the group
                    if(!(currentGroup = [[owner contactController] groupWithName:value])){
                        currentGroup = [[owner contactController] createGroupNamed:value inGroup:nil];
                    }
                    
                    //Register as an owner of the group
                    [currentGroup registerOwner:self];

                }else if([type compare:@"b"] == 0){ //BUDDY
                    //Create the handle
                    [[owner contactController] createHandleWithService:[service handleServiceType]
                                                                   UID:[value compactedString]
                                                               inGroup:currentGroup
                                                            forAccount:self];
                }else if([type compare:@"p"] == 0){
                }else if([type compare:@"m"] == 0){
                }else if([type compare:@"done"] == 0){
                }else{
                    NSLog(@"Unknown Config Type '%@', value '%@'",type,value);
                }
            }
        }
    }

}

- (void)AIM_SetIdle:(double)inSeconds
{
    NSString	*idleMessage;

    idleMessage = [NSString stringWithFormat:@"toc_set_idle %0.0f",(double)inSeconds];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:idleMessage sequence:&localSequence]];
}


// Hashes a password for sending to AIM (to avoid sending them in plain-text)
#define HASH "Tic/Toc"
static char *hash_password(const char * const password) {
    const char hash[sizeof(HASH)] = HASH;
    static char output[2048];
    int counter;
    int newcounter;
    int length;

    length = strlen(password);

    output[0] = '0';
    output[1] = 'x';

    newcounter = 2;

    for (counter = 0; counter < length; counter++) {
        if (newcounter > 2044)
            return NULL;
        sprintf(&output[newcounter],"%02x",password[counter] ^ hash[((counter) % (sizeof(HASH)-1))]);
        newcounter += 2;
    }

    output[newcounter] = '\0';

    return output;
}

//Backslashes invalid characters as required by AIM
- (NSString *)validCopyOfString:(NSString *)inString
{
    NSMutableString		*message;
    short			loop = 0;

    message = [[inString mutableCopy] autorelease];

    //---backslash certain characters---
    while(loop < [message length]){
        char currentChar = [message characterAtIndex:loop];

        if( currentChar == '$' ||
            currentChar == '{' || currentChar == '}' ||
            currentChar == '[' || currentChar == ']' ||
            currentChar == '(' || currentChar == ')' ||
            currentChar == '\"' || currentChar == '\'' || currentChar == '`' ||
            currentChar == '\\'){
            
            [message insertString:@"\\" atIndex:loop];
            loop += 2;
        
        }else if(currentChar == '\r' || currentChar == '\n'){
            [message replaceCharactersInRange:NSMakeRange(loop,1) withString:@"<BR>"];
            loop += 3;
            
        }else{
            loop += 1;
        }
    }

    return(message);
}

@end
