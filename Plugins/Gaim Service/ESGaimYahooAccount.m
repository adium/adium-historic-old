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
#import "AIStatusController.h"
#import "ESGaimYahooAccount.h"
#import "ESGaimYahooAccountViewController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <Libgaim/yahoo.h>
#import <Libgaim/yahoo_friend.h>

@implementation ESGaimYahooAccount

gboolean gaim_init_yahoo_plugin(void);
- (const char*)protocolPlugin
{
	static BOOL	didInitYahoo = NO;
	if (!didInitYahoo) didInitYahoo = gaim_init_yahoo_plugin();
    return "prpl-yahoo";
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];

	gaim_account_set_string(account, "room_list_locale", [[self preferenceForKey:KEY_YAHOO_ROOM_LIST_LOCALE
																		   group:GROUP_ACCOUNT_STATUS] UTF8String]);

	//Make sure we're not turning japanese oh no not turning japanese I really think so
	gaim_account_set_bool(account, "yahoojp", FALSE);
}

- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"AvailableMessage",
			@"Invisible",
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
}

#pragma mark Connection
- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
	}
	return nil;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError && *disconnectionError) {
		if ([*disconnectionError rangeOfString:@"Incorrect password"].location != NSNotFound) {
			[self serverReportedInvalidPassword];
		} else if (([*disconnectionError rangeOfString:@"You have signed on from another location"].location != NSNotFound) ||
				   ([*disconnectionError rangeOfString:@"logged in on a different machine or device"].location != NSNotFound)) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
}

#pragma mark Encoding
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{	
	if (inListObject) {
		return [AIHTMLDecoder encodeHTML:inAttributedString
								 headers:NO
								fontTags:YES
					  includingColorTags:YES
						   closeFontTags:YES
							   styleTags:YES
			  closeStyleTagsOnFontChange:YES
						  encodeNonASCII:NO
							encodeSpaces:NO
							  imagesPath:nil
					   attachmentsAsText:YES
			   onlyIncludeOutgoingImages:NO
						  simpleTagsOnly:YES
						  bodyBackground:NO];
	} else {
		return [inAttributedString string];
	}
}

#pragma mark File transfer
- (BOOL)canSendFolders
{
	return NO;
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}


- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

#pragma mark Status Messages

/*!
 * @brief Status name to use for a Gaim buddy
 */
- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)buddy
{
	NSString		*statusName = nil;
	GaimPresence	*presence = gaim_buddy_get_presence(buddy);
	GaimStatus		*status = gaim_presence_get_active_status(presence);
	const char		*gaimStatusID = gaim_status_get_id(status);
	
	if (!gaimStatusID) return nil;
	
	if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_BRB)) {
		statusName = STATUS_NAME_BRB;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_BUSY)) {
		statusName = STATUS_NAME_BUSY;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_NOTATHOME)) {
		statusName = STATUS_NAME_NOT_AT_HOME;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_NOTATDESK)) {
		statusName = STATUS_NAME_NOT_AT_DESK;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_NOTINOFFICE)) {
		statusName = STATUS_NAME_NOT_IN_OFFICE;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_ONPHONE)) {
		statusName = STATUS_NAME_PHONE;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_ONVACATION)) {
		statusName = STATUS_NAME_VACATION;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_OUTTOLUNCH)) {
		statusName = STATUS_NAME_LUNCH;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_STEPPEDOUT)) {
		statusName = STATUS_NAME_STEPPED_OUT;
		
	} else if (!strcmp(gaimStatusID, YAHOO_STATUS_TYPE_INVISIBLE)) {
		statusName = STATUS_NAME_INVISIBLE;
	}
	
	return statusName;
}

/*!
 * @brief Status message for a contact
 */
- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)b
{
	NSString			*statusMessageString = nil;
	NSAttributedString	*statusMessage = nil;
	char				*normalized = g_strdup(gaim_normalize(b->account, b->name));
	struct yahoo_data   *od;
	YahooFriend			*f;
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(f = g_hash_table_lookup(od->friends, normalized))) {
		
		if (f->msg != NULL) {
			statusMessageString = [NSString stringWithUTF8String:f->msg];
			
		} else if (f->status != YAHOO_STATUS_AVAILABLE) {
			switch (f->status) {
				case YAHOO_STATUS_BRB:
					statusMessageString = STATUS_DESCRIPTION_BRB;
					break;
					
				case YAHOO_STATUS_BUSY:
					statusMessageString = STATUS_DESCRIPTION_BUSY;
					break;
					
				case YAHOO_STATUS_NOTATHOME:
					statusMessageString = STATUS_DESCRIPTION_NOT_AT_HOME;
					break;
					
				case YAHOO_STATUS_NOTATDESK:
					statusMessageString = STATUS_DESCRIPTION_NOT_AT_DESK;
					break;
					
				case YAHOO_STATUS_NOTINOFFICE:
					statusMessageString = STATUS_DESCRIPTION_NOT_IN_OFFICE;
					break;
					
				case YAHOO_STATUS_ONPHONE:
					statusMessageString = STATUS_DESCRIPTION_PHONE;
					break;
					
				case YAHOO_STATUS_ONVACATION:
					statusMessageString = STATUS_DESCRIPTION_VACATION;
					break;
					
				case YAHOO_STATUS_OUTTOLUNCH:
					statusMessageString = STATUS_DESCRIPTION_LUNCH;
					break;
					
				case YAHOO_STATUS_STEPPEDOUT:
					statusMessageString = STATUS_DESCRIPTION_STEPPED_OUT;
					break;
					
				case YAHOO_STATUS_INVISIBLE:
					statusMessageString = STATUS_DESCRIPTION_INVISIBLE;
					//				statusType = AIInvisibleStatusType; /* Invisible has a special status type */
					break;
					
				case YAHOO_STATUS_AVAILABLE:
				case YAHOO_STATUS_WEBLOGIN:
				case YAHOO_STATUS_CUSTOM:
				case YAHOO_STATUS_IDLE:
				case YAHOO_STATUS_OFFLINE:
				case YAHOO_STATUS_TYPING:
					break;
			}
		}
		
		if (statusMessageString) {
			statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
															 attributes:nil] autorelease];
		}
	}

	g_free(normalized);
	
	return statusMessage;
}

/*!
 * @brief Update the status message and away state of the contact
 */
- (void)updateStatusForContact:(AIListContact *)theContact toStatusType:(NSNumber *)statusTypeNumber statusName:(NSString *)statusName statusMessage:(NSAttributedString *)statusMessage
{
	NSString			*statusMessageString = [statusMessage string];
	char				*normalized = g_strdup(gaim_normalize(account, [[theContact UID] UTF8String]));
	struct yahoo_data   *od;
	YahooFriend			*f;

	/* Grab the idle time while we have a chance */
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(f = g_hash_table_lookup(od->friends, normalized))) {

		if (f->status == YAHOO_STATUS_IDLE) {
			//Now idle
			int		idle = f->idle;
			NSDate	*idleSince;
			
			if (idle != -1) {
				idleSince = [NSDate dateWithTimeIntervalSinceNow:-idle];
			} else {
				idleSince = [NSDate date];
			}
			
			[theContact setStatusObject:idleSince
								 forKey:@"IdleSince"
								 notify:NotifyLater];
			
		} else if (f->status == YAHOO_STATUS_INVISIBLE) {
			statusTypeNumber = [NSNumber numberWithInt:AIInvisibleStatusType]; /* Invisible has a special status type */
		}
	}

	g_free(normalized);
	
	//Yahoo doesn't have an explicit mobile state; instead the status message is automatically set to indicate mobility.
	if (statusMessageString && ([statusMessageString isEqualToString:@"I'm on SMS"] ||
								([statusMessageString rangeOfString:@"I'm mobile"].location != NSNotFound))) {
		[theContact setIsMobile:YES notify:NotifyLater];

	} else if ([theContact isMobile]) {
		[theContact setIsMobile:NO notify:NotifyLater];		
	}
	
	[super updateStatusForContact:theContact
					 toStatusType:statusTypeNumber
					   statusName:statusName
					statusMessage:statusMessage];
}

