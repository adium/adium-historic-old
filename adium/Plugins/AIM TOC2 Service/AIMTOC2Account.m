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

#define	AIM_ERRORS_FILE		@"AIMErrors"	//Filename of the AIM Errors plist
#define MESSAGE_QUE_DELAY	2.0		//Delay before sending contact list changes to the server

#define AUTO_RECONNECT_DELAY_PING_FAILURE	2.0	//Delay in seconds
#define AUTO_RECONNECT_DELAY_SOCKET_DROP	2.0	//Delay in seconds
#define AUTO_RECONNECT_DELAY_CONNECT_ERROR	5.0	//Delay in seconds

static char *hash_password(const char * const password);

@interface AIMTOC2Account (PRIVATE)
- (void)update:(NSTimer *)timer;
- (void)signOnUpdate;
- (void)flushMessageDelayQue:(NSTimer *)inTimer;
- (void)removeAllStatusFlagsFromHandle:(AIContactHandle *)handle;
- (void)AIM_AddHandle:(NSString *)handleUID toGroup:(NSString *)groupName;
- (void)AIM_RemoveHandle:(NSString *)handleUID fromGroup:(NSString *)groupName;
- (void)AIM_RemoveGroup:(NSString *)groupName;
- (void)AIM_HandleUpdateBuddy:(NSString *)message;
- (void)AIM_HandleNick:(NSString *)message;
- (void)AIM_HandleSignOn:(NSString *)message;
- (void)AIM_HandleError:(NSString *)message;
- (void)AIM_HandleConfig:(NSString *)message;
- (void)AIM_HandleMessageIn:(NSString *)inCommand;
- (void)AIM_HandleGotoURL:(NSString *)message;
- (void)AIM_HandlePing;
- (void)AIM_SendMessage:(NSString *)inMessage toHandle:(NSString *)handleUID;
- (void)AIM_SetIdle:(double)inSeconds;
- (void)AIM_SetProfile:(NSString *)profile;
- (void)AIM_SetAway:(NSString *)away;
- (void)AIM_SetStatus;
- (void)AIM_GetProfile:(NSString *)handleUID;
- (NSString *)extractStringFrom:(NSString *)searchString between:(NSString *)stringA and:(NSString *)stringB;
- (NSString *)validCopyOfString:(NSString *)inString;
- (void)connect;
- (void)disconnect;
- (void)updateContactStatus:(NSNotification *)notification;
- (void)pingFailure:(NSTimer *)inTimer;
- (void)autoReconnectAfterDelay:(int)delay;
- (void)autoReconnectTimer:(NSTimer *)inTimer;
@end

@implementation AIMTOC2Account

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    AIPreferenceController	*preferenceController = [owner preferenceController];

    //Outgoing message que
    outQue = [[NSMutableArray alloc] init];

    pingTimer = nil;
    screenName = nil;
    password = nil;
    
    //Delayed handle modification
    deleteDict = [[NSMutableDictionary alloc] init];
    addDict = [[NSMutableDictionary alloc] init];
    messageDelayTimer = nil;
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];

    //
    [[owner notificationCenter] addObserver:self selector:@selector(updateContactStatus:) name:Contact_UpdateStatus object:nil];
    
    //Load our preferences
    preferencesDict = [[preferenceController preferencesForGroup:AIM_TOC2_PREFS] retain];

    //We have a choice here between:
    //Option 1: Automatically remembering the online state, and restoring it on launch
    //Auto-Connect (via state-restore)
    //if([[[owner accountController] statusObjectForKey:@"Online" account:self] boolValue]){
    //    [self connect];
    //}
    //Option 2:Clearing the online state, and using the classic 'auto-Connect' option system
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
    //Option 1 is very neat, but is more annoying than helpful - so we'll stick with 2 for now :)
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

// AIAccount_GroupedContacts ---------------------------------------------------------------------------
- (BOOL)contactListEditable
{
    return([[[owner accountController] statusObjectForKey:@"Online" account:self] boolValue]);
}

