/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import "CBGaimOscarAccount.h"
#import "SLGaimCocoaAdapter.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIHTMLDecoder.h>

#define DELAYED_UPDATE_INTERVAL			2.0

extern gchar *oscar_encoding_extract(const char *encoding);

@implementation CBGaimOscarAccount

- (const char*)protocolPlugin
{
	NSLog(@"WARNING: Subclass must override");
    return "";
}

#pragma mark AIListContact and AIService special cases for OSCAR
//Override contactWithUID to mark mobile and ICQ users as such via the displayServiceID
- (AIListContact *)contactWithUID:(NSString *)sourceUID
{
	AIListContact	*contact;
	
	if (!namesAreCaseSensitive) {
		sourceUID = [sourceUID compactedString];
	}
	
	contact = [[adium contactController] existingContactWithService:service
															account:self
																UID:sourceUID];
	if (!contact) {		
		contact = [[adium contactController] contactWithService:[self _serviceForUID:sourceUID]
														account:self
															UID:sourceUID];
	}
	
	return contact;
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	AIService	*contactService;
	NSString	*contactServiceID = nil;
	
	const char	firstCharacter = ([contactUID length] ? [contactUID characterAtIndex:0] : '\0');

	//Determine service based on UID
	if ([contactUID hasSuffix:@"@mac.com"]) {
#ifdef JOSCAR_SUPERCEDE_LIBGAIM
		contactServiceID = @"joscar-OSCAR-dotMac";
#else
		contactServiceID = @"libgaim-oscar-Mac";
#endif
	} else if (firstCharacter && (firstCharacter >= '0' && firstCharacter <= '9')) {
		contactServiceID = @"libgaim-oscar-ICQ";
	} else {
#ifdef JOSCAR_SUPERCEDE_LIBGAIM
		contactServiceID = @"joscar-OSCAR-AIM";
#else
		contactServiceID = @"libgaim-oscar-AIM";
#endif
	}

	contactService = [[adium accountController] serviceWithUniqueID:contactServiceID];

	return contactService;
}
	
#pragma mark Account Connection

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;

	if (disconnectionError && *disconnectionError) {
		if (([*disconnectionError rangeOfString:@"Incorrect nickname or password."].location != NSNotFound) ||
			([*disconnectionError rangeOfString:@"Authentication failed"].location != NSNotFound)){
			[self serverReportedInvalidPassword];

		} else if ([*disconnectionError rangeOfString:@"signed on with this screen name at another location"].location != NSNotFound) {
			shouldAttemptReconnect = NO;
		} else if ([*disconnectionError rangeOfString:@"too frequently"].location != NSNotFound) {
			shouldAttemptReconnect = NO;	
		}
	}
	
	return shouldAttemptReconnect;
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Screen name sent",nil);
			break;
		case 2:
			return AILocalizedString(@"Password sent",nil);
			break;			
		case 3:
			return AILocalizedString(@"Received authorization",nil);
			break;
		case 4:
			return AILocalizedString(@"Connection established",nil);
			break;
		case 5:
			return AILocalizedString(@"Finalizing connection",nil);
			break;
	}

	return nil;
}

- (oneway void)updateUserInfo:(AIListContact *)theContact withData:(GaimNotifyUserInfo *)user_info
{
	NSString	*contactUID = [theContact UID];
	const char	firstCharacter = [contactUID characterAtIndex:0];

	if ((firstCharacter >= '0' && firstCharacter <= '9')) {
		//For ICQ contacts, however, we want to pass this data on as the profile
		[super updateUserInfo:theContact withData:user_info];

	} else {
		GList *l;
		
		for (l = gaim_notify_user_info_get_entries(user_info); l != NULL; l = l->next) {
			GaimNotifyUserInfoEntry *user_info_entry = l->data;
			if (gaim_notify_user_info_entry_get_label(user_info_entry) &&
				strcmp(gaim_notify_user_info_entry_get_label(user_info_entry), "Profile") == 0) {

				[theContact setProfile:[AIHTMLDecoder decodeHTML:(gaim_notify_user_info_entry_get_value(user_info_entry) ?
																  [NSString stringWithUTF8String:gaim_notify_user_info_entry_get_value(user_info_entry)] :
																  nil)]
								notify:NotifyLater];
				
				//Apply any changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];
			}
		}
	}
}

