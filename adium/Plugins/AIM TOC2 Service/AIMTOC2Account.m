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

#define AIM_PACKET_MAX_LENGTH	2048

#define SIGN_ON_MAX_WAIT	10.0		//Max amount of time to wait for first sign on packet
#define SIGN_ON_UPKEEP_INTERVAL	0.8		//Max wait before sign up updates

#define AUTO_RECONNECT_DELAY_PING_FAILURE	2.0	//Delay in seconds
#define AUTO_RECONNECT_DELAY_SOCKET_DROP	2.0	//Delay in seconds
#define AUTO_RECONNECT_DELAY_CONNECT_ERROR	5.0	//Delay in seconds

static char *hash_password(const char * const password);

@interface AIMTOC2Account (PRIVATE)
- (void)update:(NSTimer *)timer;
- (void)signOnUpdate;
- (void)flushMessageDelayQue:(NSTimer *)inTimer;
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle;
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
- (void)AIM_HandleEviled:(NSString *)message;
- (void)AIM_HandlePing;
- (void)AIM_HandleClientEvent:(NSString *)inCommand;
- (void)AIM_HandleEncMessageIn:(NSString *)inCommand;
- (void)AIM_SendClientEvent:(int)inEvent toHandle:(NSString *)handleUID;
- (void)AIM_SendMessage:(NSString *)inMessage toHandle:(NSString *)handleUID;
- (void)AIM_SendMessageEnc:(NSString *)inMessage toHandle:(NSString *)handleUID;
- (void)AIM_SetIdle:(double)inSeconds;
- (void)AIM_SetProfile:(NSString *)profile;
- (void)AIM_SetNick:(NSString *)nick;
- (void)AIM_SetAway:(NSString *)away;
- (void)AIM_SetStatus;
- (void)AIM_GetProfile:(NSString *)handleUID;
- (void)AIM_GetStatus:(NSString *)handleUID;
- (void)AIM_SendWarningToHandle:(NSString *)handleUID anonymous:(BOOL)anonymous;
- (NSString *)extractStringFrom:(NSString *)searchString between:(NSString *)stringA and:(NSString *)stringB;
- (NSString *)validCopyOfString:(NSString *)inString;
- (void)connect;
- (void)disconnect;
- (void)updateContactStatus:(NSNotification *)notification;
- (void)pingFailure:(NSTimer *)inTimer;
- (void)autoReconnectAfterDelay:(int)delay;
- (void)autoReconnectTimer:(NSTimer *)inTimer;
- (void)firstSignOnUpdateReceived;
- (void)waitForLastSignOnUpdate:(NSTimer *)inTimer;
- (void)handle:(AIHandle *)inHandle isIdle:(BOOL)inIdle;
@end

@implementation AIMTOC2Account

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    AIPreferenceController	*preferenceController = [owner preferenceController];

    //Init
    outQue = [[NSMutableArray alloc] init];
    handleDict = [[NSMutableDictionary alloc] init];
    pingTimer = nil;
    pingInterval = nil;
    firstPing = nil;
    screenName = nil;
    password = nil;
    profileURLHandle = nil;
    
    //Delayed handle modification
    deleteDict = [[NSMutableDictionary alloc] init];
    addDict = [[NSMutableDictionary alloc] init];
    messageDelayTimer = nil;

    //
    [[owner notificationCenter] addObserver:self selector:@selector(updateContactStatus:) name:Contact_UpdateStatus object:nil];
    
    //Load our preferences
    preferencesDict = [[preferenceController preferencesForGroup:AIM_TOC2_PREFS] retain];

    //Clear the online state.  'Auto-Connect' values are used, not the previous online state.
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];

    //Traffic watch debug window
    if([NSEvent controlKey]){
        [NSBundle loadNibNamed:@"TrafficWatch" owner:self];
    }
}

// Return a view for the connection window
- (id <AIAccountViewController>)accountView{
    return([AIMTOC2AccountViewController accountViewForOwner:owner account:self]);
}

// Return a unique ID specific to THIS account plugin, and the user's account name
- (NSString *)accountID{
    return([NSString stringWithFormat:@"TOC2.%@",[[propertiesDict objectForKey:@"Handle"] compactedString]]);
}

//The user's account name
- (NSString *)UID{
    return([[propertiesDict objectForKey:@"Handle"] compactedString]);
}

//The service ID (shared by any account code accessing this service)
- (NSString *)serviceID{
    return(@"AIM");
}