// Add an object to the specified groups
- (BOOL)addObject:(AIContactObject *)object toGroup:(AIContactGroup *)group
{
    NSParameterAssert(object != nil);
    NSParameterAssert(group != nil);
    
    if([object isMemberOfClass:[AIContactGroup class]]){
        //AIM automatically creates groups (when we attempt to add to them), so nothing needs to be done here.

    }else if([object isMemberOfClass:[AIContactHandle class]]){
        //AIM automatically creates the needed containing groups, so they do not need to be added here.
        [self AIM_AddHandle:[object UID] toGroup:[group UID]];	//Place it on the server side list
        
    }else{
        //Unrecognized object
    }

    return(YES);
}

// Remove an object from the specified groups
- (BOOL)removeObject:(AIContactObject *)object fromGroup:(AIContactGroup *)group
{
    NSParameterAssert(object != nil);
    NSParameterAssert(group != nil);

    if([object isMemberOfClass:[AIContactGroup class]]){
        [self AIM_RemoveGroup:[object UID]];

    }else if([object isMemberOfClass:[AIContactHandle class]]){
        //AIM automatically removes unneeded containing groups, so they do not need to be removed here.
        [self removeAllStatusFlagsFromHandle:(AIContactHandle *)object];
        [self AIM_RemoveHandle:[object UID] fromGroup:[group UID]]; //Remove the handle
        
    }else{
        //Unrecognized object
    }

    return(YES);
}


// Rename an object
- (BOOL)renameObject:(AIContactObject *)object inGroup:(AIContactGroup *)group to:(NSString *)inName
{
    NSParameterAssert(object != nil);
    NSParameterAssert(group != nil);
    NSParameterAssert(inName != nil); NSParameterAssert([inName length] != 0);

    if([object isMemberOfClass:[AIContactGroup class]]){
        NSEnumerator	*enumerator;
        AIContactObject	*target;

        enumerator = [group objectEnumerator]; //Remove all the handles from the group
        while((target = [enumerator nextObject])){
            if([target isKindOfClass:[AIContactHandle class]]){
                [self AIM_RemoveHandle:[target UID] fromGroup:[object UID]];
            }
        }

        enumerator = [group objectEnumerator]; //Re-add all the handles into a new group (with the new name)
        while((target = [enumerator nextObject])){
            if([target isKindOfClass:[AIContactHandle class]]){
                [self AIM_AddHandle:[(AIContactHandle *)target UID] toGroup:inName];
            }
        }

    }else if([object isMemberOfClass:[AIContactHandle class]]){
        [self AIM_RemoveHandle:[object UID] fromGroup:[group UID]]; 	//Remove the handle
        [self removeAllStatusFlagsFromHandle:(AIContactHandle *)object]; 				//Remove any status flags from this account (The AIM server will automatically send an update buddy message)
        [self AIM_AddHandle:inName toGroup:[group UID]]; 		//Re-add the handle (with the new name)
        
    }else{
        //Unrecognized object
    }

    return(YES);
}

// Move an object
- (BOOL)moveObject:(AIContactObject *)object fromGroup:(AIContactGroup *)sourceGroup toGroup:(AIContactGroup *)destGroup
{
    NSParameterAssert(object != nil);
    NSParameterAssert(sourceGroup != nil);
    NSParameterAssert(destGroup != nil);

    if([object isMemberOfClass:[AIContactGroup class]]){
        //The placement of groups is ignored
        
    }else if([object isMemberOfClass:[AIContactHandle class]]){
        //AIM doesn't support moving, so we simply remove and re-add the handle.
        [self AIM_RemoveHandle:[object UID] fromGroup:[sourceGroup UID]];
        [self AIM_AddHandle:[object UID] toGroup:[destGroup UID]];
        
    }else{
        //Unrecognized object
    }

    return(YES);    
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
    }
    
    return(YES);
}

