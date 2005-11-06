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
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject contentMessage:(AIContentMessage *)contentMessage
{	
	return [self encodedAttributedString:inAttributedString forListObject:inListObject];
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
- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)b
{
	NSAttributedString	*statusMessage;
	
	statusMessage = [super statusMessageForGaimBuddy:b];

	//If we don't get a status message from super, try to generate a generic one based on the state
	if (!statusMessage || ![statusMessage length]) {
					
		/* ((b->uc & 0xffff0000) >> 16) is nicely undocumented magic from oscar.c.  It turns out that real
		* men don't document their code. */
		int			state = ((b->uc & 0xffff0000) >> 16);
		NSString	*statusMessageString = nil;
		
		if (state & AIM_ICQ_STATE_CHAT) {
			statusMessageString = STATUS_DESCRIPTION_FREE_FOR_CHAT;
			
		} else if (state & AIM_ICQ_STATE_DND) {
			statusMessageString = STATUS_DESCRIPTION_DND;
			
		} else if (state & AIM_ICQ_STATE_OUT) {
			statusMessageString = STATUS_DESCRIPTION_NOT_AVAILABLE;
			
		} else if (state & AIM_ICQ_STATE_BUSY) {
			statusMessageString = STATUS_DESCRIPTION_OCCUPIED;
			
		} else if (state & AIM_ICQ_STATE_INVISIBLE) {
			statusMessageString = STATUS_DESCRIPTION_INVISIBLE;
		}
		
		if (statusMessageString) {
			statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
															 attributes:nil] autorelease];
		}
	}

	return statusMessage;
}

- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)b
{
	NSString		*statusName = nil;
	
	/* ((b->uc & 0xffff0000) >> 16) is nicely undocumented magic from oscar.c.  It turns out that real
		* men don't document their code. */
	int state = ((b->uc & 0xffff0000) >> 16);
	
	if (state & AIM_ICQ_STATE_CHAT) {
		statusName = STATUS_NAME_FREE_FOR_CHAT;
		
	} else if (state & AIM_ICQ_STATE_DND) {
		statusName = STATUS_NAME_DND;
		
	} else if (state & AIM_ICQ_STATE_OUT) {
		statusName = STATUS_NAME_NOT_AVAILABLE;
		
	} else if (state & AIM_ICQ_STATE_BUSY) {
		statusName = STATUS_NAME_OCCUPIED;
		
	} else if (state & AIM_ICQ_STATE_INVISIBLE) {
		statusName = STATUS_NAME_INVISIBLE;
	}
				
	return statusName;
}

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
			if ([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) {
				gaimStatusType = "Free For Chat";
			} else {
				/* ICQ uses "Online" rather than "Available" for the base available state.
				 * For any available state we don't have a specific statusType for, use "Online"
				 * rather than the "Available" CBGaimAccount will provide. */ 				
				gaimStatusType = "Online";
			}
			
			//No available status message for ICQ, sadly
			*statusMessage = nil;
			
			break;
		}

		case AIAwayStatusType:
		{
			NSString	*statusMessageString = (*statusMessage ? [*statusMessage string] : @"");

			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
			   ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_DND] == NSOrderedSame))
				gaimStatusType = "Do Not Disturb";
			else if (([statusName isEqualToString:STATUS_NAME_NOT_AVAILABLE]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_NOT_AVAILABLE] == NSOrderedSame))
				gaimStatusType = "Not Available";
			else if (([statusName isEqualToString:STATUS_NAME_OCCUPIED]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_OCCUPIED] == NSOrderedSame))
				gaimStatusType = "Occupied";
			else
				gaimStatusType = "Away";

			break;
		}
			
		case AIInvisibleStatusType: 
			gaimStatusType = "Invisible";
			
			//No invisible status message
			*statusMessage = nil;

			break;
		
		case AIOfflineStatusType:
			break;
	}

	//If we are setting one of our custom statuses, don't use a status message
//	if (gaimStatusType != NULL) 	*statusMessage = nil;

	//If we didn't get a gaim status type, request one from super
	if (gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
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
