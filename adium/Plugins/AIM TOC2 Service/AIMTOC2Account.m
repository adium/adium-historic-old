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
#import "AIMTOC2Account.h"
#import "AIMTOC2Packet.h"
#import "AIMTOC2StringAdditions.h"
#import "AIMTOC2AccountViewController.h"
#import "AIMTOC2ServicePlugin.h"
//#import "AIMTOC2ChatInviteWindowController.h"

#define	AIM_ERRORS_FILE			@"AIMErrors"	//Filename of the AIM Errors plist
#define TOC2_DEFAULTS_FILE		@"TOC2Defaults" //Filename of the account property defaults
#define MESSAGE_QUE_DELAY		2.0				//Delay before sending contact list changes to the server

#define GROUP_AIM_ACCOUNT       @"AIM"			//Group for AIM prefs

#define AIM_PACKET_MAX_LENGTH	2048

#define UPDATE_INTERVAL			(1.0 / 10.0)	//Rate to check for socket updates

#define SIGN_ON_EVENT_DURATION	30.0			//Amount of time to wait for initial sign on updates

#define AUTO_RECONNECT_DELAY_PING_FAILURE	2.0	//Delay in seconds
#define AUTO_RECONNECT_DELAY_SOCKET_DROP	2.0	//Delay in seconds
#define AUTO_RECONNECT_DELAY_CONNECT_ERROR	5.0	//Delay in seconds

@interface AIMTOC2Account (PRIVATE)
- (void)update:(NSTimer *)timer;
- (void)signOnUpdate;
- (void)flushMessageDelayQue:(NSTimer *)inTimer;
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
- (void)AIM_HandleChatInvite:(NSString *)inCommand;
- (void)AIM_HandleChatUpdateBuddy:(NSString *)inCommand;
- (void)AIM_HandleEncChatIn:(NSString *)inCommand;
- (void)AIM_HandleChatJoin:(NSString *)inCommand;
- (void)AIM_HandleChatLeft:(NSString *)inCommand;
- (void)AIM_SendClientEvent:(int)inEvent toHandle:(NSString *)handleUID;
- (void)AIM_SendMessage:(NSString *)inMessage toHandle:(NSString *)handleUID;
- (void)AIM_SendMessageEnc:(NSString *)inMessage toHandle:(NSString *)handleUID autoreply:(BOOL)autoreply;
- (void)AIM_SendChatEnc:(NSString *)inMessage toChat:(NSString *)chatID;
- (void)AIM_SetIdle:(double)inSeconds;
- (void)AIM_SetProfile:(NSString *)profile;
- (void)AIM_SetNick:(NSString *)nick;
- (void)AIM_SetAway:(NSString *)away;
- (void)AIM_SetStatus;
- (void)AIM_GetProfile:(NSString *)handleUID;
- (void)AIM_GetStatus:(NSString *)handleUID;
- (void)AIM_SendWarningWithHandle:(NSString *)handleUID anonymous:(BOOL)anonymous;
- (void)AIM_LeaveChat:(NSString *)chatID;
- (NSString *)extractStringFrom:(NSString *)searchString between:(NSString *)stringA and:(NSString *)stringB;
- (NSString *)validCopyOfString:(NSString *)inString;
- (void)pingFailure:(NSTimer *)inTimer;
- (NSString *)loginStringForName:(NSString *)name password:(NSString *)pass;
- (IBAction)sendCommand:(NSString *)command;
- (NSString *)hashPassword:(NSString *)pass;
- (NSString *)clientDescriptionForID:(NSString *)clientID;
- (void)loadProfileFromURL:(NSString *)inURL;
- (void)resetPingTimer;
- (void)_AIMHandleMessageInFromUID:(NSString *)name rawMessage:(NSString *)rawMessage;
- (void)removeAllStatusFlagsFromContact:(AIListContact *)contact;
- (void)setTypingFlagOfContact:(AIListContact *)contact to:(BOOL)typing;
- (void)setAccountIdleTo:(NSTimeInterval)idle;
- (void)setAccountAwayTo:(NSAttributedString *)awayMessage;
- (void)setAccountProfileTo:(NSAttributedString *)profile;
@end

@implementation AIMTOC2Account

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{
    //Init
    outQue = [[NSMutableArray alloc] init];
    chatDict = [[NSMutableDictionary alloc] init];
    chatRoomDict = [[NSMutableDictionary alloc] init];
    silenceUpdateArray = [[NSMutableArray alloc] init];
    
    //
    pingTimer = nil;
    pingInterval = nil;
    firstPing = nil;
    password = nil;
    profileURLHandle = nil;
    
    //Delayed handle modification
    deleteDict = [[NSMutableDictionary alloc] init];
    addDict = [[NSMutableDictionary alloc] init];
    messageDelayTimer = nil;
	
    //Defaults
	//Register our default preferences and install our preference views
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:TOC2_DEFAULTS_FILE forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];
}

// AIAccount_Handles ---------------------------------------------------------------------------
- (void)removeContacts:(NSArray *)objects
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while(object = [enumerator nextObject]){
		NSString	*group = [object remoteGroupName];

		//Remove it server-side & update our remote grouping
		[object setRemoteGroupName:nil];
		[self AIM_RemoveHandle:[object UID] fromGroup:group];
	}
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)inGroup
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while(object = [enumerator nextObject]){
		//Add it server-side & update our remote grouping
		[self AIM_AddHandle:[object UID] toGroup:[inGroup UID]];
		[object setRemoteGroupName:[inGroup UID]];
	}
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	//TOC doesn't support moving contacts, so our only option is to delete and re-add them
	[self removeContacts:objects];
	[self addContacts:objects toGroup:group];
}

- (void)renameGroup:(AIListGroup *)inGroup to:(NSString *)newName
{
	//Ignore for now.  Our TOC2 renaming code has the potential of destruction and I'd rather not include it
}

// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    return([[self statusObjectForKey:@"Online"] boolValue]);
}



