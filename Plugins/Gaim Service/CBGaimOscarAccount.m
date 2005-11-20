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

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIStatusController.h"
#import "CBGaimOscarAccount.h"
#import "SLGaimCocoaAdapter.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>

#define DELAYED_UPDATE_INTERVAL			1.0

@implementation CBGaimOscarAccount

gboolean gaim_init_oscar_plugin(void);
- (const char*)protocolPlugin
{
	static BOOL didInitOscar = NO;
	if (!didInitOscar) {
		didInitOscar = gaim_init_oscar_plugin();
		if (!didInitOscar) NSLog(@"CBGaimOscarAccount: Oscar plugin failed to load.");
	}
	
    return "prpl-oscar";
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
		contactServiceID = @"libgaim-oscar-Mac";
	} else if (firstCharacter && (firstCharacter >= '0' && firstCharacter <= '9')) {
		contactServiceID = @"libgaim-oscar-ICQ";
	//		} else if (isMobile = (firstCharacter == '+')) {
	//			contactServiceID = @"libgaim-oscar-AIM";
	} else {
		contactServiceID = @"libgaim-oscar-AIM";
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

- (oneway void)updateUserInfo:(AIListContact *)theContact withData:(NSString *)userInfoString
{
	//For AIM contacts, we get profiles by themselves and don't want this userInfo with all its fields, so
	//we override this method to prevent the information from reaching the rest of Adium.
	
	//For ICQ contacts, however, we want to pass this data on as the profile
	const char	firstCharacter = [[theContact UID] characterAtIndex:0];
	
	if ((firstCharacter >= '0' && firstCharacter <= '9') || [theContact isStranger]) {
		[super updateUserInfo:theContact withData:userInfoString];
	}
}

#pragma mark Account status
- (char *)gaimStatusIDForStatus:(AIStatus *)statusState
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
				(comment = aim_ssi_getcomment(od->sess->ssi.local, g->name, buddy->name))) {
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
}


#pragma mark Delayed updates

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

- (void)_performDelayedUpdates:(NSTimer *)timer
{
	if ([arrayOfContactsForDelayedUpdates count]) {
		AIListContact *theContact = [arrayOfContactsForDelayedUpdates objectAtIndex:0];
		
		[theContact setStatusObject:[self serversideCommentForContact:theContact]
							 forKey:@"Notes"
							 notify:YES];

		//Request ICQ contacts' info to get the nickname
		if (aim_sn_is_icq([[theContact UID] UTF8String])) {
			[self delayedUpdateContactStatus:theContact];
		}

		[arrayOfContactsForDelayedUpdates removeObjectAtIndex:0];
		
	} else {
		[arrayOfContactsForDelayedUpdates release]; arrayOfContactsForDelayedUpdates = nil;
		[delayedSignonUpdateTimer invalidate]; [delayedSignonUpdateTimer release]; delayedSignonUpdateTimer = nil;
	}
}

#pragma mark File transfer

/*!
* @brief Allow a file transfer with an object?
 *
 * Only return YES if the user's capabilities include AIM_CAPS_SENDFILE indicating support for file transfer
 */
- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, [[inListObject UID] UTF8String]))) {
		
		return (userinfo->capabilities & AIM_CAPS_SENDFILE);
	}
	
	return NO;
}

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
- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)b
{
	NSString			*statusMessage = nil;
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	struct buddyinfo	*bi;
	char				*normalized = g_strdup(gaim_normalize(b->account, b->name));
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, normalized))) {
		
		bi = (od->buddyinfo ? g_hash_table_lookup(od->buddyinfo, normalized) : NULL);
		
		if ((bi != NULL) && (bi->availmsg != NULL) && !(userinfo->flags & AIM_FLAG_AWAY)) {
			
			//Available status message - bi->availmsg has already been converted to UTF8 if needed for us.
			statusMessage = [NSString stringWithUTF8String:(bi->availmsg)];
			
		} else if ((userinfo->flags & AIM_FLAG_AWAY) && (userinfo->away != NULL)) {
			if ((userinfo->away_len > 0) && 
				(userinfo->away_encoding != NULL)) {
				
				//Away message using specified encoding
				statusMessage = [self stringWithBytes:userinfo->away
											   length:userinfo->away_len
											 encoding:userinfo->away_encoding];
			} else {
				//Away message, no encoding provided, assume UTF8
				statusMessage = [NSString stringWithUTF8String:userinfo->away];
			}
		}
	}
	
	g_free(normalized);
	
	if (statusMessage) {
		// We use our own HTML decoder to avoid conflicting with the shared one, since we are running in a thread
		static AIHTMLDecoder	*statusMessageHTMLDecoder = nil;
		if (!statusMessageHTMLDecoder) statusMessageHTMLDecoder = [[AIHTMLDecoder decoder] retain];
		
		return [statusMessageHTMLDecoder decodeHTML:statusMessage];
	} else {
		return nil;
	}
}

- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)buddy
{
	NSString		*statusName = nil;
	
	if (aim_sn_is_icq(buddy->name)) {
		GaimPresence	*presence = gaim_buddy_get_presence(buddy);
		GaimStatus *status = gaim_presence_get_active_status(presence);
		const char *gaimStatusName = gaim_status_get_name(status);

		if (!strcmp(gaimStatusName, OSCAR_STATUS_ID_INVISIBLE)) {
			statusName = STATUS_NAME_INVISIBLE;

		} else if (!strcmp(gaimStatusName, OSCAR_STATUS_ID_OCCUPIED)) {
			statusName = STATUS_NAME_OCCUPIED;

		} else if (!strcmp(gaimStatusName, OSCAR_STATUS_ID_NA)) {
			statusName = STATUS_NAME_NOT_AVAILABLE;

		} else if (!strcmp(gaimStatusName, OSCAR_STATUS_ID_DND)) {
			statusName = STATUS_NAME_DND;

		} else if (!strcmp(gaimStatusName, OSCAR_STATUS_ID_FREE4CHAT)) {
			statusName = STATUS_NAME_FREE_FOR_CHAT;

		}
	}

	return statusName;
}

@end

#pragma mark Coding Notes

/*if (isdigit(b->name[0])) {
char *status;
status = gaim_icq_status((b->uc & 0xffff0000) >> 16);
tmp = ret;
ret = g_strconcat(tmp, _("<b>Status:</b> "), status, "\n", NULL);
g_free(tmp);
g_free(status);
}

if ((bi != NULL) && (bi->ipaddr)) {
    char *tstr =  g_strdup_printf("%hhd.%hhd.%hhd.%hhd",
                                  (bi->ipaddr & 0xff000000) >> 24,
                                  (bi->ipaddr & 0x00ff0000) >> 16,
                                  (bi->ipaddr & 0x0000ff00) >> 8,
                                  (bi->ipaddr & 0x000000ff));
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>IP Address:</b> "), tstr, "\n", NULL);
    g_free(tmp);
    g_free(tstr);
}

if ((userinfo != NULL) && (userinfo->capabilities)) {
    char *caps = caps_string(userinfo->capabilities);
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>Capabilities:</b> "), caps, "\n", NULL);
    g_free(tmp);
}

static void oscar_ask_direct_im(GaimBlistNode *node, gpointer ignored);

*/

#if 0
//**Adium
GaimXfer *oscar_xfer_new(GaimConnection *gc, const char *destsn) {
	OscarData *od = (OscarData *)gc->proto_data;
	GaimXfer *xfer;
	struct aim_oft_info *oft_info;
	
	/* You want to send a file to someone else, you're so generous */
	
	/* Build the file transfer handle */
	xfer = gaim_xfer_new(gaim_connection_get_account(gc), GAIM_XFER_SEND, destsn);
	xfer->local_port = 5190;
	
	/* Create the oscar-specific data */
	oft_info = aim_oft_createinfo(od->sess, NULL, destsn, xfer->local_ip, xfer->local_port, 0, 0, NULL);
	xfer->data = oft_info;
	
	/* Setup our I/O op functions */
	gaim_xfer_set_init_fnc(xfer, oscar_xfer_init);
	gaim_xfer_set_start_fnc(xfer, oscar_xfer_start);
	gaim_xfer_set_end_fnc(xfer, oscar_xfer_end);
	gaim_xfer_set_cancel_send_fnc(xfer, oscar_xfer_cancel_send);
	gaim_xfer_set_cancel_recv_fnc(xfer, oscar_xfer_cancel_recv);
	gaim_xfer_set_ack_fnc(xfer, oscar_xfer_ack);
	
	/* Keep track of this transfer for later */
	od->file_transfers = g_slist_append(od->file_transfers, xfer);
	
	return xfer;
}
#endif