//ServiceID.UID
- (NSString *)UIDAndServiceID{
    return([NSString stringWithFormat:@"%@.%@",[self serviceID],[self UID]]);
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


// AIAccount_Handles ---------------------------------------------------------------------------
// Add a handle
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
{
    AIHandle	*handle;

    if(inTemporary) inGroup = @"__Strangers";
    if(!inGroup) inGroup = @"Unknown";

    //Check to see if the handle already exists, and remove the duplicate if it does
    if(handle = [handleDict objectForKey:inUID]){
        [self removeHandleWithUID:inUID]; //Remove the handle
    }

    //Create the handle
    handle = [AIHandle handleWithServiceID:[[[self service] handleServiceType] identifier] UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:self];

    //Add the handle
    [self AIM_AddHandle:[handle UID] toGroup:[handle serverGroup]]; //Add it server-side
    [handleDict setObject:handle forKey:[handle UID]]; //Add it locally

    //Update the contact list
    [[owner contactController] handle:handle addedToAccount:self];

    return(handle);
}

// Remove a handle
- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    AIHandle	*handle = [handleDict objectForKey:inUID];

    //Remove the handle
    [self AIM_RemoveHandle:[handle UID] fromGroup:[handle serverGroup]]; //Remove it server-side
    [handleDict removeObjectForKey:[handle UID]]; //Remove it locally

    //Update the contact list
    [[owner contactController] handle:handle removedFromAccount:self];
        
    return(YES);
}

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup
{
    //
    return(YES);
}

// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;

    //Empty the group
    enumerator = [[handleDict allValues] objectEnumerator];
    while((handle = [enumerator nextObject])){
        if([[handle serverGroup] compare:inGroup] == 0){
            [self removeHandleWithUID:[handle UID]];
        }
    }

    //Remove it
//    [self AIM_RemoveGroup:inGroup];

    return(YES);
}

// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;
    NSMutableArray	*groupContents;

    //There is no easy way to rename a group on TOC!!
    //So what we do is remove all the buddies from the existing group,
    //and then re-add them to a new group with the correct name.
    groupContents = [[[NSMutableArray alloc] init] autorelease];

    enumerator = [[handleDict allValues] objectEnumerator];
    while((handle = [enumerator nextObject])){
        if([[handle serverGroup] compare:inGroup] == 0){
            [self AIM_RemoveHandle:[handle UID] fromGroup:[handle serverGroup]]; //Remove it server-side
            [groupContents addObject:handle];
        }
    }

    enumerator = [groupContents objectEnumerator];
    while((handle = [enumerator nextObject])){
        [handle setServerGroup:newName]; //Set the handle to the new server group
        [self AIM_AddHandle:[handle UID] toGroup:newName]; //Add it server-side
    }
    
    //Update the contact list
    [[owner contactController] handlesChangedForAccount:self];

    return(YES);
}

// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    return([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_ONLINE);
}

// Return a dictionary of our handles
- (NSDictionary *)availableHandles
{
    int	status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];
    
    if(status == STATUS_ONLINE || status == STATUS_CONNECTING){
        return(handleDict);
    }else{
        return(nil);
    }
}

 

// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(id <AIContentObject>)object
{
    BOOL	sent = NO;
    NSString	*message;
    AIHandle	*handle;

    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
        message = [self validCopyOfString:[AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message] encodeFullString:YES]];

        if([message length] <= AIM_PACKET_MAX_LENGTH){
            //Get the handle for receiving this content
            handle = [[owner contactController] handleOfContact:[object destination] forReceivingContentType:CONTENT_MESSAGE_TYPE fromAccount:self];
            if(!handle){
                handle = [self addHandleWithUID:[[[object destination] UID] compactedString] serverGroup:nil temporary:YES];
            }

            [self AIM_SendMessageEnc:message toHandle:[handle UID]];
            sent = YES;

        }else{
            [[owner interfaceController] handleErrorMessage:@"Message too big" withDescription:@"The message you're trying to send it too large.  Try breaking it into parts and sending them one at a time."];

        }

    }else if([[object type] compare:CONTENT_TYPING_TYPE] == 0){
        BOOL	typing;

        //Get the handle for receiving this content
        handle = [[owner contactController] handleOfContact:[object destination] forReceivingContentType:CONTENT_TYPING_TYPE fromAccount:self];
        typing = [(AIContentTyping *)object typing];

        //Send the typing client event
        if(handle){
            [self AIM_SendClientEvent:(typing ? 2 : 0) toHandle:[handle UID]];
            sent = YES;
	    
        }
	
    }else if([[object type] compare:CONTENT_WARNING_TYPE] == 0){
        BOOL	anonymous;

        //Get the handle for receiving this content
        handle = [[owner contactController] handleOfContact:[object destination] forReceivingContentType:CONTENT_WARNING_TYPE fromAccount:self];
        anonymous = [(AIContentWarning *)object anonymous];

        //Send the typing client event
        if(handle){
            [self AIM_SendWarningToHandle:[handle UID] anonymous:anonymous];
            sent = YES;
        }
    }
    
    return(sent);
}

// Return YES if we're available for sending the specified content
- (BOOL)availableForSendingContentType:(NSString *)inType toHandle:(AIHandle *)inHandle
{
    BOOL available = NO;

    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        //If we're online, ("and the contant is online" or nil), return YES
        if([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_ONLINE &&
           (![[handleDict allValues] containsObject:inHandle] || [[[inHandle statusDictionary] objectForKey:@"Online"] intValue])){
            available = YES;
        }
    }

    return(available);
}