// Add a handle
//- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
//{
//    AIHandle	*handle;
//	
//    if(inTemporary) inGroup = @"__Strangers";    
//    if(!inGroup) inGroup = @"Unknown";
//    
//    //Check to see if the handle already exists, and remove the duplicate if it does
//    if(handle = [handleDict objectForKey:inUID]){
//        [self removeHandleWithUID:inUID]; //Remove the handle
//    }
//	
//    //Create the handle
//    handle = [AIHandle handleWithServiceID:[[[self service] handleServiceType] identifier] UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:self];
//    
//    //Add the handle
//    [self AIM_AddHandle:[handle UID] toGroup:[handle serverGroup]]; //Add it server-side
//    [handleDict setObject:handle forKey:[handle UID]]; //Add it locally
//    [self silenceUpdateFromHandle:handle]; //Silence the server's initial update command
//	
//    //Update the contact list
//    [[adium contactController] handle:handle addedToAccount:self];
//	
//    return(handle);
//}

// Remove a handle
//- (BOOL)removeHandleWithUID:(NSString *)inUID
//{
//    AIHandle	*handle = [handleDict objectForKey:inUID];
//	
//    //Remove the handle
//    [self AIM_RemoveHandle:[handle UID] fromGroup:[handle serverGroup]]; //Remove it server-side
//    [handleDict removeObjectForKey:[handle UID]]; //Remove it locally
//	
//    //Update the contact list
//    [[adium contactController] handle:handle removedFromAccount:self];
//	
//    return(YES);
//}

// Add a group to this account
//- (BOOL)addServerGroup:(NSString *)inGroup
//{
//    //
//    return(YES);
//}

// Remove a group
//- (BOOL)removeServerGroup:(NSString *)inGroup
//{
//    NSEnumerator	*enumerator;
//    AIHandle		*handle;
//	
//    //Empty the group
//    enumerator = [[handleDict allValues] objectEnumerator];
//    while((handle = [enumerator nextObject])){
//        if([[handle serverGroup] compare:inGroup] == 0){
//            [self removeHandleWithUID:[handle UID]];
//        }
//    }
//	
//    //Remove it
//	//    [self AIM_RemoveGroup:inGroup];
//	
//    return(YES);
//}

// Rename a group
//- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
//{
//    NSEnumerator	*enumerator;
//    AIHandle		*handle;
//    NSMutableArray	*groupContents;
//	
//    //There is no easy way to rename a group on TOC!!
//    //So what we do is remove all the buddies from the existing group,
//    //and then re-add them to a new group with the correct name.
//    groupContents = [[[NSMutableArray alloc] init] autorelease];
//	
//    enumerator = [[handleDict allValues] objectEnumerator];
//    while((handle = [enumerator nextObject])){
//        if([[handle serverGroup] compare:inGroup] == 0){
//            [self AIM_RemoveHandle:[handle UID] fromGroup:[handle serverGroup]]; //Remove it server-side
//            [groupContents addObject:handle];
//        }
//    }
//	
//    enumerator = [groupContents objectEnumerator];
//    while((handle = [enumerator nextObject])){
//        [handle setServerGroup:newName]; //Set the handle to the new server group
//        [self AIM_AddHandle:[handle UID] toGroup:newName]; //Add it server-side
//    }
//    
//    //Update the contact list
//    [[adium contactController] handlesChangedForAccount:self];
//	
//    return(YES);
//}

// Return YES if the contact list is editable
//- (BOOL)contactListEditable
//{
//    return([[self statusObjectForKey:@"Online"] boolValue]);
//}

// Return a dictionary of our handles
//- (NSDictionary *)availableHandles
//{
//    if([[self statusObjectForKey:@"Online"] boolValue] || [[self statusObjectForKey:@"Connecting"] boolValue]){
//        return(handleDict);
//    }else{
//        return(nil);
//    }
//}


// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(AIContentObject *)object
{
    NSString	*chatRoomID;
    NSString	*message;
    BOOL		sent = NO;
	
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
		
        //Get the message in a sendable format (HTML or plain text)
        if(!connectedWithICQ){
            message = [self validCopyOfString:[self encodedAttributedString:[(AIContentMessage *)object message]
															  forListObject:[object destination]]];
        }else{
            message = [self validCopyOfString:[[(AIContentMessage *)object message] string]];
        }
		
		//Ensure the message isn't too long
        if([message length] <= AIM_PACKET_MAX_LENGTH){
			
            if(chatRoomID = [[[object chat] statusDictionary] objectForKey:@"TOC_ChatRoomID"]){ //Chat
                [self AIM_SendChatEnc:message toChat:chatRoomID];
				
            }else{ //Message
                [self AIM_SendMessageEnc:message
								toHandle:[[[object chat] listObject] UID]
							   autoreply:[(AIContentMessage *)object autoreply]];
            }
            
            sent = YES;
			
        }else{
            [[adium interfaceController] handleErrorMessage:@"Message too big" withDescription:@"The message you're trying to send it too large.  Try breaking it into parts and sending them one at a time."];
			
        }
		
    }else if([[object type] compare:CONTENT_TYPING_TYPE] == 0){		
        if(![[[object chat] statusDictionary] objectForKey:@"TOC_ChatRoomID"]){ //Message
            AIListContact	*contact = (AIListContact *)[[object chat] listObject];
			
            //Send the typing client event
            if(contact){
                [self AIM_SendClientEvent:([(AIContentTyping *)object typing] ? 2 : 0)
								 toHandle:[contact UID]];
                sent = YES;
            }
        }
    }    
	
    return(sent);
}

//AIM doesn't require we close our tags, so don't waste the characters
//TOC2 doesn't support non-ASCII characters, so encode them
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	BOOL	noHTML = NO;
	
	//We don't want to send HTML to ICQ users, or mobile phone users
	if(inListObject){
		char	firstCharacter = [[inListObject UID] characterAtIndex:0];
		noHTML = ((firstCharacter >= '0' && firstCharacter <= '9') || firstCharacter == '+');
	}
	
    return((noHTML ? [inAttributedString string] : [AIHTMLDecoder encodeHTML:inAttributedString
																	 headers:YES
																	fontTags:YES
														  includingColorTags:YES
															   closeFontTags:NO
																   styleTags:YES
												  closeStyleTagsOnFontChange:NO
															  encodeNonASCII:YES
																  imagesPath:nil
														   attachmentsAsText:YES]));
}

//Return YES if we're available for sending the specified content.  If inListObject is nil, we can return YES if we
//will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    BOOL	weAreOnline = [[self statusObjectForKey:@"Online"] boolValue];
	
    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        if(weAreOnline && (inListObject == nil || [[inListObject statusObjectForKey:@"Online"] boolValue])){ 
			return(YES);
        }
    }
	
    return(NO);
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
	//Correctly enable/disable the chat
