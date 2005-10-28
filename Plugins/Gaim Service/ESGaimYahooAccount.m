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
#import <Libgaim/yahoo_filexfer.h>
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
		} else if ([*disconnectionError rangeOfString:@"logged in on a different machine or device"].location != NSNotFound) {
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
		  attachmentImagesOnlyForSending:NO
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

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)) {
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
		
		return yahoo_xfer_new(account->gc,destsn);
	}
	
	return nil;
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
- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)b
{
	char				*normalized = g_strdup(gaim_normalize(b->account, b->name));
	struct yahoo_data   *od;
	YahooFriend			*f;
	NSString			*statusName = nil;
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(f = g_hash_table_lookup(od->friends, normalized))) {

		switch (f->status) {
			case YAHOO_STATUS_BRB:
				statusName = STATUS_NAME_BRB;
				break;
				
			case YAHOO_STATUS_BUSY:
				statusName = STATUS_NAME_BUSY;
				break;
				
			case YAHOO_STATUS_NOTATHOME:
				statusName = STATUS_NAME_NOT_AT_HOME;
				break;
				
			case YAHOO_STATUS_NOTATDESK:
				statusName = STATUS_NAME_NOT_AT_DESK;
				break;
				
			case YAHOO_STATUS_NOTINOFFICE:
				statusName = STATUS_NAME_NOT_IN_OFFICE;
				break;
				
			case YAHOO_STATUS_ONPHONE:
				statusName = STATUS_NAME_PHONE;
				break;
				
			case YAHOO_STATUS_ONVACATION:
				statusName = STATUS_NAME_VACATION;
				break;
				
			case YAHOO_STATUS_OUTTOLUNCH:
				statusName = STATUS_NAME_LUNCH;
				break;
				
			case YAHOO_STATUS_STEPPEDOUT:
				statusName = STATUS_NAME_STEPPED_OUT;
				break;
				
			case YAHOO_STATUS_INVISIBLE:
				statusName = STATUS_NAME_INVISIBLE;
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
	
	g_free(normalized);

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

/*
- (void)updateIdleReturn:(AIListContact *)theContact withData:(void *)data
{
	struct yahoo_data   *od;
	YahooFriend *f;
	
	const char				*buddyName = [[theContact UID] UTF8String];
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(f = g_hash_table_lookup(od->friends, buddyName))) {
		
		AIStatusType	statusType = ((f->status != YAHOO_STATUS_AVAILABLE) ? AIAwayStatusType : AIAvailableStatusType);		
		
		if (f->status != YAHOO_STATUS_IDLE) {
			NSLog(@"%@ is %i",theContact,f->status);
			[super updateIdleReturn:theContact withData:data];
		}
	}
}
*/

/*!
 * @brief Return the gaim status type to be used for a status
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status equivalent
 * @param statusMessage A pointer to the statusMessage.  Set *statusMessage to nil if it should not be used directly for this status.
 *
 * @result The gaim status equivalent
 */
- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage
{
	NSString		*statusName = [statusState statusName];
	AIStatusType	statusType = [statusState statusType];
	char			*gaimStatusType = NULL;
	
	switch (statusType) {
		case AIAvailableStatusType:
		{
			gaimStatusType = "Available";
			break;
		}

		case AIAwayStatusType:
		{
			NSString	*statusMessageString = (*statusMessage ? [*statusMessage string] : @"");

			if (([statusName isEqualToString:STATUS_NAME_BRB]) ||
				([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BRB] == NSOrderedSame))
				gaimStatusType = "Be Right Back";
			else if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BUSY] == NSOrderedSame))
				gaimStatusType = "Busy";
			else if (([statusName isEqualToString:STATUS_NAME_NOT_AT_HOME]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_NOT_AT_HOME] == NSOrderedSame))
				gaimStatusType = "Not At Home";
			else if (([statusName isEqualToString:STATUS_NAME_NOT_AT_DESK]) ||
				([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_NOT_AT_DESK] == NSOrderedSame))
				gaimStatusType = "Not At Desk";
			else if (([statusName isEqualToString:STATUS_NAME_PHONE]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_PHONE] == NSOrderedSame))
				gaimStatusType = "On The Phone";
			else if (([statusName isEqualToString:STATUS_NAME_VACATION]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_VACATION] == NSOrderedSame))
				gaimStatusType = "On Vacation";
			else if (([statusName isEqualToString:STATUS_NAME_LUNCH]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_LUNCH] == NSOrderedSame))
				gaimStatusType = "Out To Lunch";
			else if (([statusName isEqualToString:STATUS_NAME_STEPPED_OUT]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_STEPPED_OUT] == NSOrderedSame))
				gaimStatusType = "Stepped Out";

			break;
		}
			
		case AIInvisibleStatusType:
		{
			gaimStatusType = "Invisible";
			
			//We must clear the status message to enter an invisible state
			*statusMessage = nil;
			
			break;
		}
		
		case AIOfflineStatusType:
			break;
	}
	
	//If we are setting one of our custom statuses, clear a @"" statusMessage to nil
	if ((gaimStatusType != NULL) && ([*statusMessage length] == 0)) *statusMessage = nil;

	//If we didn't get a gaim status type, request one from super
	if (gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, "Add Buddy") == 0) {
		//We handle Add Buddy ourselves
		return nil;
	} else if (strcmp(label, "Join in Chat") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Join %@'s Chat",nil),[inContact formattedUID]];

	} else if (strcmp(label, "Initiate Conference") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Initiate Conference with %@",nil), [inContact formattedUID]];

	}  else if (strcmp(label, "View Webcam") == 0) {
		//return [NSString stringWithFormat:AILocalizedString(@"View %@'s Webcam",nil), [inContact formattedUID]];		
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