#pragma mark Account status
- (const char *)gaimStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	char	*statusID = NULL;

	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			statusID = OSCAR_STATUS_ID_AVAILABLE;
			break;
		case AIAwayStatusType:
			statusID = OSCAR_STATUS_ID_AWAY;
			break;

		case AIInvisibleStatusType:
			statusID = OSCAR_STATUS_ID_INVISIBLE;
			break;
			
		case AIOfflineStatusType:
			statusID = OSCAR_STATUS_ID_OFFLINE;
			break;
	}
	
	return statusID;
}


#pragma mark Contact notes
-(NSString *)serversideCommentForContact:(AIListContact *)theContact
{	
	NSString *serversideComment = nil;
	
	if (gaim_account_is_connected(account)) {
		const char  *uidUTF8String = [[theContact UID] UTF8String];
		GaimBuddy   *buddy;
		
		if ((buddy = gaim_find_buddy(account, uidUTF8String))) {
			GaimGroup   *g;
			char		*comment;
			OscarData   *od;
			
			if ((g = gaim_buddy_get_group(buddy)) &&
				(od = account->gc->proto_data) &&
				(comment = aim_ssi_getcomment(od->ssi.local, g->name, buddy->name))) {
				gchar		*comment_utf8;
				
				comment_utf8 = gaim_utf8_try_convert(comment);
				serversideComment = [NSString stringWithUTF8String:comment_utf8];
				g_free(comment_utf8);
				
				free(comment);
			}
		}
	}
	
	return serversideComment;
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
#ifndef JOSCAR_SUPERCEDE_LIBGAIM
	if ([group isEqualToString:PREF_GROUP_NOTES]) {
		//If the notification object is a listContact belonging to this account, update the serverside information
		if (account &&
			[object isKindOfClass:[AIListContact class]] && 
			[(AIListContact *)object account] == self) {
			
			if ([key isEqualToString:@"Notes"]) {
				NSString  *comment = [object preferenceForKey:@"Notes" 
														group:PREF_GROUP_NOTES
										ignoreInheritedValues:YES];
				
				[[super gaimThread] OSCAREditComment:comment forUID:[object UID] onAccount:self];
			}			
		}
	}
#endif
}


#pragma mark Delayed updates

- (void)_performDelayedUpdates:(NSTimer *)timer
{
	if ([arrayOfContactsForDelayedUpdates count]) {
		AIListContact *theContact = [arrayOfContactsForDelayedUpdates objectAtIndex:0];
		
		[theContact setStatusObject:[self serversideCommentForContact:theContact]
							 forKey:@"Notes"
							 notify:YES];

		//Request ICQ contacts' info to get the nickname
		const char *contactUIDUTF8String = [[theContact UID] UTF8String];
		if (aim_sn_is_icq(contactUIDUTF8String)) {
			OscarData			*od;

			if ((gaim_account_is_connected(account)) &&
				(od = account->gc->proto_data)) {
				aim_icq_getalias(od, contactUIDUTF8String);
			}
		}

		[arrayOfContactsForDelayedUpdates removeObjectAtIndex:0];
		
	} else {
		[arrayOfContactsForDelayedUpdates release]; arrayOfContactsForDelayedUpdates = nil;
		[delayedSignonUpdateTimer invalidate]; [delayedSignonUpdateTimer release]; delayedSignonUpdateTimer = nil;
	}
}