#warning All opened chats assumed valid until a better system for doing this reliably is figured out.
	[[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
		
	//
	[chatDict setObject:chat forKey:[[chat listObject] UID]];

	return(YES);
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
    NSEnumerator	*enumerator;
    NSString		*key;
    NSString		*chatRoomID;
    NSMutableDictionary	*containingDict;
	
    //Leave the chat room
    chatRoomID = [[inChat statusDictionary] objectForKey:@"TOC_ChatRoomID"];
    if(chatRoomID){
        [self AIM_LeaveChat:chatRoomID];
    }
	
    //Remove the chat from our tracking dict
    containingDict = (chatRoomID ? chatRoomDict : chatDict);
    enumerator = [[containingDict allKeys] objectEnumerator];
    while(key = [enumerator nextObject]){
        if([containingDict objectForKey:key] == inChat){
            [containingDict removeObjectForKey:key];
            break;
        }
    }
    
    return(YES); //Success
}


// Account Status ------------------------------------------------------------------------------------------------------
#pragma mark Account Status
// Returns an array of the status keys we support
- (NSArray *)supportedPropertyKeys
{
    return([NSArray arrayWithObjects:@"Online", @"IdleSince", @"IdleManuallySet", @"TextProfile", @"AwayMessage", nil]);
}

//Respond to account status changes
- (void)updateStatusForKey:(NSString *)key
{
    [super updateStatusForKey:key];
    
    BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];
    
    //Now look at keys which only make sense while online
    if(areOnline){
        NSData  *data;
        if([key compare:@"IdleSince"] == 0){
            NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
            [self setAccountIdleTo:(idleSince != nil ? -[idleSince timeIntervalSinceNow] : nil)];
            
        }else if([key compare:@"AwayMessage"] == 0){
			[self setAccountAwayTo:[self autoRefreshingOutgoingContentForStatusKey:key]];
			
        }else if([key compare:@"TextProfile"] == 0){
			[self setAccountProfileTo:[self autoRefreshingOutgoingContentForStatusKey:key]];

		}
    }
}

//Set our idle (Pass nil for no idle)
- (void)setAccountIdleTo:(NSTimeInterval)idle
{
    NSDate      *oldIdle = [self statusObjectForKey:@"IdleSince"];
    
    if(oldIdle != nil && idle != nil){
        //Most AIM clients will ignore 2 consecutive idles,
        //so we unidle, then re-idle to the new value
        [self AIM_SetIdle:0];
    }
    
    [self AIM_SetIdle:idle];
    //We are now idle
    [self setStatusObject:(idle ? [NSDate dateWithTimeIntervalSinceNow:-idle] : nil)
                   forKey:@"IdleSince" notify:YES];
}

- (void)setAccountAwayTo:(NSAttributedString *)awayMessage
{
    if (awayMessage){
        [self AIM_SetAway:[self encodedAttributedString:awayMessage forListObject:nil]];
        [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Away" notify:NO];
        [self setStatusObject:awayMessage forKey:@"StatusMessage" notify:NO];
        
    }else{
        [self AIM_SetAway:nil];
        [self setStatusObject:nil forKey:@"Away" notify:NO];
        [self setStatusObject:nil forKey:@"StatusMessage" notify:NO];
    }
	
	[self notifyOfChangedStatusSilently:NO];
}

- (void)setAccountProfileTo:(NSAttributedString *)profile
{
    if([profile length] > 1024){
        [[adium interfaceController] handleErrorMessage:@"Info Size Error"
                                        withDescription:[NSString stringWithFormat:@"Your info is too large, and could not be set.\r\rThis service limits info to 1024 characters (Your current info is %i characters)",[profile length]]];
        // in theory this would be where to activate that field, and below to disable it
    }else{
        [self AIM_SetProfile:[self encodedAttributedString:profile forListObject:nil]];
        [self setStatusObject:profile forKey:@"TextProfile" notify:YES];
    }
}

//Update the status of a contact
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{	
    //AIM requires a delayed load of profiles...
    if([[inContact statusObjectForKey:@"Online"] boolValue]){
		[self AIM_GetProfile:[inContact UID]];
    }
}
- (float)delayedUpdateStatusInterval{
	return(5.0);
}

// Connecting and Disconnecting ---------------------------------------------------------------------------
// Connect
- (void)connect{
	NSString	*host = [self preferenceForKey:AIM_TOC2_KEY_HOST group:GROUP_ACCOUNT_STATUS];
	int			port = [[self preferenceForKey:AIM_TOC2_KEY_PORT group:GROUP_ACCOUNT_STATUS] intValue];
	
	//Set our status as connecting
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:YES];
	
	//Determine if this is an ICQ account
	connectedWithICQ = ([[[self UID] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]] length] == 0);
	
	//Init our socket and start connecting
	socket = [[AISocket socketWithHost:host port:port] retain];
	connectionPhase = 1;
	updateTimer = [[NSTimer scheduledTimerWithTimeInterval:(UPDATE_INTERVAL) //(1.0 / x) x times per second
													target:self
												  selector:@selector(update:)
												  userInfo:nil
												   repeats:YES] retain];
}

//Disconnects or cancels
- (void)disconnect
{
    NSEnumerator	*enumerator;
    AIListContact   *contact;
	
    //Set our status as disconnecting
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
	
    //Flush all our handle status flags
	[[adium contactController] delayListObjectNotificationsUntilInactivity];
#warning Adam: This is dreadfully inefficient.  Is there a faster solution to disconnecting?
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while((contact = [enumerator nextObject])){
		[self removeAllStatusFlagsFromContact:contact];
		[contact setRemoteGroupName:nil];
    }
	
    //Clean up and close down
    [silenceUpdateArray release]; silenceUpdateArray = nil;
    [socket release]; socket = nil;
    [pingTimer invalidate];
    [pingTimer release]; pingTimer = nil;
    [updateTimer invalidate];
    [updateTimer release]; updateTimer = nil;
	
    //Set our status as offline
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:NO]; //Needed if we were connecting when the error happened
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:NO];
	
	[self notifyOfChangedStatusSilently:NO];
}