// AIAccount_Status --------------------------------------------------------------------------------
// Returns an array of the status keys we support
- (NSArray *)supportedStatusKeys
{
    return([NSArray arrayWithObjects:@"Online", @"IdleSince", @"IdleManuallySet", @"TextProfile", @"AwayMessage", nil]);
}

// Respond to account status changes
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    ACCOUNT_STATUS	status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];

    if([key compare:@"Online"] == 0){
        if([inValue boolValue]){ //Connect
            if(status == STATUS_OFFLINE){
                [self connect];
            }            
        }else{ //Disconnect
            if(status == STATUS_ONLINE){
                [self disconnect];
            }
        }

    }

    //Ignore the following keys unless we're online
    if(status == STATUS_ONLINE){
       if([key compare:@"IdleSince"] == 0){
        NSDate		*oldIdle = [[owner accountController] statusObjectForKey:@"IdleSince" account:self];
        NSDate		*newIdle = inValue;

        if(oldIdle != nil && newIdle != nil){
            [self AIM_SetIdle:0]; //Most AIM cliens will ignore 2 consecutive idles, so we unidle, then re-idle to the new value
        }

        [self AIM_SetIdle:(-[newIdle timeIntervalSinceNow])];

        }else if([key compare:@"TextProfile"] == 0){
            [self AIM_SetProfile:[AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:inValue] encodeFullString:YES]];
    
        }else if([key compare:@"AwayMessage"] == 0){
            if(inValue){
                [self AIM_SetAway:[AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:inValue] encodeFullString:YES]];
            }else{
                [self AIM_SetAway:nil];
            }
        }
    }

}

// Update the status of a handle
- (void)updateContactStatus:(NSNotification *)notification
{
    NSArray		*desiredKeys = [[notification userInfo] objectForKey:@"Keys"];
    AIListContact	*contact = [notification object];

    //AIM requires a delayed load of profiles...
    if([[contact statusArrayForKey:@"Online"] greatestIntegerValue]){
        if([desiredKeys containsObject:@"TextProfile"]){
            [self AIM_GetProfile:[contact UID]];
        }
    }
}



// Connecting and Disconnecting ---------------------------------------------------------------------------
// Connect
- (void)connect
{
    //Get password
    [[owner accountController] passwordForAccount:self notifyingTarget:self selector:@selector(finishConnect:)];
}

// Finish connecting (after the password is received)
- (void)finishConnect:(NSString *)inPassword
{
    if(inPassword && [inPassword length] != 0){
        NSString	*host = [preferencesDict objectForKey:AIM_TOC2_KEY_HOST];
        int		port = [[preferencesDict objectForKey:AIM_TOC2_KEY_PORT] intValue];

        //Set our status as connecting
        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];

        //Remember the account name and password
        if(screenName != [propertiesDict objectForKey:@"Handle"]){
            [screenName release]; screenName = [[propertiesDict objectForKey:@"Handle"] copy];
        }
        if(password != inPassword){
            [password release]; password = [inPassword copy];
        }

        //Debug window
        if(textView_trafficWatchDEBUG){
            [[textView_trafficWatchDEBUG window] setTitle:screenName];
            [[textView_trafficWatchDEBUG window] makeKeyAndOrderFront:nil];
        }

        //Init our socket and start connecting
        socket = [[AISocket socketWithHost:host port:port] retain];
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
    AIHandle		*handle;

    //Set our status as disconnecting
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_DISCONNECTING] forKey:@"Status" account:self];

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
    [socket release]; socket = nil;
    [pingTimer invalidate];
    [pingTimer release]; pingTimer = nil;
    [updateTimer invalidate];
    [updateTimer release]; updateTimer = nil;

    //Set our status as offline
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
}


// Auto-Reconnect ------------------------------------------------------------------------
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


// Packet/Protocol Processing ---------------------------------------------------------------------------
// Check for sign on packets and update status
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
                localSequence = +(short) (65536.0*rand()/(RAND_MAX+1.0));

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

//                message = [NSString stringWithFormat:@"toc2_signon login.oscar.aol.com 5190 %@ %s english TIC:AIMM 160 %lu",[screenName compactedString],hash_password([password cString]),o];
                message = [NSString stringWithFormat:@"toc2_login login.oscar.aol.com 29999 %@ %s English \"TIC:\\$Revision: 1.69 $\" 160 US \"\" \"\" 3 0 30303 -kentucky -utf8 %lu",[screenName compactedString],hash_password([password cString]),o];

                [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];

                connectionPhase = 0;
            }
            break;
    }
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

                if(textView_trafficWatchDEBUG){
                    [[textView_trafficWatchDEBUG textStorage] appendString:@"<- "
                                                            withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:11],NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]];
                    [[textView_trafficWatchDEBUG textStorage] appendString:[NSString stringWithFormat:@"%@",[packet string]]
                                                            withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:11],NSFontAttributeName,[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.4 alpha:1.0],NSForegroundColorAttributeName,nil]];
                    [[textView_trafficWatchDEBUG textStorage] appendString:@"\r" withAttributes:[NSDictionary dictionary]];
                    [textView_trafficWatchDEBUG scrollRangeToVisible:NSMakeRange([[textView_trafficWatchDEBUG textStorage] length],0)];
                }

                if([command compare:@"SIGN_ON"] == 0){
                    [self AIM_HandleSignOn:message];

                }else if([command compare:@"ERROR"] == 0){
                    [self AIM_HandleError:message];

                }else if([command compare:@"NICK"] == 0){
                    [self AIM_HandleNick:message];

                }else if([command compare:@"CONFIG2"] == 0){
                    [self AIM_HandleConfig:message];
                    [self AIM_SetStatus];	//Set our status

                    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self];
                    [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:self];

                    //Set Caps
