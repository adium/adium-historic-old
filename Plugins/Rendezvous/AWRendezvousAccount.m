/*
 * Project:     Adium Rendezvous Plugin
 * File:        AWRendezvousAccount.m
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004 Andrew Wellington.
 * All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AWRendezvousAccount.h"
#import "AWRendezvousPlugin.h"

#import "AWEzv.h"
#import "AWEzvContact.h"
#import "AWEzvDefines.h"

@implementation AWRendezvousAccount
//
- (void)initAccount
{
    [super initAccount];
	
    libezvContacts = [[NSMutableDictionary alloc] init];
    
    libezv = [[AWEzv alloc] initWithClient:self];
}

- (void)dealloc
{
	[libezvContacts release];
	[libezv release];
}

- (BOOL)disconnectOnFastUserSwitch
{
	return(YES);
}

//No need for a password for Rendezvous accounts
- (BOOL)requiresPassword
{
	return(NO);
}

- (void)connect
{
    // Say we're connecting...
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:YES];

    [libezv setName:[self displayName]];
    [libezv login];
}

- (void)disconnect
{
    // Say we're disconnecting...
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
    
    [libezv logout];
}

- (void)removeContacts:(NSArray *)objects
{

}

#pragma mark Libezv Callbacks
// Libezv Callbacks
- (void) reportLoggedIn {
    //We are now online
    [self setStatusObject:nil forKey:@"Disconnecting" notify:NO];
    [self setStatusObject:nil forKey:@"Connecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];

    //Apply any changes
    [self notifyOfChangedStatusSilently:NO];
    
    [self updateAllStatusKeys];
}

- (void) reportLoggedOut 
{
    NSEnumerator	*enumerator = [libezvContacts objectEnumerator];
    NSString		*uniqueID;
    AIListContact	*listContact;

    while (uniqueID = [enumerator nextObject]) {
		listContact = [[adium contactController] existingContactWithService:service
															 account:self
																 UID:uniqueID];
		[listContact setRemoteGroupName:nil];
    }
    [libezvContacts removeAllObjects];
    
	//We are now offline
    [self setStatusObject:nil forKey:@"Disconnecting" notify:NO];
    [self setStatusObject:nil forKey:@"Connecting" notify:NO];
    [self setStatusObject:nil forKey:@"Online" notify:NO];
	
	//Apply any changes
    [self notifyOfChangedStatusSilently:NO];
}

- (void) userChangedState:(AWEzvContact *)contact
{
    AIListContact	*listContact;
	NSString		*contactName, *statusMessage;
	NSDate			*idleSinceDate;
	NSImage			*contactImage;
	
    listContact = [[adium contactController] contactWithService:service
												 account:self
													 UID:[contact uniqueID]];  

	if (![listContact remoteGroupName]){
		[listContact setRemoteGroupName:AILocalizedString(@"Rendezvous", @"Rendezvous group name")];
	}

	//We only get state change updates on Online contacts
	if (![listContact online]){
		[listContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
	}
	
	switch ([contact status]) {
		case AWEzvAway:
			if (![listContact integerStatusObjectForKey:@"Away"]){
				[listContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Away" notify:NO];
			}
			break;
		case AWEzvOnline:
		case AWEzvIdle:
		default:
			if ([listContact integerStatusObjectForKey:@"Away"]){
				[listContact setStatusObject:nil forKey:@"Away" notify:NO];
			}
	}
	
	if (idleSinceDate = [contact idleSinceDate]){
		//Only set the new date object if the time interval has changed
		if ([[listContact statusObjectForKey:@"IdleSince"] timeIntervalSinceDate:idleSinceDate] != 0){
			[listContact setStatusObject:idleSinceDate forKey:@"IdleSince" notify:NO];
		}
	}else{
		[listContact setStatusObject:nil forKey:@"IdleSince" notify:NO];
	}
	
    if (statusMessage = [contact statusMessage]){
		NSString	*oldStatusMessage = [listContact stringFromAttributedStringStatusObjectForKey:@"StatusMessage"];
		
		if (!oldStatusMessage || ![oldStatusMessage isEqualToString:statusMessage]){
			[listContact setStatusObject:[[[NSAttributedString alloc] initWithString:statusMessage] autorelease]
								  forKey:@"StatusMessage"
								  notify:NO];
		}
	}else{
		[listContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
	}
	
	contactImage = [contact contactImage];
	if(contactImage != [listContact userIcon]){
		[listContact setStatusObject:contactImage forKey:KEY_USER_ICON notify:NO];
	}

    //The Rendezvous UID is useless; we'll use the contact alias as the formatted UID
	contactName = [contact name];
	if (![[listContact formattedUID] isEqualToString:contactName]){
		[listContact setStatusObject:contactName
							 forKey:@"FormattedUID"
							 notify:NO];
	}
	
    [libezvContacts setObject:[contact uniqueID] forKey:[contact uniqueID]];   
	
    //Apply any changes
    [listContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void) userLoggedOut:(AWEzvContact *)contact
{
    AIListContact *listContact;
    
    listContact = [[adium contactController] existingContactWithService:service
																account:self 
																	UID:[contact uniqueID]];
    
    [listContact setRemoteGroupName:nil];
    [libezvContacts removeObjectForKey:[contact uniqueID]];
}

//We received a message from an AWEzvContact
- (void) user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html
{
    AIListContact		*listContact;
    AIContentMessage	*msgObj;
    AIChat				*chat;
	
    listContact = [[adium contactController] existingContactWithService:service
														 account:self
															 UID:[contact uniqueID]];
	chat = [[adium contentController] chatWithContact:listContact];
	
    msgObj = [AIContentMessage messageInChat:chat
								  withSource:listContact
								 destination:self
										date:nil
									 message:[AIHTMLDecoder decodeHTML:html]
								   autoreply:NO];
    
    [[adium contentController] receiveContentObject:msgObj];
	
	//Clear the typing flag
	[chat setStatusObject:nil
				   forKey:KEY_TYPING
				   notify:YES];
}

- (void) user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus
{
    AIListContact   *listContact;
    AIChat			*chat;
    listContact = [[adium contactController] existingContactWithService:service
																account:self
																	UID:[contact uniqueID]];
	chat = [[adium contentController] existingChatWithContact:listContact];
		
    [chat setStatusObject:((typingStatus == AWEzvIsTyping) ? [NSNumber numberWithInt:AITyping] : nil)
					    forKey:KEY_TYPING
					    notify:YES];
}

- (void) user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
/* unimplemented in libezv at this stage */
}