- (BOOL)availableForSendingContentType:(NSString *)inType toHandle:(AIContactHandle *)inHandle
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
    return([NSArray arrayWithObjects:@"Online", @"IdleTime", @"IdleManuallySet", @"TextProfile", @"AwayMessage", nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    if([key compare:@"Online"] == 0){
        ACCOUNT_STATUS		status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];

        if([inValue boolValue]){ //Connect
            if(status == STATUS_OFFLINE){
                [self connect];
            }            
        }else{ //Disconnect
            if(status == STATUS_ONLINE){
                [self disconnect];
            }
        }

    }else if([key compare:@"IdleTime"] == 0){
        double		oldIdle = [[[owner accountController] statusObjectForKey:@"IdleTime" account:self] doubleValue];
        double		newIdle = [inValue doubleValue];

        if(oldIdle != 0 && newIdle != 0){
            [self AIM_SetIdle:0]; //Most AIM cliens will ignore 2 consecutive idles, so we unidle, then re-idle to the new value
        }

        [self AIM_SetIdle:newIdle];

    }else if([key compare:@"TextProfile"] == 0){
        [self AIM_SetProfile:[AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:inValue]]];

    }else if([key compare:@"AwayMessage"] == 0){
        if(inValue){
            [self AIM_SetAway:[AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:inValue]]];
        }else{
            [self AIM_SetAway:nil];
        }
    }

}



- (void)updateContactStatus:(NSNotification *)notification
{
    NSArray		*desiredKeys = [[notification userInfo] objectForKey:@"Keys"];
    AIContactHandle	*handle = [notification object];
    
    //AIM requires a delayed load of profiles...
    if([desiredKeys containsObject:@"TextProfile"]){
        [self AIM_GetProfile:[handle UID]];
    }
    
}

// Internal --------------------------------------------------------------------------------
//Dealloc
- (void)dealloc
{
    [screenName release];
    [password release];

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

        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];

        //Setup and init
        socket = [[AISocket socketWithHost:host port:port] retain];
        if(screenName != [propertiesDict objectForKey:@"Handle"]){
            [screenName release];
            screenName = [[propertiesDict objectForKey:@"Handle"] copy];
        }
        if(password != inPassword){
            [password release];
            password = [inPassword copy];
        }

        pingInterval = nil;
        firstPing = nil;
        
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

    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_DISCONNECTING] forKey:@"Status" account:self];

    //Delay updates until we're finished signing off
    [[owner contactController] delayContactListUpdatesFor:5]; //Signoff shouldn't take any longer than 5 seconds

    //Flush all our handle status flags
    enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES ownedBy:self] objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self removeAllStatusFlagsFromHandle:handle];
    }

    //Clean up and close down
    [socket release]; socket = nil;

    [pingTimer invalidate];
    [pingTimer release]; pingTimer = nil;

    [updateTimer invalidate];
    [updateTimer release]; updateTimer = nil;

    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
}

//Removes all the possible status flags (that are valid on AIM/TOC) from the passed handle
- (void)removeAllStatusFlagsFromHandle:(AIContactHandle *)handle
{
    NSArray	*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"Idle",@"Signon Date",@"Away",@"Client",@"TextProfile",nil];
    int		loop;
    
    for(loop = 0;loop < [keyArray count];loop++){
        [[handle statusArrayForKey:[keyArray objectAtIndex:loop]] removeObjectsWithOwner:self];
    }
    
    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray];
}