//                    [outQue addObject:[AIMTOC2Packet dataPacketWithString:@"toc_set_caps 0946134D-4C7F-11D1-8222-444553540000 09461346-4C7F-11D1-8222-444553540000 09461343-4C7F-11D1-8222-444553540000 09461348-4C7F-11D1-8222-444553540000" sequence:&localSequence]];
                    
                    //Send AIM the init done message (at this point we become visible to other buddies)
                    [outQue addObject:[AIMTOC2Packet dataPacketWithString:@"toc_init_done" sequence:&localSequence]];

                    
                }else if([command compare:@"PAUSE"] == 0){
                }else if([command compare:@"NEW_BUDDY_REPLY2"] == 0){
                }else if([command compare:@"BUDDY_CAPS2"] == 0){
                }else if([command compare:@"BART2"] == 0){
                }else if([command compare:@"IM_IN2"] == 0){
                    [self AIM_HandleMessageIn:message];

                }else if([command compare:@"IM_IN_ENC2"] == 0){
                    [self AIM_HandleEncMessageIn:message];

                }else if([command compare:@"CLIENT_EVENT2"] == 0){
                    [self AIM_HandleClientEvent:message];

                }else if([command compare:@"UPDATE_BUDDY2"] == 0){
                    [self AIM_HandleUpdateBuddy:message];

                }else if([command compare:@"GOTO_URL"] == 0){
                    [self AIM_HandleGotoURL:message];

                }else if([command compare:@"EVILED"] == 0){
		    [self AIM_HandleEviled:message];
		    
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
        AIMTOC2Packet	*packet = [outQue objectAtIndex:0];

        if([packet length] <= 2048){
            [[outQue objectAtIndex:0] sendToSocket:socket];
        }else{
            NSLog(@"Attempted to send invalid packet (Too large, %i)",[packet length]);
        }

        if(textView_trafficWatchDEBUG){
            [[textView_trafficWatchDEBUG textStorage] appendString:@"-> "
                                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:11],NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]];
            [[textView_trafficWatchDEBUG textStorage] appendString:[NSString stringWithFormat:@"%@",[[outQue objectAtIndex:0] string]]
                                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:11],NSFontAttributeName,[NSColor colorWithCalibratedRed:0.0 green:0.4 blue:0.0 alpha:1.0],NSForegroundColorAttributeName,nil]];
            [[textView_trafficWatchDEBUG textStorage] appendString:@"\r" withAttributes:[NSDictionary dictionary]];
            [textView_trafficWatchDEBUG scrollRangeToVisible:NSMakeRange([[textView_trafficWatchDEBUG textStorage] length],0)];
        }
        
        [outQue removeObjectAtIndex:0];
    }
}

// Contact list modification ---------------------------------------------------------------------------
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

- (void)AIM_RemoveGroup:(NSString *)groupName //(Must be an empty group)
{
    NSString *message = [NSString stringWithFormat:@"toc2_del_group \"%@\"",groupName];
    
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];    
}


//Server -> Client Command Handlers ------------------------------------------------------
//CLIENT_EVENT2:adamiser@mac.com:2
- (void)AIM_HandleClientEvent:(NSString *)inCommand
{
    AIHandle		*handle;
    NSString		*name;
    int			event;

    //Extract the handle and event ID
    name = [inCommand TOCStringArgumentAtIndex:1];
    event = [[inCommand TOCStringArgumentAtIndex:2] intValue];

    //Ensure a handle exists (creating a stranger if necessary)
    handle = [handleDict objectForKey:[name compactedString]];
    if(!handle){
        handle = [self addHandleWithUID:[name compactedString] serverGroup:nil temporary:YES];
    }

    //Post the correct typing state
    if(event == 0){ //Not typing
        [[handle statusDictionary] setObject:[NSNumber numberWithInt:NO] forKey:@"Typing"];
    }else if(event == 1){ //Still typing?
            
    }else if(event == 2){ //Typing
        [[handle statusDictionary] setObject:[NSNumber numberWithInt:YES] forKey:@"Typing"];
    }else{
        NSLog(@"%@ Unknown client event %i",name,event);
    }
    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]];

}