/*!
 * @brief Return the gaim status ID to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status ID
 * @param arguments Prpl-specific arguments which will be passed with the state. Message is handled automatically.
 *
 * @result The gaim status ID
 */
- (char *)gaimStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	char			*statusID = NULL;
	NSString		*statusName = [statusState statusName];
	NSString		*statusMessageString = [statusState statusMessageString];

	if (!statusMessageString) statusMessageString = @"";

	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			statusID = YAHOO_STATUS_TYPE_AVAILABLE;
			break;

		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_BRB]) ||
				([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BRB] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_BRB;

			else if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BUSY] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_BUSY;

			else if (([statusName isEqualToString:STATUS_NAME_NOT_AT_HOME]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_NOT_AT_HOME] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_NOTATHOME;

			else if (([statusName isEqualToString:STATUS_NAME_NOT_AT_DESK]) ||
				([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_NOT_AT_DESK] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_NOTATDESK;
			
			else if (([statusName isEqualToString:STATUS_NAME_PHONE]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_PHONE] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_ONPHONE;
			
			else if (([statusName isEqualToString:STATUS_NAME_VACATION]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_VACATION] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_ONVACATION;
			
			else if (([statusName isEqualToString:STATUS_NAME_LUNCH]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_LUNCH] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_OUTTOLUNCH;
			
			else if (([statusName isEqualToString:STATUS_NAME_STEPPED_OUT]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_STEPPED_OUT] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_STEPPEDOUT;
			
			
			break;
		}
			
		case AIInvisibleStatusType:
			statusID = YAHOO_STATUS_TYPE_INVISIBLE;
			break;
		
		case AIOfflineStatusType:
			break;
	}
	
	//If we didn't get a gaim status ID, request one from super
	if (statusID == NULL) statusID = [super gaimStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (!strcmp(label, "Add Buddy")) {
		//We handle Add Buddy ourselves
		return nil;
		
	} else if (!strcmp(label, "Join in Chat")) {
		return [NSString stringWithFormat:AILocalizedString(@"Join %@'s Chat",nil),[inContact formattedUID]];

	} else if (!strcmp(label, "Initiate Conference")) {
		return [NSString stringWithFormat:AILocalizedString(@"Initiate Conference with %@",nil), [inContact formattedUID]];

	} else if (!strcmp(label, "Presence Settings")) {
		return [NSString stringWithFormat:AILocalizedString(@"Presence Settings for %@",nil), [inContact formattedUID]];

	} else if (!strcmp(label, "Appear Online")) {
		return [NSString stringWithFormat:AILocalizedString(@"Appear Online to %@",nil), [inContact formattedUID]];
		
	} else if (!strcmp(label, "Appear Offline")) {
		return [NSString stringWithFormat:AILocalizedString(@"Appear Offline to %@",nil), [inContact formattedUID]];
		
	} else if (!strcmp(label, "Appear Permanently Offline")) {
		return [NSString stringWithFormat:AILocalizedString(@"Always Appear Offline to %@",nil), [inContact formattedUID]];
		
	} else if (!strcmp(label, "Don't Appear Permanently Offline")) {
		return [NSString stringWithFormat:AILocalizedString(@"Don't Always Appear Offline to %@",nil), [inContact formattedUID]];
		
	} else if (!strcmp(label, "View Webcam")) {
		//return [NSString stringWithFormat:AILocalizedString(@"View %@'s Webcam",nil), [inContact formattedUID]];		
		return nil;

	} else if (!strcmp(label, "Start Doodling")) {
		return nil;
	}

	return [super titleForContactMenuLabel:label forContact:inContact];
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* The Yahoo actions are "Activate ID" (or perhaps "Active ID," depending on where in the code you look)
	 * and "Join User in Chat...".  These are dumb. Additionally, Join User in Chat doesn't work as of gaim 1.1.4. */
	return nil;
}

@end