// Sends packets, receives packets, and dispatches commands 
- (void)update:(NSTimer *)timer
{
    AIMTOC2Packet	*packet;

    if(![socket isValid]){
        [self disconnect];
        [self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY_SOCKET_DROP];
        return;
    }
    
    if(connectionPhase == 0){ //Send & Receive regular AIM commands
        //Receive any incoming packets
        while([socket readyForReceiving] && (packet = [AIMTOC2Packet packetFromSocket:socket sequence:&remoteSequence])){
            if([packet frameType] == FRAMETYPE_DATA){
                NSString		*message = [packet string];
                NSString		*command = [message TOCStringArgumentAtIndex:0];

//                NSLog(@"<- %@",[packet string]);

                if([command compare:@"SIGN_ON"] == 0){
                    [self AIM_HandleSignOn:message];

                }else if([command compare:@"ERROR"] == 0){
                    [self AIM_HandleError:message];

                }else if([command compare:@"NICK"] == 0){
                    [self AIM_HandleNick:message];

                }else if([command compare:@"CONFIG2"] == 0){
                    [self AIM_HandleConfig:message];
                    [self AIM_SetStatus];	//Set our status

                    //Send AIM the init done message (at this point we become visible to other buddies)
                    [outQue addObject:[AIMTOC2Packet dataPacketWithString:@"toc_init_done" sequence:&localSequence]];

                    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self];
                    [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:self];

                }else if([command compare:@"PAUSE"] == 0){
                }else if([command compare:@"NEW_BUDDY_REPLY2"] == 0){
                }else if([command compare:@"IM_IN2"] == 0){
                    [self AIM_HandleMessageIn:message];

                }else if([command compare:@"UPDATE_BUDDY2"] == 0){
                    [self AIM_HandleUpdateBuddy:message];

                }else if([command compare:@"GOTO_URL"] == 0){
                    [self AIM_HandleGotoURL:message];

                }else if([command compare:@"EVILED"] == 0){
                }else if([command compare:@"CHAT_JOIN"] == 0){
                }else if([command compare:@"CHAT_LEFT"] == 0){
                }else if([command compare:@"CHAT_IN"] == 0){
                }else if([command compare:@"CHAT_INVITE"] == 0){
                }else if([command compare:@"CHAT_UPDATE_BUDDY"] == 0){
                }else if([command compare:@"ADMIN_NICK_STATUS"] == 0){
                }else if([command compare:@"ADMIN_PASSWD_STATUS"] == 0){
                }else if([command compare:@"RVOUS_PROPOSE"] == 0){
                }else{
                    NSLog(@"Unexpected TOC command '%@'",command);
                }

            }else if([packet frameType] == FRAMETYPE_KEEPALIVE){
                [self AIM_HandlePing];

            }else{
                NSLog(@"Unexpected packet frametype: %i",[packet frameType]);
            }
        }

    }else{ //Send & Receive the sign on commands
        [self signOnUpdate];
    }

    //Send any packets in the outQue
    while([outQue count] && [socket readyForSending]){
        [[outQue objectAtIndex:0] sendToSocket:socket];
//        NSLog(@"-> %@",[[outQue objectAtIndex:0] string]);
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
                    [self disconnect];
                    [self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY_CONNECT_ERROR];
                    return;
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

    //Install (or reset) the delay
    if(messageDelayTimer){
        [messageDelayTimer invalidate]; [messageDelayTimer release]; messageDelayTimer = nil;
    }
    
    messageDelayTimer = [[NSTimer scheduledTimerWithTimeInterval:MESSAGE_QUE_DELAY target:self selector:@selector(flushMessageDelayQue:) userInfo:nil repeats:NO] retain];
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

    //Install (or reset) the delay
    if(messageDelayTimer){
        [messageDelayTimer invalidate]; [messageDelayTimer release]; messageDelayTimer = nil;
    }
    
    messageDelayTimer = [[NSTimer scheduledTimerWithTimeInterval:MESSAGE_QUE_DELAY target:self selector:@selector(flushMessageDelayQue:) userInfo:nil repeats:NO] retain];
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
            NSArray	*groupArray;
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

- (void)AIM_RemoveGroup:(NSString *)groupName
{
    NSString *message = [NSString stringWithFormat:@"toc2_del_group \"%@\"",groupName];
    
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];    
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
    NSString		*path;
    NSDictionary	*errorDict;
    NSString		*errorMessage;
    BOOL		disconnect = NO;
    int			errorNumber = [[message TOCStringArgumentAtIndex:1] intValue];
    
    //Get the error message data
    //Error messages (and if we should disconnect) come from keys within the AIMErrors.plist file
    path = [[NSBundle bundleForClass:[self class]] pathForResource:AIM_ERRORS_FILE ofType:@"plist"];
    errorDict = [NSDictionary dictionaryWithContentsOfFile:path];

    //Get the corrent message and disconnect flag
    errorMessage = [[errorDict objectForKey:@"ErrorString"] objectForKey:[message TOCStringArgumentAtIndex:1]];
    if(!errorMessage) errorMessage = @"Unknown Error";
    disconnect = [[[errorDict objectForKey:@"ErrorDisc"] objectForKey:[message TOCStringArgumentAtIndex:1]] boolValue];

    //Display the error
    [[owner interfaceController] handleErrorMessage:[NSString stringWithFormat:@"AIM Error %i (%@)", errorNumber, screenName] withDescription:errorMessage];

    //Disconnecting Errors
    if(disconnect){
        [self disconnect];
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

- (void)AIM_HandleGotoURL:(NSString *)message
{
    NSString	*host, *port, *path, *urlString;
    NSURL	*url;
    NSData	*data;
    NSString	*profileHTML, *profile;
    NSString	*userName;

    //Key pieces of HTML that mark the begining and end of the AIM profile (and the username)
    #define USERNAME_START	@"Username : <B>"
    #define USERNAME_END	@"</B>"    
    #define PROFILE_START	@"<hr><br>"
    #define PROFILE_END		@"<br><hr><I>Legend:</I><br><br>"
    
    //Piece together the URL (http://host:port/profile#)
    host = [preferencesDict objectForKey:AIM_TOC2_KEY_HOST];
    port = [preferencesDict objectForKey:AIM_TOC2_KEY_PORT];
    path = [message nonBreakingTOCStringArgumentAtIndex:2];
    urlString = [NSString stringWithFormat:@"http://%@:%@/%@", host, port, path];
    
    //Fetch the site
    //Just to note: this caused a crash when the user had a proxy in previous versions of Adium
    url = [NSURL URLWithString:urlString];
    data = [url resourceDataUsingCache:NO];
    profileHTML = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];

    //Extract the username and profile
    userName = [self extractStringFrom:profileHTML between:USERNAME_START and:USERNAME_END];
    profile = [self extractStringFrom:profileHTML between:PROFILE_START and:PROFILE_END];

    if(userName && profile){
        AIContactHandle		*handle = [[owner contactController] handleWithService:[service handleServiceType] UID:[userName compactedString] forAccount:self];
        AIMutableOwnerArray	*ownerArray;

        //Add profile to the handle
        ownerArray = [handle statusArrayForKey:@"TextProfile"];
        [ownerArray removeObjectsWithOwner:self];
        [ownerArray addObject:[AIHTMLDecoder decodeHTML:profile] withOwner:self];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"TextProfile"]];
        
    }else{
        [[owner interfaceController] handleErrorMessage:@"Invalid Server Response" withDescription:@"The AIM server has returned HTML that Adium does not recognize."];
    }
}