//user:F:F:T:O,:F:U:en:message
- (void)AIM_HandleEncMessageIn:(NSString *)inCommand
{
    AIHandle		*handle;
    NSString		*name;
    NSString		*rawMessage;
    NSAttributedString	*messageText;
    AIContentMessage	*messageObject;

    //Extract the handle and message from the command
    name = [inCommand TOCStringArgumentAtIndex:1];
    rawMessage = [inCommand nonBreakingTOCStringArgumentAtIndex:9];

    rawMessage = [[NSString alloc] initWithData:[NSData dataWithBytes:[rawMessage cString] length:[rawMessage length]]
                                       encoding:NSJapaneseEUCStringEncoding/*NSUnicodeStringEncoding*/];
    //kCFStringEncodingUnicode



    //Ensure a handle exists (creating a stranger if necessary)
    handle = [handleDict objectForKey:[name compactedString]];
    if(!handle){
        handle = [self addHandleWithUID:[name compactedString] serverGroup:nil temporary:YES];
    }

    //Clear typing flag
    if([[[handle statusDictionary] objectForKey:@"Typing"] intValue]){
        [[handle statusDictionary] setObject:[NSNumber numberWithInt:NO] forKey:@"Typing"];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]];
    }

    //Create a content object for the message
    messageText = [AIHTMLDecoder decodeHTML:rawMessage];
    messageObject = [AIContentMessage messageWithSource:[handle containingContact] destination:self date:nil message:messageText];

    //Add the content object
    [[owner contentController] addIncomingContentObject:messageObject];
}

- (void)AIM_HandleMessageIn:(NSString *)inCommand
{
    AIHandle		*handle;
    NSString		*name;
    NSString		*rawMessage;
    NSAttributedString	*messageText;
    AIContentMessage	*messageObject;

    //Extract the handle and message from the command
    name = [inCommand TOCStringArgumentAtIndex:1];
    rawMessage = [inCommand nonBreakingTOCStringArgumentAtIndex:4];

    //Ensure a handle exists (creating a stranger if necessary)
    handle = [handleDict objectForKey:[name compactedString]];
    if(!handle){
        handle = [self addHandleWithUID:[name compactedString] serverGroup:nil temporary:YES];
    }

    //Clear typing flag
    if([[[handle statusDictionary] objectForKey:@"Typing"] intValue]){
        [[handle statusDictionary] setObject:[NSNumber numberWithInt:NO] forKey:@"Typing"];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]];
    }

    //Create a content object for the message
    messageText = [AIHTMLDecoder decodeHTML:rawMessage];
    messageObject = [AIContentMessage messageWithSource:[handle containingContact] destination:self date:nil message:messageText];

    //Add the content object
    [[owner contentController] addIncomingContentObject:messageObject];
}         

- (void)AIM_SendClientEvent:(int)inEvent toHandle:(NSString *)handleUID
{
    NSString	*command;

    //Create the message string
    command = [NSString stringWithFormat:@"toc2_client_event %@ %i",handleUID,inEvent];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:command sequence:&localSequence]];
}

- (void)AIM_SendMessage:(NSString *)inMessage toHandle:(NSString *)handleUID
{
    NSString	*command;

    //Create the message string
    command = [NSString stringWithFormat:@"toc2_send_im %@ \"%@\"",handleUID,inMessage];
    
    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:command sequence:&localSequence]];
}

- (void)AIM_SendMessageEnc:(NSString *)inMessage toHandle:(NSString *)handleUID
{
    NSString	*command;
    
    //Create the message string (Automatic (T,F) - Client Type (O, U, etc), language (en, ja, ...) )??
    command = [NSString stringWithFormat:@"toc2_send_im_enc %@ F U en \"%@\"",handleUID,inMessage];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:command sequence:&localSequence]];
}