- (void) user:(AWEzvContact *)contact sentFile:(NSString *)filename size:(size_t)size cookie:(int)cookie
{
/* sorry, no file transfer in libezv at the moment */
}

- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity
{

}

- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity forUser:(NSString *)contact
{

}

#pragma mark AIAccount Messaging
// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(AIContentObject *)object
{
    BOOL sent = NO;
    if([[object type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
		NSAttributedString  *attributedMessage = [(AIContentMessage *)object message];
		NSString			*message = [attributedMessage string];
		NSString			*htmlMessage = [AIHTMLDecoder encodeHTML:attributedMessage
															 headers:NO
															fontTags:YES
												  includingColorTags:YES
													   closeFontTags:YES
														   styleTags:YES
										  closeStyleTagsOnFontChange:YES
													  encodeNonASCII:YES
														encodeSpaces:NO
														  imagesPath:nil
												   attachmentsAsText:YES
									  attachmentImagesOnlyForSending:NO
													  simpleTagsOnly:NO];
		
		AIChat			*chat = [(AIContentMessage *)object chat];
		AIListObject    *listObject = [chat listObject];
		NSString		*to = [listObject UID];
		
		[libezv sendMessage:message 
						 to:to 
				   withHtml:htmlMessage];

		sent = YES;

    } else if([[object type] isEqualToString:CONTENT_TYPING_TYPE]) {
		AIContentTyping *contentTyping = (AIContentTyping*)object;
		AIChat			*chat = [contentTyping chat];
		AIListObject    *listObject = [chat listObject];
		NSString		*to = [listObject UID];
		
		[libezv sendTypingNotification:(([contentTyping typingState] == AITyping) ? AWEzvIsTyping : AWEzvNotTyping)
									to:to];
		sent = YES;
    }
	
    return sent;
}

//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
    if([inType isEqualToString:CONTENT_MESSAGE_TYPE] && [self online]){
		return(YES);
    }
    
    return NO;
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
    return(YES);
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
    return(YES);
}

#pragma mark Account Status
//Respond to account status changes
- (void)updateStatusForKey:(NSString *)key
{
    [super updateStatusForKey:key];
    
    BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];
    
    //Now look at keys which only make sense while online
    if(areOnline){
        NSData  *data;
        if([key isEqualToString:@"IdleSince"]){
            NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			
			[libezv setStatus:AWEzvIdle withMessage:[self preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS]];
            [self setAccountIdleTo:idleSince];
			
        } else if ( ([key isEqualToString:@"AwayMessage"])){
            [self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(setAccountAwayTo:)];
			
        } else if ( ([key isEqualToString:KEY_USER_ICON])) {
			if(data = [self preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]){
				[libezv setContactImage:[[[NSImage alloc] initWithData:data] autorelease]];
			}
			
		}
    }
}

- (void)setAccountIdleTo:(NSDate *)idle
{
	[libezv setIdleTime:idle];

	//We are now idle
	[self setStatusObject:idle forKey:@"IdleSince" notify:YES];
}

- (void)setAccountAwayTo:(NSAttributedString *)awayMessage
{
	if(!awayMessage || ![[awayMessage string] isEqualToString:[[self statusObjectForKey:@"StatusMessage"] string]]){
		if (awayMessage != nil)
		    [libezv setStatus:AWEzvAway withMessage:[NSString stringWithString:[awayMessage string]]];
		else
		    [libezv setStatus:AWEzvOnline withMessage:nil];
		
		//We are now away or not
		[self setStatusObject:[NSNumber numberWithBool:(awayMessage != nil)] forKey:@"Away" notify:YES];
		[self setStatusObject:awayMessage forKey:@"StatusMessage" notify:YES];
	}
}

//Status keys this account supports
- (NSArray *)supportedPropertyKeys
{
	static NSArray *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys)
		supportedPropertyKeys = [[NSArray alloc] initWithObjects:
			@"Display Name",
			@"Online",
			@"Offline",
			@"IdleSince",
			@"IdleManuallySet",
			KEY_USER_ICON,
			@"Away",
			@"AwayMessage",
			//      @"TextProfile",
			//      @"DefaultUserIconFilename",
			nil];
	
	return supportedPropertyKeys;
}

//Update all our status keys
- (void)updateAllStatusKeys
{
    [self updateStatusForKey:@"IdleSince"];
    [self updateStatusForKey:@"TextProfile"];
    [self updateStatusForKey:@"AwayMessage"];
    [self updateStatusForKey:KEY_USER_ICON];
}


@end