- (void)gotGroupForContact:(AIListContact *)theContact
{
	if (theContact) {
		if (!arrayOfContactsForDelayedUpdates) arrayOfContactsForDelayedUpdates = [[NSMutableArray alloc] init];
		[arrayOfContactsForDelayedUpdates addObject:theContact];
		
		if (!delayedSignonUpdateTimer) {
			delayedSignonUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:DELAYED_UPDATE_INTERVAL 
																		 target:self
																	   selector:@selector(_performDelayedUpdates:) 
																	   userInfo:nil 
																		repeats:YES] retain];
		}
	}
}

- (void)removeContacts:(NSArray *)objects
{
	//Stop any pending delayed updates for these objects
	[arrayOfContactsForDelayedUpdates removeObjectsInArray:objects];

	[super removeContacts:objects];
}

#pragma mark File transfer

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

- (BOOL)canSendFolders
{
	return [super canSendFolders];
}

#pragma mark Contacts
/*!
 * @brief Should set aliases serverside?
 *
 * AIM and ICQ support serverside aliases.
 */
- (BOOL)shouldSetAliasesServerside
{
	return YES;
}


#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, "Edit Buddy Comment") == 0) {
		return nil;

	} else if (strcmp(label, "Re-request Authorization") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Re-request Authorization from %@",nil),[inContact formattedUID]];
		
	} else 	if (strcmp(label, "Get AIM Info") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Get AIM information for %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "Direct IM") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Initiate Direct IM with %@",nil),[inContact formattedUID]];
	}

	return [super titleForContactMenuLabel:label forContact:inContact];
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (strcmp(label, "Set User Info...") == 0) {
		return nil;
	} else if (strcmp(label, "Edit Buddy Comment") == 0) {
		return nil;
	} else if (strcmp(label, "Show Buddies Awaiting Authorization") == 0) {
		/* XXX Depends on adiumGaimRequestFields() */
		return nil;
	}

	return [super titleForAccountActionMenuLabel:label];
}

- (NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding
{
	//Default to UTF-8
	NSStringEncoding	desiredEncoding = NSUTF8StringEncoding;
	
	//Only attempt to check encoding if we were passed one
	if (encoding && (encoding[0] != '\0')) {
		NSString	*encodingString = [NSString stringWithUTF8String:encoding];
		NSRange		encodingRange;
		
		encodingRange = (encodingString ? [encodingString rangeOfString:@"charset=\""] : NSMakeRange(NSNotFound, 0));
		if (encodingRange.location != NSNotFound) {
			encodingString = [encodingString substringWithRange:NSMakeRange(NSMaxRange(encodingRange),
																			[encodingString length] - NSMaxRange(encodingRange) - 1)];
			if (encodingString && [encodingString length]) {
				desiredEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingString));
				
				if (desiredEncoding == kCFStringEncodingInvalidId) {
					desiredEncoding = NSUTF8StringEncoding;
				}
			}
		}
	}
	
	return [[[NSString alloc] initWithBytes:bytes length:length encoding:desiredEncoding] autorelease];
}

#pragma mark Buddy status
- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)buddy
{
	NSString		*statusName = nil;
	
	if (aim_sn_is_icq(buddy->name)) {
		GaimPresence	*presence = gaim_buddy_get_presence(buddy);
		GaimStatus *status = gaim_presence_get_active_status(presence);
		const char *gaimStatusID = gaim_status_get_id(status);

		if (!strcmp(gaimStatusID, OSCAR_STATUS_ID_INVISIBLE)) {
			statusName = STATUS_NAME_INVISIBLE;

		} else if (!strcmp(gaimStatusID, OSCAR_STATUS_ID_OCCUPIED)) {
			statusName = STATUS_NAME_OCCUPIED;

		} else if (!strcmp(gaimStatusID, OSCAR_STATUS_ID_NA)) {
			statusName = STATUS_NAME_NOT_AVAILABLE;

		} else if (!strcmp(gaimStatusID, OSCAR_STATUS_ID_DND)) {
			statusName = STATUS_NAME_DND;

		} else if (!strcmp(gaimStatusID, OSCAR_STATUS_ID_FREE4CHAT)) {
			statusName = STATUS_NAME_FREE_FOR_CHAT;

		}
	}

	return statusName;
}

@end