//UPDATE_BUDDY2:<screenname>:<online>:<warning>:<signon Time>:<idletime>:<userclass>:<???>
- (void)AIM_HandleUpdateBuddy:(NSString *)message
{
    NSString		*name = [message TOCStringArgumentAtIndex:1];
    NSString		*compactedName = [name compactedString];
    AIHandle		*handle = nil;
    NSMutableArray	*alteredStatusKeys;

    //Sign on update monitoring
    if(processingSignOnUpdates) numberOfSignOnUpdates++;
    if(waitingForFirstUpdate) [self firstSignOnUpdateReceived];
    
    //Get the handle
    handle = [handleDict objectForKey:compactedName];

    if(handle){
        NSMutableDictionary	*handleStatusDict = [handle statusDictionary];
        NSString		*userFlags = [message TOCStringArgumentAtIndex:6];
        BOOL			online;
        BOOL			away;
        int			warning;
        double			idleTime;
        NSDate			*signOnDate;        
        char			clientA, clientB;
        NSNumber		*storedValue;
        NSDate			*storedDate;
        NSString		*storedString;
        NSString		*client;
                
        alteredStatusKeys = [[[NSMutableArray alloc] init] autorelease];

        //Get the handle's status from the update event
        online = ([[message TOCStringArgumentAtIndex:2] characterAtIndex:0] == 'T');
        warning = [[message TOCStringArgumentAtIndex:3] intValue];
        idleTime = ([[message TOCStringArgumentAtIndex:5] doubleValue] * 60.0);
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
        
        //There is an extra unknown parameter at the end of the update message.  In my experience, the only possible value is '0'.  I'm sure the value has some purpose though
//        if([[message TOCStringArgumentAtIndex:7] compare:@"0"] != 0){
//            NSLog(@"****%@ has a mystery value of [%@]****",name,[message TOCStringArgumentAtIndex:7]);
//        }

        //Online/Offline
        storedValue = [handleStatusDict objectForKey:@"Online"];
        if(storedValue == nil || online != [storedValue intValue]){
            [handleStatusDict setObject:[NSNumber numberWithInt:online] forKey:@"Online"];
            [alteredStatusKeys addObject:@"Online"];
        }

        //Warning
        storedValue = [handleStatusDict objectForKey:@"Warning"];
        if(storedValue == nil || warning != [storedValue intValue]){
            [handleStatusDict setObject:[NSNumber numberWithInt:warning] forKey:@"Warning"];
            [alteredStatusKeys addObject:@"Warning"];

	    if(warning < [storedValue intValue]){
		[handleStatusDict setObject:[NSNumber numberWithBool:YES] forKey:@"Cooldown"];
		[alteredStatusKeys addObject:@"Cooldown"];
	    }else{
		[handleStatusDict setObject:[NSNumber numberWithBool:NO] forKey:@"Cooldown"];
		[alteredStatusKeys addObject:@"Cooldown"];
	    }
        }

        //Idle time (seconds)
        storedDate = [handleStatusDict objectForKey:@"IdleSince"];
        if(storedDate == nil || (idleTime != -[storedDate timeIntervalSinceNow])){
            if(idleTime == 0 && storedDate){
                [handleStatusDict removeObjectForKey:@"IdleSince"];
                [alteredStatusKeys addObject:@"IdleSince"];
            }else if(idleTime > 0){
                [handleStatusDict setObject:[NSDate dateWithTimeIntervalSinceNow:-idleTime] forKey:@"IdleSince"];
                [alteredStatusKeys addObject:@"IdleSince"];
            }
        }

        //Sign on date
        storedDate = [handleStatusDict objectForKey:@"Signon Date"];
        if(storedDate == nil || ![signOnDate isEqualToDate:storedDate]){
            [handleStatusDict setObject:signOnDate forKey:@"Signon Date"];
            [alteredStatusKeys addObject:@"Signon Date"];
        }

        //Away
        storedValue = [handleStatusDict objectForKey:@"Away"];
        if(storedValue == nil || away != [storedValue intValue]){
            [handleStatusDict setObject:[NSNumber numberWithBool:away] forKey:@"Away"];
            [alteredStatusKeys addObject:@"Away"];
        }

        //Client
        storedString = [handleStatusDict objectForKey:@"Client"];
        if(storedString == nil || [client compare:storedString] != 0){
            [handleStatusDict setObject:client forKey:@"Client"];
            [alteredStatusKeys addObject:@"Client"];
        }
        
        //Display Name
        storedString = [handleStatusDict objectForKey:@"Display Name"];
        if(storedString == nil || [name compare:storedString] != 0){
            [handleStatusDict setObject:name forKey:@"Display Name"];
            [alteredStatusKeys addObject:@"Display Name"];
        }

        //Let the contact list know a handle's status changed
        if([alteredStatusKeys count]){
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:alteredStatusKeys];
        }
        
    }else{
        NSLog(@"Unknown handle %@",compactedName);
    }

}

- (void)AIM_HandleNick:(NSString *)message
{
/*    if([screenName compare:[message TOCStringArgumentAtIndex:1]] != 0){
        NSString *message = [NSString stringWithFormat:@"toc_format_nickname \"%@\"",screenName];
        [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
    }*/
}