//Handle a server ping
- (void)AIM_HandlePing
{
    if(pingInterval){
        //Reset the ping timer
        if(pingTimer){
            [pingTimer invalidate];
            [pingTimer release]; pingTimer = nil;
        }
        pingTimer = [[NSTimer scheduledTimerWithTimeInterval:pingInterval target:self selector:@selector(pingFailure:) userInfo:nil repeats:NO] retain];

    }else{ //A ping interval has not yet been established
        if(!firstPing){ //Record the date our first ping was recieved
            firstPing = [[NSDate date] retain];

        }else{ //On the second ping...
               //Determine the amount of time that has elapsed between the pings
            pingInterval = [[NSDate date] timeIntervalSinceDate:firstPing];
            [firstPing release]; firstPing = nil;

            //We multiply the ping interval by 2.2 to allow the ping time to arrive late (and to prevent disconnect if a single ping is lost).  The closer the scale is to 1, the more sensitive the ping will become.  The further away from 1, the longer it will take to realize a ping failure.  With a ping of 50 seconds, 2.2 would disconnect us 110 seconds after the latest ping, so anywhere between 60 and 170 seconds after the connection is lost.  This is responsive enough to prove useful, but lax enough to handle fairly extreme lag (and even the loss of a ping packet).
            pingInterval *= 2.2;

            NSLog(@"Server supports ping (%i)",(int)pingInterval);

            //Install a timer to auto-disconnect after the ping interval
            pingTimer = [[NSTimer scheduledTimerWithTimeInterval:pingInterval target:self selector:@selector(pingFailure:) userInfo:nil repeats:NO] retain];
        }
    }
}