// Packet/Protocol Processing -------------------------------------------------------------------------
// Check for sign on packets and update status
- (void)signOnUpdate
{
    AIMTOC2Packet	*packet;
	
    switch(connectionPhase){
        case 1: //Send the "flap on" packet
            if([socket sendData:[@"FLAPON\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]]){
                connectionPhase++;
            }
			break;
        case 2: //Receive the server version
            if((packet = [AIMTOC2Packet packetFromSocket:socket sequence:0])){
                if([packet dataByte:0] != 0 || [packet dataByte:1] != 0 || [packet dataByte:2] != 0 || [packet dataByte:3] != 1){
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
				//Send the first sign on packet
            if([[AIMTOC2Packet signOnPacketForScreenName:[[self UID] compactedString] sequence:&localSequence] sendToSocket:socket]){
				
                //Send the login string
                [self sendCommand:[self loginStringForName:[[self UID] compactedString] password:password]];
				
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
        while((packet = [AIMTOC2Packet packetFromSocket:socket sequence:&remoteSequence])){
            if([packet frameType] == FRAMETYPE_DATA){
                NSString		*message = [packet string];
                NSString		*command = [message TOCStringArgumentAtIndex:0];
				
                if([command compare:@"SIGN_ON"] == 0){
                    [self AIM_HandleSignOn:message];
					
                }else if([command compare:@"ERROR"] == 0){
                    [self AIM_HandleError:message];
					
                }else if([command compare:@"NICK"] == 0){
                    [self AIM_HandleNick:message];
					
                }else if([command compare:@"CONFIG2"] == 0){
                    [self AIM_HandleConfig:message];
					
                    [self silenceAllHandleUpdatesForInterval:SIGN_ON_EVENT_DURATION];
					
                    //Flag ourself as online
					[self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:NO];
					[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
					[self notifyOfChangedStatusSilently:NO];
						
                    //Set our correct status
					[self updateStatusForKey:@"IdleSince"];
					[self updateStatusForKey:@"TextProfile"];
					[self updateStatusForKey:@"AwayMessage"];
					
					//Format our nickname as it was entered for the account
					if(!connectedWithICQ){
						NSString *nick = [self preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
						if(nick && [nick length]) [self AIM_SetNick:nick];
					}
                    
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
                    [self AIM_HandleChatJoin:message];
                    
                }else if([command compare:@"CHAT_LEFT"] == 0){
                    [self AIM_HandleChatLeft:message];
                    
                }else if([command compare:@"CHAT_IN"] == 0){
                    
                }else if([command compare:@"CHAT_IN_ENC"] == 0){
                    [self AIM_HandleEncChatIn:message];
					
                }else if([command compare:@"CHAT_INVITE"] == 0){
                    [self AIM_HandleChatInvite:message];
					
                }else if([command compare:@"CHAT_UPDATE_BUDDY"] == 0){
                    [self AIM_HandleChatUpdateBuddy:message];
                    
                }else if([command compare:@"ADMIN_NICK_STATUS"] == 0){
                }else if([command compare:@"ADMIN_PASSWD_STATUS"] == 0){
                }else if([command compare:@"RVOUS_PROPOSE"] == 0){
                }
				
            }else if([packet frameType] == FRAMETYPE_KEEPALIVE){
                [self AIM_HandlePing];
            }
        }
		
    }else{ //Send & Receive the sign on commands
        [self signOnUpdate];
    }
	
    //Send any packets in the outQue
    BOOL packetProcessed = YES;
    while([outQue count] && packetProcessed){ //When a packet fails to send, we stop trying until the next update timer fires.
        packet = [outQue objectAtIndex:0];
		
        if([packet length] <= 2048){
            packetProcessed = [[outQue objectAtIndex:0] sendToSocket:socket];
        }else{
            NSLog(@"Attempted to send invalid packet (Too large, %i)",[packet length]);
            packetProcessed = YES; //Processed as in deleted :D
        }
		
        if(packetProcessed){ //If a packet fails to send, we don't log or remove it
            [outQue removeObjectAtIndex:0];
        }
    }
}

//Send a command to the server
- (IBAction)sendCommand:(NSString *)command
{
    //Create a data packet for the command and add it to our outgoing que
    [outQue addObject:[AIMTOC2Packet dataPacketWithString:command sequence:&localSequence]];
}


//Login ---------------------------------------------------------------------------------------------------
//Returns the login string
- (NSString *)loginStringForName:(NSString *)name password:(NSString *)pass
{
    unsigned long 	a,b,d,o;
	
    //Generate the correct login number
    a = ([name cString][0] - 96) * 7696 + 738816; 	//first SN letter
    b = ([name cString][0] - 96) * 746512; 		//first SN letter
    d = ([password cString][0] - 96) * a; 					//pass first letter
    o = d - a + b + 71665152;
	
    //return our login string
    return([NSString stringWithFormat:@"toc2_login login.oscar.aol.com 29999 %@ %@ English \"TIC:\\$Revision: 1.133 $\" 160 US \"\" \"\" 3 0 30303 -kentucky -utf8 %lu", name, [self hashPassword:password],o]);
}

//Hashes a password for sending to AIM (to avoid sending them in plain-text)
#define HASH "Tic/Toc"
- (NSString *)hashPassword:(NSString *)pass
{
    const char 		hash[(sizeof(HASH))] = HASH;
    const char 		*cPass = [pass cString];
    int 			length = [pass length];
    int 			counter;
    NSMutableString	*output;
	
    //Create the hash string
    output = [NSMutableString stringWithString:@"0x"];
    for(counter = 0; counter < length; counter++){
        [output appendString:[NSString stringWithFormat:@"%02x",cPass[counter] ^ hash[((counter) % (sizeof(HASH)-1))]]];
    }
	
    return(output);
}



//Client -> Server Commands --------------------------------------------------------------------------------
- (void)AIM_SendChatEnc:(NSString *)inMessage toChat:(NSString *)chatID{
    [self sendCommand:[NSString stringWithFormat:@"toc_chat_send_enc %@ U \"%@\"", chatID, inMessage]];
}

- (void)AIM_LeaveChat:(NSString *)chatID{
    [self sendCommand:[NSString stringWithFormat:@"toc_chat_leave %@", chatID]];
}

- (void)AIM_SendClientEvent:(int)inEvent toHandle:(NSString *)handleUID{
    [self sendCommand:[NSString stringWithFormat:@"toc2_client_event %@ %i",handleUID,inEvent]];
}

- (void)AIM_SendMessage:(NSString *)inMessage toHandle:(NSString *)handleUID{
    [self sendCommand:[NSString stringWithFormat:@"toc2_send_im %@ \"%@\"",handleUID,inMessage]];
}

- (void)AIM_SendMessageEnc:(NSString *)inMessage toHandle:(NSString *)handleUID autoreply:(BOOL)autoreply{
    [self sendCommand:[NSString stringWithFormat:@"toc2_send_im_enc %@ F U en \"%@\" %@",handleUID,inMessage,(autoreply ? @"auto" : @"")]];
}

- (void)AIM_SetNick:(NSString *)nick{
    [self sendCommand:[NSString stringWithFormat:@"toc_format_nickname \"%@\"",nick]];
}

- (void)AIM_SetIdle:(double)inSeconds{
    [self sendCommand:[NSString stringWithFormat:@"toc_set_idle %0.0f",(double)inSeconds]];
}

- (void)AIM_SetProfile:(NSString *)profile{
    [self sendCommand:[NSString stringWithFormat:@"toc_set_info \"%@\"",[self validCopyOfString:profile]]];
}

- (void)AIM_SetAway:(NSString *)away{
    if(away){
        [self sendCommand:[NSString stringWithFormat:@"toc_set_away \"%@\"",[self validCopyOfString:away]]];
    }else{
        [self sendCommand:@"toc_set_away"];
    }
}

- (void)AIM_GetProfile:(NSString *)handleUID{
    [self sendCommand:[NSString stringWithFormat:@"toc_get_info %@",handleUID]];
}

- (void)AIM_WarnHandle:(NSString *)handleUID anonymous:(BOOL)anonymous{
    [self sendCommand:[NSString stringWithFormat:@"toc_evil %@ %@",handleUID, (anonymous ? @"anon" : @"norm")]];
}

- (void)AIM_GetStatus:(NSString *)handleUID{
    [self sendCommand:[NSString stringWithFormat:@"toc_get_status %@",handleUID]];
}

- (void)AIM_RemoveGroup:(NSString *)groupName{
    [self sendCommand:[NSString stringWithFormat:@"toc2_del_group \"%@\"",groupName]]; //(Group must be empty)
}


//Server -> Client Command Handlers ------------------------------------------------------
- (void)AIM_HandleChatInvite:(NSString *)inCommand
{
//    NSString		*chatName = [inCommand TOCStringArgumentAtIndex:1];
//    NSString		*chatID = [inCommand TOCStringArgumentAtIndex:2];
//    NSString		*handleName = [inCommand TOCStringArgumentAtIndex:3];
//    //NSString		*inviteMessage = [inCommand nonBreakingTOCStringArgumentAtIndex:4];
//    AIHandle		*handle;
//	
//    //Get the inviting handle (creating a stranger if necessary)
//    handle = [handleDict objectForKey:[handleName compactedString]];
//    if(!handle){
//        handle = [self addHandleWithUID:[handleName compactedString] serverGroup:nil temporary:YES];
//    }
//	
//    //Display the chat invite
//    [[AIMTOC2ChatInviteWindowController chatInviteFrom:handle forChatID:chatID name:chatName account:self] showWindow:nil];
}

- (void)acceptInvitationForChatID:(NSString *)chatID
{
//    NSString	*message = [NSString stringWithFormat:@"toc_chat_accept %@",chatID];
//    [outQue addObject:[AIMTOC2Packet dataPacketWithString:message sequence:&localSequence]];
}

- (void)declineInvitationForChatID:(NSString *)chatID
{
    //I don't know of a chat decline command.  We just ignore the invitation at the moment.
}

- (void)AIM_HandleChatJoin:(NSString *)inCommand
{
//    NSString		*chatID = [inCommand TOCStringArgumentAtIndex:1];
//    NSString		*chatName = [inCommand TOCStringArgumentAtIndex:2];
//    AIChat		*chat;
//	
//    //Create an AIChat for this chat room
//    chat = [AIChat chatForAccount:self];
//    [[chat statusDictionary] setObject:chatID forKey:@"TOC_ChatRoomID"];
//	
//    //Chat set participants and status
//    [[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"AlwaysShowUserList"];
//    [[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"DisallowAccountSwitching"];
//    [[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
//    [[chat statusDictionary] setObject:chatName forKey:@"DisplayName"];
//    
//    
//    //
//    [chatRoomDict setObject:chat forKey:chatID];
//    [[adium contentController] noteChat:chat forAccount:self];
//    [[adium interfaceController] setActiveChat:chat];
}

//
- (void)AIM_HandleChatLeft:(NSString *)inCommand
{
//	
}

//
- (void)AIM_HandleChatUpdateBuddy:(NSString *)inCommand
{
//    NSString		*chatID = [inCommand TOCStringArgumentAtIndex:1];
//    BOOL		entering = ([[inCommand TOCStringArgumentAtIndex:2] characterAtIndex:0] == 'T');
//    NSArray		*userArray = [[inCommand nonBreakingTOCStringArgumentAtIndex:3] componentsSeparatedByString:@":"];
//    NSEnumerator	*enumerator;
//    NSString		*userName;
//    AIChat		*chat;
//	
//    //Get the chat
//    chat = [chatRoomDict objectForKey:chatID];
//    
//    //Add/remove users    
//    enumerator = [userArray objectEnumerator];
//    while((userName = [enumerator nextObject])){
//        AIHandle	*handle;
//        
//        //Get the handle for this user
//        handle = [handleDict objectForKey:[userName compactedString]];
//        if(!handle){
//            handle = [self addHandleWithUID:[userName compactedString] serverGroup:nil temporary:YES];
//        }
//		
//        //Add/remove list object
//        if(entering){
//            [chat addParticipatingListObject:[handle containingContact]];
//        }else{
//            [chat removeParticipatingListObject:[handle containingContact]];
//        }
//    }
//	
//    //Notify
//    [[adium notificationCenter] postNotificationName:Content_ChatParticipatingListObjectsChanged object:chat userInfo:nil];
}

- (void)AIM_HandleEncChatIn:(NSString *)inCommand
{
//    NSString		*chatID = [inCommand TOCStringArgumentAtIndex:1];
//    NSString		*senderName = [inCommand TOCStringArgumentAtIndex:2];
//    NSString		*rawMessage = [inCommand nonBreakingTOCStringArgumentAtIndex:6];
//    NSAttributedString	*messageText;
//    AIContentMessage	*messageObject;
//    AIHandle		*senderHandle;
//    AIChat 		*chat;
//    
//    if([[self UID] compare:[senderName compactedString]] != 0){ //Ignore echoed messages
//																//Get the sending handle (creating a stranger if necessary)
//        senderHandle = [handleDict objectForKey:[senderName compactedString]];
//        if(!senderHandle){
//            senderHandle = [self addHandleWithUID:[senderName compactedString] serverGroup:nil temporary:YES];
//        }
//		
//        //Get the chat
//        if(chat = [chatRoomDict objectForKey:chatID]){
//            //Create a content object for the message
//            messageText = [AIHTMLDecoder decodeHTML:rawMessage];
//            messageObject = [AIContentMessage messageInChat:chat
//												 withSource:[senderHandle containingContact]
//                                                destination:self
//													   date:nil
//                                                    message:messageText
//                                                  autoreply:NO];
//			
//            //Add the content object
//            [[adium contentController] addIncomingContentObject:messageObject];
//        }
//    }
}

- (void)AIM_HandleClientEvent:(NSString *)inCommand
{
    int				event = [[inCommand TOCStringArgumentAtIndex:2] intValue];
    NSString		*name = [inCommand TOCStringArgumentAtIndex:1];
    AIListContact	*contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
																   accountID:[self uniqueObjectID]
																		 UID:[name compactedString]];
    
    //Post the correct typing state
    if(contact){
        if(event == 0){ //Not typing
            [self setTypingFlagOfContact:contact to:NO];
        }else if(event == 2){ //Typing
            [self setTypingFlagOfContact:contact to:YES];
        }
    }
}

- (void)AIM_HandleEncMessageIn:(NSString *)inCommand
{
    [self _AIMHandleMessageInFromUID:[inCommand TOCStringArgumentAtIndex:1]
                          rawMessage:[inCommand nonBreakingTOCStringArgumentAtIndex:9]];
}

- (void)AIM_HandleMessageIn:(NSString *)inCommand
{
    [self _AIMHandleMessageInFromUID:[inCommand TOCStringArgumentAtIndex:1]
                          rawMessage:[inCommand nonBreakingTOCStringArgumentAtIndex:4]];
}

- (void)_AIMHandleMessageInFromUID:(NSString *)name rawMessage:(NSString *)rawMessage
{
    AIContentMessage	*messageObject;
    AIChat				*chat;
    AIListContact		*contact;
	
	//
	contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
												  accountID:[self uniqueObjectID]
														UID:[name compactedString]];
	
    //Clear the 'typing' flag
    [self setTypingFlagOfContact:contact to:NO];
    
    //Open a chat for this handle
    chat = [[adium contentController] chatWithContact:contact initialStatus:nil];

    //Add a content object for the message
    messageObject = [AIContentMessage messageInChat:chat
                                         withSource:contact
                                        destination:self
                                               date:nil
                                            message:[AIHTMLDecoder decodeHTML:rawMessage]
                                          autoreply:NO];
    [[adium contentController] receiveContentObjectmessageObject];
}

//
- (void)_setInstantMessagesWithContact:(AIListContact *)contact enabled:(BOOL)enable
{
    NSEnumerator	*enumerator;
    AIChat		*chat;
	
    //Search for any chats with this contact
    enumerator = [[chatDict allValues] objectEnumerator];
    while(chat = [enumerator nextObject]){
        if([chat listObject] == contact){
            //Enable/disable the chat
            [[chat statusDictionary] setObject:[NSNumber numberWithBool:enable] forKey:@"Enabled"];
			
            //Notify
            [[adium notificationCenter] postNotificationName:Content_ChatStatusChanged object:chat userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Enabled"] forKey:@"Keys"]];
			
            //Exit early
            break;
        }
    }
}

- (void)AIM_HandleUpdateBuddy:(NSString *)message
{
    NSString		*name = [message TOCStringArgumentAtIndex:1];
    NSString		*compactedName = [name compactedString];
    AIListContact	*contact = nil;
	
    //Get the contact
    if(contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
													 accountID:[self uniqueObjectID]
														   UID:compactedName]){
        NSNumber		*storedValue;
        NSDate			*storedDate;
        NSString		*storedString;
		
        //Get the handle's status from the update event
        BOOL		online = ([[message TOCStringArgumentAtIndex:2] characterAtIndex:0] == 'T');
        int			warning = [[message TOCStringArgumentAtIndex:3] intValue];
        double		idleTime = ([[message TOCStringArgumentAtIndex:5] doubleValue] * 60.0);
        NSDate		*signOnDate = [NSDate dateWithTimeIntervalSince1970:[[message TOCStringArgumentAtIndex:4] doubleValue]];
        NSString	*userFlags = [message TOCStringArgumentAtIndex:6];
        NSString	*client = [self clientDescriptionForID:[userFlags substringToIndex:2]];
        BOOL		away = (([userFlags length] < 3) ? NO : ([userFlags characterAtIndex:2] == 'U'));
		
        //Online/Offline
		storedValue = [contact statusObjectForKey:@"Online"];
        if(storedValue == nil || online != [storedValue intValue]){
            [contact setStatusObject:[NSNumber numberWithInt:online] forKey:@"Online" notify:NO];
			
			if(!silentAndDelayed){
				if(online){
					[contact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Signed On" notify:NO];
					[contact setStatusObject:nil forKey:@"Signed Off" notify:NO];
					[contact setStatusObject:nil forKey:@"Signed On" afterDelay:15];
				}else{
					[contact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Signed Off" notify:NO];
					[contact setStatusObject:nil forKey:@"Signed On" notify:NO];
					[contact setStatusObject:nil forKey:@"Signed Off" afterDelay:15];
				}
			}
			
            //Enable/disable any instant messages with this contact
            [self _setInstantMessagesWithContact:contact enabled:online];
        }
		
        //Warning
        storedValue = [contact statusObjectForKey:@"Warning"];
        if(storedValue == nil || warning != [storedValue intValue]){
            [contact setStatusObject:[NSNumber numberWithInt:warning] forKey:@"Warning" notify:NO];
			//			
			//			if([storedValue intValue] == 0){
			//				[handleStatusDict setObject:[NSNumber numberWithInt:warning] forKey:@"Cooldown"];
			//				[alteredStatusKeys addObject:@"Cooldown"];
			//			}else{
			//				[handleStatusDict setObject:[NSNumber numberWithInt:[storedValue intValue]] forKey:@"Cooldown"];
			//				[alteredStatusKeys addObject:@"Cooldown"];
			//			}
        }
		
        //Idle time (seconds)
        storedDate = [contact statusObjectForKey:@"IdleSince"];
        if(storedDate == nil || (idleTime != -[storedDate timeIntervalSinceNow])){
            if(idleTime == 0 && storedDate){
				[contact setStatusObject:nil forKey:@"IdleSince" notify:NO];
            }else if(idleTime > 0){
				[contact setStatusObject:[NSDate dateWithTimeIntervalSinceNow:-idleTime] forKey:@"IdleSince" notify:NO];
            }
        }
		
        //Sign on date
        storedDate = [contact statusObjectForKey:@"Signon Date"];
        if(storedDate == nil || ![signOnDate isEqualToDate:storedDate]){
			[contact setStatusObject:signOnDate forKey:@"Signon Date" notify:NO];
        }
		
        //Away
        storedValue = [contact statusObjectForKey:@"Away"];
        if(storedValue == nil || away != [storedValue intValue]){
			[contact setStatusObject:[NSNumber numberWithBool:away] forKey:@"Away" notify:NO];
        }
		
        //Client
        storedString = [contact statusObjectForKey:@"Client"];
        if(storedString == nil || [client compare:storedString] != 0){
			[contact setStatusObject:client forKey:@"Client" notify:NO];
        }
        
        //Formatted UID
        storedString = [contact statusObjectForKey:@"FormattedUID"];
        if(storedString == nil || [name compare:storedString] != 0){
			[contact setStatusObject:name forKey:@"FormattedUID" notify:NO];
        }
		
        //Let the contact list know a contact's status changed
		[contact notifyOfChangedStatusSilently:silentAndDelayed];
    }
}

- (void)AIM_HandleNick:(NSString *)message
{
    //Do nothing
}

- (void)AIM_HandleSignOn:(NSString *)message
{
    if([[message TOCStringArgumentAtIndex:1] compare:@"TOC2.0"] != 0){ //Check the protocol version
        NSLog(@"Server is reporting '%@', expected 'TOC2.0'",[message TOCStringArgumentAtIndex:1]);
    }
}

- (void)AIM_HandleError:(NSString *)message
{
    NSString		*path;
    NSDictionary	*errorDict;
    NSString		*errorMessage;
    BOOL			disconnect = NO;
    int				errorNumber = [[message TOCStringArgumentAtIndex:1] intValue];
    BOOL			displayError = YES;
    
    //Special case error situations
//    if(errorNumber == 931){
//        NSString	*contactName = [message TOCStringArgumentAtIndex:2];
//        int		subError = [[message TOCStringArgumentAtIndex:3] intValue];
//		
//        if(subError == 17){ //Contact list is full, could not add handle.
//            NSString	*handleKey = [contactName compactedString];
//            AIHandle	*handle = [[handleDict objectForKey:handleKey] retain];
//			
//            //If the handle is not temporary we remove it from our local handle dict
//            if(![handle temporary]){
//                [handleDict removeObjectForKey:handleKey];
//                [[adium contactController] handle:handle removedFromAccount:self];
//            }
//			
//            //If the handle was temporary
//            if([handle temporary]){
//                AIChat	*chat;
//                NSLog(@"Contact list is full, unable to track stranger: %@",contactName);
//				
//                //Display the contact list is full status note
//                if(chat = [chatDict objectForKey:handleKey]){
//                    AIContentStatus	*content;
//                    
//                    //Create our content object
//                    content = [AIContentStatus statusInChat:chat
//                                                 withSource:[handle containingContact]
//                                                destination:self
//                                                       date:[NSDate date]
//                                                    message:[NSString stringWithFormat:@"Your contact list is full.\rAdium is unable to track the status of '%@'.", contactName]];
//                    [[adium contentController] addIncomingContentObject:content];
//                }                    
//                
//                //Ask the server for an update to this handle's status, since we're unable to track it on our contact list.
//                [self AIM_GetStatus:[handle UID]];
//                
//                //Handle this error silently.
//                displayError = NO;
//            }
//			
//            [handle release];
//        }
//    }
	
    if(displayError){
        //Get the error message data
        //Error messages (and if we should disconnect) come from keys within the AIMErrors.plist file
        path = [[NSBundle bundleForClass:[self class]] pathForResource:AIM_ERRORS_FILE ofType:@"plist"];
        errorDict = [NSDictionary dictionaryWithContentsOfFile:path];
		
        //Get the corrent message and disconnect flag
        errorMessage = [[errorDict objectForKey:@"ErrorString"] objectForKey:[message TOCStringArgumentAtIndex:1]];
        if(!errorMessage) errorMessage = @"Unknown Error";
        disconnect = [[[errorDict objectForKey:@"ErrorDisc"] objectForKey:[message TOCStringArgumentAtIndex:1]] boolValue];
		
        //Display the error
        [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"AIM Error %i (%@)", errorNumber, [self displayName]] withDescription:errorMessage];
		
        //Disconnecting Errors
        if(disconnect){
            [self disconnect];
        }
    }
}

- (void)AIM_HandleConfig:(NSString *)message
{
    NSScanner		*scanner;
    NSCharacterSet	*endlines = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
    NSString		*configString = [message nonBreakingTOCStringArgumentAtIndex:1];
    NSString		*type;
    NSString		*value = nil;
    NSString		*currentGroup = @"New Group";
    
	//
	[[adium contactController] delayListObjectNotificationsUntilInactivity];
	
    //Create a scanner
    scanner = [NSScanner scannerWithString:configString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    
    while(![scanner isAtEnd]){
		
        //Scan the type (the text before the : )
        [scanner scanUpToString:@":" intoString:&type];
        if([scanner scanString:@":" intoString:nil]){
			
            //scan the value (the text after the : )
            value = nil;
            [scanner scanUpToCharactersFromSet:endlines intoString:&value];
            if([scanner scanCharactersFromSet:endlines intoString:nil] && value != nil){
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
					currentGroup = value;
					
                }else if([type compare:@"b"] == 0){ //BUDDY
					AIListContact	*contact;
					//
					contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
																  accountID:[self uniqueObjectID]
																		UID:[value compactedString]];
					[contact setRemoteGroupName:currentGroup];
					
                }else if([type compare:@"p"] == 0){
                }else if([type compare:@"d"] == 0){
                }else if([type compare:@"m"] == 0){
                }else if([type compare:@"pref"] == 0){
                    if([value compare:@"0"] == 0){
                        NSLog(@"Idle is disabled server-side for %@",[self displayName]);
                    }
					
                }else if([type compare:@"20"] == 0){
                }else if([type compare:@"done"] == 0){
                }else{
                    //NSLog(@"Unknown Config Type '%@', value '%@'.",type,value);
                }
            }
        }
    }
}

- (void)AIM_HandleGotoURL:(NSString *)message
{
    NSString	*host, *port, *path, *urlString;
	
    //Set up the address
    host = [socket hostIP]; //We must request our profile from the same server that we connected to.
    port = [self preferenceForKey:AIM_TOC2_KEY_PORT group:GROUP_ACCOUNT_STATUS];
    path = [message nonBreakingTOCStringArgumentAtIndex:2];
    urlString = [NSString stringWithFormat:@"http://%@:%@/%@", host, port, path];
	
    //Load the profile
    [self loadProfileFromURL:urlString];
}

- (void)AIM_HandlePing
{
    if(pingInterval){
        //Reset the ping timer
        [self resetPingTimer];
		
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
            [self resetPingTimer];
        }
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


// Profile Loading --------------------------------------------------------------------------------------------
- (void)loadProfileFromURL:(NSString *)inURLString
{
    NSURL	*url;
    
    //Cancle any existing profile load
    if(profileURLHandle){
        [profileURLHandle cancelLoadInBackground];
    }
	
    //Fetch the site
    //Just to note: this caused a crash when the user had a proxy in previous versions of Adium
    url = [NSURL URLWithString:inURLString];
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
		AIListContact	*contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
																	   accountID:[self uniqueObjectID]
																			 UID:[userName compactedString]];
        //Add profile to the handle
        [contact setStatusObject:[AIHTMLDecoder decodeHTML:profile] forKey:@"TextProfile" notify:YES];
    }
	
    //Cleanup
    [profileURLHandle release]; profileURLHandle = nil;
}

- (void)URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes
{
}

- (void)URLHandleResourceDidBeginLoading:(NSURLHandle *)sender
{
}

- (void)URLHandleResourceDidCancelLoading:(NSURLHandle *)sender
{
    if(profileURLHandle){
        [profileURLHandle release]; profileURLHandle = nil;
    }
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
#warning Adam: This code is assuming we are on our own contact list?  We cannot make this assumption.
//    NSString	*level = [message TOCStringArgumentAtIndex:1];
//    NSString	*enemy = [message TOCStringArgumentAtIndex:2];
//	
//    int		cooldown = [[[[handleDict objectForKey:[self UID]] statusDictionary] objectForKey:@"Cooldown"] intValue];
//    
//    if(enemy !=nil){
//		[[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ : Warning Level (%@)",[self UID],enemy] withDescription:[NSString stringWithFormat:@"Your warning level is now: %@\%",level]];
//		
//    }else if(cooldown < [level intValue]){
//		[[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ : Warning Level (Anonymous)", [self UID]] withDescription:[NSString stringWithFormat:@"Your warning level is now: %@\%",level]];
//		
//    }else if([level intValue] == 0){
//		[[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:@"%@ : Warning Level Cleared",[self UID]] withDescription:[NSString stringWithFormat:@"Your warning level is now normal"]];
//    }
}


//Server Activity Pings ---------------------------------------------------------------------------------------
//Reset the ping timer
- (void)resetPingTimer
{
    if(pingTimer){
        [pingTimer invalidate];
        [pingTimer release]; pingTimer = nil;
    }
    pingTimer = [[NSTimer scheduledTimerWithTimeInterval:pingInterval target:self selector:@selector(pingFailure:) userInfo:nil repeats:NO] retain];
}

//Called if the server ping fails to arrive
- (void)pingFailure:(NSTimer *)inTimer
{
    NSLog(@"Server's ping not recieved, disconnecting.");
	
    [self disconnect];
    [self autoReconnectAfterDelay:AUTO_RECONNECT_DELAY_PING_FAILURE];
}


// Misc stuff ------------------------------------------------------------------------------------------------
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

// Removes all the possible status flags (that are valid on AIM/TOC) from the passed contact
- (void)removeAllStatusFlagsFromContact:(AIListContact *)contact
{
    NSArray			*keyArray = [NSArray arrayWithObjects:@"Online",@"Warning",@"IdleSince",@"Signon Date",@"Away",@"Client",@"TextProfile",nil];
	NSEnumerator	*enumerator = [keyArray objectEnumerator];
	NSString		*key;
	
	while(key = [enumerator nextObject]){
		[contact setStatusObject:nil forKey:key notify:NO];
	}
	[contact notifyOfChangedStatusSilently:YES];
}

// Dealloc
- (void)dealloc
{
    [outQue release];
    [password release];
    [addDict release];
    [deleteDict release];
    [socket release];
    [messageDelayTimer release];
    [chatDict release];
    [chatRoomDict release];
	
    [super dealloc];
}

- (void)setTypingFlagOfContact:(AIListContact *)contact to:(BOOL)typing
{
    BOOL currentValue = [[contact statusObjectForKey:@"Typing"] boolValue];
	
    if(typing != currentValue){
		[contact setStatusObject:[NSNumber numberWithBool:typing] forKey:@"Typing" notify:YES];
    }
}

- (NSString *)clientDescriptionForID:(NSString *)clientID
{
    char	clientA = [clientID characterAtIndex:0];
    char	clientB = [clientID characterAtIndex:1];
    NSString	*client;
    
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
	
    return(client);
}

@end