- (void)AIM_SetNick:(NSString *)nick
{
    NSString *message = [NSString stringWithFormat:@"toc_format_nickname \"%@\"",nick];
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
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
    NSCharacterSet	*endlines = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
    NSString		*configString = [message nonBreakingTOCStringArgumentAtIndex:1];
    NSString		*type;
    NSString		*value;
    NSString		*currentGroup = @"__NoGroup?";
    int			index = 0;
    
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
                NSRange	invalidRange;
                
                //Occasionally the config will have :'s appended to the end of a contact's name.  We strip any :'s from the end of the name value here.
                invalidRange = [value rangeOfString:@":"];
                if(invalidRange.location != NSNotFound){
                    value = [value substringToIndex:invalidRange.location]; //Strip any trailing :'s
                }
                
                //Parse the information
                if([type compare:@"m"] == 0){
                    //NSLog(@"Privacy Mode:%@",value);
                    
                }else if([type compare:@"g"] == 0){ //GROUP
                    //Save the new group name string
                    [currentGroup release];
                    currentGroup = [value copy];
                    index = 0;

                }else if([type compare:@"b"] == 0){ //BUDDY
                    //Create the handle
                    [handleDict setObject:[AIHandle handleWithServiceID:[[service handleServiceType] identifier]
                                                                    UID:[value compactedString]
                                                            serverGroup:currentGroup
                                                              temporary:NO
                                                             forAccount:self]
                                   forKey:[value compactedString]];

                    index++;

                }else if([type compare:@"p"] == 0){
                }else if([type compare:@"d"] == 0){
                }else if([type compare:@"m"] == 0){
                }else if([type compare:@"pref"] == 0){
                }else if([type compare:@"20"] == 0){
                }else if([type compare:@"done"] == 0){
                }else{
                    //NSLog(@"Unknown Config Type '%@', value '%@'.",type,value);
                }
            }
        }
    }

    [[owner contactController] handlesChangedForAccount:self];
    [[owner contactController] setHoldContactListUpdates:YES]; //Hold updates until we're finished signing on

    //Adium waits for the first sign on update, and then checks for aditional updates every .2 seconds.  When the stream of updates stops, the account can be assumed online, and contact list updates resumed.
    //If no updates are receiced for 5 seconds, we assume 'no available contacts' and resume contact list updates.
    waitingForFirstUpdate = YES;
    processingSignOnUpdates = YES;
    numberOfSignOnUpdates = 0;
    [NSTimer scheduledTimerWithTimeInterval:(SIGN_ON_MAX_WAIT) //5 Seconds max
                                     target:self
                                   selector:@selector(firstSignOnUpdateReceived)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)firstSignOnUpdateReceived
{
    if(waitingForFirstUpdate){
        waitingForFirstUpdate = NO;

        NSLog(@"%@ firstSignOnUpdateReceived",[self accountDescription]);

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
        NSLog(@"%@ sign on is complete",[self accountDescription]);

        //No updates received, sign on is complete
        [inTimer invalidate]; //Stop this timer
        [[owner contactController] setHoldContactListUpdates:NO]; //Resume contact list updates
        processingSignOnUpdates = NO;
    }else{
        NSLog(@"%@ .. (%i)",[self accountDescription],numberOfSignOnUpdates);
        numberOfSignOnUpdates = 0;
    }
}

//
- (void)AIM_HandleGotoURL:(NSString *)message
{
    NSString	*host, *port, *path, *urlString;
    NSURL	*url;

    //Cancle any existing profile load
    if(profileURLHandle){
        [profileURLHandle cancelLoadInBackground];
    }

    //Set up the address
    host = [socket hostIP]; //We must request our profile from the same server that we connected to.
    port = [preferencesDict objectForKey:AIM_TOC2_KEY_PORT];
    path = [message nonBreakingTOCStringArgumentAtIndex:2];
    urlString = [NSString stringWithFormat:@"http://%@:%@/%@", host, port, path];

    //Fetch the site
    //Just to note: this caused a crash when the user had a proxy in previous versions of Adium
    url = [NSURL URLWithString:urlString];
    profileURLHandle = [[url URLHandleUsingCache:NO] retain];
    [profileURLHandle addClient:self];
    [profileURLHandle loadInBackground];
}

- (void)URLHandleResourceDidFinishLoading:(NSURLHandle *)sender
{
    NSString	*profileHTML, *profile;
    NSString	*userName;

    profileHTML = [[[NSString alloc] initWithData:[sender resourceData] encoding:NSISOLatin1StringEncoding] autorelease];
    
    //Key pieces of HTML that mark the begining and end of the AIM profile (and the username)
    #define USERNAME_START	@"Username : <B>"
    #define USERNAME_END	@"</B>"
    #define PROFILE_START	@"<hr><br>\n"
    #define PROFILE_END		@"<br><hr><I>Legend:</I><br><br>"

    //Extract the username and profile
    userName = [self extractStringFrom:profileHTML between:USERNAME_START and:USERNAME_END];
    profile = [self extractStringFrom:profileHTML between:PROFILE_START and:PROFILE_END];

    if(userName && profile){
        AIHandle	*handle = [handleDict objectForKey:[userName compactedString]];

        //Add profile to the handle
        [[handle statusDictionary] setObject:[AIHTMLDecoder decodeHTML:profile] forKey:@"TextProfile"];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"TextProfile"]];

    }else{
        [[owner interfaceController] handleErrorMessage:@"Invalid Server Response" withDescription:@"The AIM server has returned HTML that Adium does not recognize."];
        NSLog(@"Profile:%@",profileHTML);
    }

    //Cleanup
    [profileURLHandle release]; profileURLHandle = nil;
}

