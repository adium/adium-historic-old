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

#import "AIStatusController.h"
#import "ESGaimICQAccount.h"
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

@interface ESGaimICQAccount (PRIVATE)
- (void)updateStatusMessage:(AIListContact *)theContact;
@end

@implementation ESGaimICQAccount

- (void)configureGaimAccount
{
	[super configureGaimAccount];

	NSString	*encoding;

	//Default encoding
	if ((encoding = [self preferenceForKey:KEY_ICQ_ENCODING group:GROUP_ACCOUNT_STATUS])) {
		gaim_account_set_string(account, "encoding", [encoding UTF8String]);
	}
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	//As an ICQ account we should always send plain text, so no more complex checking is needed
	return [[inAttributedString attributedStringByConvertingLinksToStrings] string];
}

//CBGaimOscarAccount does complex things here, but ICQ can just perform a normal encodedAttributedString:forListObject
- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{		
	return [self encodedAttributedString:[inContentMessage message] forListObject:[inContentMessage destination]];
}

/*!
 * @brief Setting aliases serverside would override the information Gaim is feeding us
 */
- (BOOL)shouldSetAliasesServerside
{
	return NO;
}

/*!
 * @brief ICQ supports offline messaging
 */
- (BOOL)supportsOfflineMessaging
{
	return YES;
}

#pragma mark Contact updates

- (char *)gaimStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	char			*statusID = NULL;
	NSString		*statusName = [statusState statusName];
	NSString		*statusMessageString = [statusState statusMessageString];
	
	if (!statusMessageString) statusMessageString = @"";
		
	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			if ([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) {
				statusID = OSCAR_STATUS_ID_FREE4CHAT;
			}
			break;

		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
			   ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_DND] == NSOrderedSame))
				statusID = OSCAR_STATUS_ID_DND;
			else if (([statusName isEqualToString:STATUS_NAME_NOT_AVAILABLE]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_NOT_AVAILABLE] == NSOrderedSame))
				statusID = OSCAR_STATUS_ID_NA;
			else if (([statusName isEqualToString:STATUS_NAME_OCCUPIED]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_OCCUPIED] == NSOrderedSame))
				statusID = OSCAR_STATUS_ID_OCCUPIED;
			break;
		}
			
		case AIInvisibleStatusType: 
		case AIOfflineStatusType:
			break;
	}

	//If we didn't get a gaim status type, request one from super
	if (statusID == NULL) statusID = [super gaimStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, "Re-request Authorization") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Re-request Authorization from %@",nil),[inContact formattedUID]];
	}
	
	return [super titleForContactMenuLabel:label forContact:inContact];
}

@end