//Called if the server ping fails to arrive
- (void)pingFailure:(NSTimer *)inTimer
{
    NSLog(@"Server's ping not recieved, disconnecting.");

    [self disconnect];
    [self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY_PING_FAILURE];
}


- (void)AIM_SetIdle:(double)inSeconds
{
    NSString	*idleMessage;

    idleMessage = [NSString stringWithFormat:@"toc_set_idle %0.0f",(double)inSeconds];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:idleMessage sequence:&localSequence]];
}

- (void)AIM_SetProfile:(NSString *)profile
{
    NSString	*message;

    message = [NSString stringWithFormat:@"toc_set_info \"%@\"",[self validCopyOfString:profile]];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
}

- (void)AIM_SetAway:(NSString *)away
{
    NSString	*message;

    if(away){
        message = [NSString stringWithFormat:@"toc_set_away \"%@\"",[self validCopyOfString:away]];
    }else{
        message = @"toc_set_away";
    }

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
}

- (void)AIM_GetProfile:(NSString *)handleUID
{
    NSString	*message;

    message = [NSString stringWithFormat:@"toc_get_info %@",handleUID];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
}

- (void)AIM_SetStatus
{
    double 		idle = [[[owner accountController] statusObjectForKey:@"IdleTime" account:self] doubleValue];
    NSAttributedString 	*profile = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"TextProfile" account:self]];
    NSAttributedString 	*away = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"AwayMessage" account:self]];
    
    if(idle){
        [self AIM_SetIdle:idle];
    }

    if(profile){
        [self AIM_SetProfile:[AIHTMLDecoder encodeHTML:profile]];
    }
    
    if(away){
        [self AIM_SetAway:[AIHTMLDecoder encodeHTML:away]];
    }
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

//Extracts a string from another, using 2 other strings to locate the desired segment
- (NSString *)extractStringFrom:(NSString *)searchString between:(NSString *)stringA and:(NSString *)stringB
{
    NSString	*string = nil;
    int		start, end;
    NSRange	range;

    range = [searchString rangeOfString:stringA];
    start = range.location + range.length;
    end = [searchString rangeOfString:stringB].location;

    if(start >= 0 && start < [searchString length] && end >= 0 && end < [searchString length] && end > start){ //Ensure the ranges are valid
        string = [searchString substringWithRange:NSMakeRange(start, end - start)];
    }

    return(string);
}

//Attempts to auto-reconnect (after an X second delay)
- (void)autoReconnectAfterDelay:(int)delay
{
    //Install a timer to autoreconnect after a delay
    [NSTimer scheduledTimerWithTimeInterval:delay
                                     target:self
                                   selector:@selector(autoReconnectTimer:)
                                   userInfo:nil
                                    repeats:NO];

    NSLog(@"Auto-Reconnect in %i seconds",delay);
}

//
- (void)autoReconnectTimer:(NSTimer *)inTimer
{
    //If we're still offline, continue with the reconnect
    if([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_OFFLINE){

        NSLog(@"Attempting Auto-Reconnect");

        //Instead of calling connect, we directly call the second phase of connecting, passing it the user's password.  This prevents users who don't keychain passwords from having to enter them for a reconnect.
        [self finishConnect:password];
    }
}


@end