- (void)URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes
{
    //NSLog(@"resourceDataDidBecomeAvailable");
}
- (void)URLHandleResourceDidBeginLoading:(NSURLHandle *)sender
{
    //NSLog(@"URLHandleResourceDidBeginLoading");
}
- (void)URLHandleResourceDidCancelLoading:(NSURLHandle *)sender
{
    if(profileURLHandle){
        [profileURLHandle release]; profileURLHandle = nil;
    }
    //NSLog(@"URLResourceDidCancelLoading");
}
- (void)URLHandle:(NSURLHandle *)sender resourceDidFailLoadingWithReason:(NSString *)reason
{
    if(profileURLHandle){
        [profileURLHandle release]; profileURLHandle = nil;
    }
    //NSLog(@"resourceDidFailLoadingWithReason: %@",reason);    
}

- (void)AIM_HandleEviled:(NSString *)message
{
    NSString		*compactedName = [[self UID] compactedString];
    AIHandle		*handle = [handleDict objectForKey:compactedName];
    NSMutableDictionary	*handleStatusDict = [handle statusDictionary];
	
    NSString	*level = [message TOCStringArgumentAtIndex:1];
    NSString	*enemy = [message TOCStringArgumentAtIndex:2];
    BOOL	cooldown = [[handleStatusDict objectForKey:@"Cooldown"] boolValue];

    NSLog(@"%s",cooldown);
    
    if((enemy == nil) && (!cooldown)){
	[[owner interfaceController] handleErrorMessage:@"Warning Level (Anonymous)" withDescription:[NSString stringWithFormat:@"Your warning level is now: %@\%",level]];

    }if((cooldown) && ([level compare:@"0"])){
	[[owner interfaceController] handleErrorMessage:[NSString stringWithFormat:@"Warning Level Cleared"] withDescription:[NSString stringWithFormat:@"Your warning level is now normal"]];
	
    }else{
	[[owner interfaceController] handleErrorMessage:[NSString stringWithFormat:@"Warning Level (%@)",enemy] withDescription:[NSString stringWithFormat:@"Your warning level is now: %@\%",level]];
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
    //Profile length must be 1024 charactes or less (not including backslashed characters)
    if([profile length] > 1024){
        [[owner interfaceController] handleErrorMessage:@"Info Size Error"
                                        withDescription:[NSString stringWithFormat:@"Your info is too large, and could not be set.\r\rThis service limits info to 1024 characters (Your current info is %i characters)",[profile length]]];

    }else{
        NSString	*message = [NSString stringWithFormat:@"toc_set_info \"%@\"",[self validCopyOfString:profile]];

        //Send the message
        [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
    }

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

- (void)AIM_SendWarningToHandle:(NSString *)handleUID anonymous:(BOOL)anonymous;
{
    NSString	*message;

    message = [NSString stringWithFormat:@"toc_evil %@ %@",handleUID, (anonymous ? @"anon" : @"norm")];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];

}

- (IBAction)sendCommand:(id)sender
{
    NSString	*message = [textField_trafficSendDEBUG stringValue];
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];    
}

- (void)AIM_GetStatus:(NSString *)handleUID
{
    NSString	*message;

    message = [NSString stringWithFormat:@"toc_get_status %@",handleUID];

    //Send the message
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
}

- (void)AIM_SetStatus
{
    NSDate 		*idle = [[owner accountController] statusObjectForKey:@"IdleSince" account:self];
    NSAttributedString 	*profile = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"TextProfile" account:self]];
    NSAttributedString 	*away = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"AwayMessage" account:self]];
    
    if(idle){
        [self AIM_SetIdle:(-[idle timeIntervalSinceNow])];
    }

    if(profile){
        [self AIM_SetProfile:[AIHTMLDecoder encodeHTML:profile encodeFullString:YES]];
    }
    
    if(away){
        [self AIM_SetAway:[AIHTMLDecoder encodeHTML:away encodeFullString:YES]];
    }

    [self AIM_SetNick:screenName];
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


// Misc stuff --------------------------
//Backslashes invalid characters as required by AIM
- (NSString *)validCopyOfString:(NSString *)inString
{
    NSMutableString		*message;
    short			loop = 0;

    message = [[inString mutableCopy] autorelease];

    //backslash certain characters
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

// Removes all the possible status flags (that are valid on AIM/TOC) from the passed handle
- (void)removeAllStatusFlagsFromHandle:(AIHandle *)handle
{
    NSArray	*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"IdleSince",@"Signon Date",@"Away",@"Client",@"TextProfile",nil];

    [[handle statusDictionary] removeObjectsForKeys:keyArray];
    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:keyArray];
}

// Dealloc
- (void)dealloc
{
    //Stop observing
    [[owner notificationCenter] removeObserver:self name:Contact_UpdateStatus object:nil];
    
    [screenName release];
    [password release];

    [outQue release];
    [screenName release];
    [password release];
    [addDict release];
    [deleteDict release];
    [preferencesDict release];
    [socket release];
    [messageDelayTimer release];

    [super dealloc];
}

@end

