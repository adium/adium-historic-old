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

@interface ESGaimICQAccount (PRIVATE)
- (void)updateStatusMessage:(AIListContact *)theContact;
@end

@implementation ESGaimICQAccount

- (void)configureGaimAccount
{
	[super configureGaimAccount];

	NSString	*encoding;

	//Default encoding
	if ((encoding = [self preferenceForKey:KEY_ICQ_ENCODING group:GROUP_ACCOUNT_STATUS])){
		gaim_account_set_string(account, "encoding", [encoding UTF8String]);
	}
}

- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;

	if (!supportedPropertyKeys){
		supportedPropertyKeys = [[super supportedPropertyKeys] mutableCopy];
		//ICQ doesn't support available messages
		[supportedPropertyKeys removeObject:@"AvailableMessage"];
	}
	
	return supportedPropertyKeys;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	//As an ICQ account we should always send plain text, so no more complex checking is needed
	return ([inAttributedString string]);
}

//CBGaimOscarAccount does complex things here, but ICQ can just perform a normal encodedAttributedString:forListObject
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject contentMessage:(AIContentMessage *)contentMessage
{	
	return([self encodedAttributedString:inAttributedString forListObject:inListObject]);
}

/*!
 * @brief Setting aliases serverside would override the information Gaim is feeding us
 */
- (BOOL)shouldSetAliasesServerside
{
	return(NO);
}

#pragma mark Status
/*!
 * @brief Get the ICQ status message when going away and coming back
 *
 * We really should have a buddy-status-message signal from libgaim, but I can't figure out where to
 * add it to the libgaim code.... so this ghetto fix will do for now, pending the status rewrite for gaim
 * when we'll revisit this.  Only problem with this method is that an ICQ user going from one away state
 * to another isn't going to get updated properly... so this should be fixed eventually. -eds
 */
- (void)_updateAwayOfContact:(AIListContact *)theContact toAway:(BOOL)newAway
{
	[super _updateAwayOfContact:theContact toAway:newAway];
	
	[self updateStatusMessage:theContact];
}

- (NSString *)ICQStatusMessageForState:(int)state
{
	NSString	*statusMessage = nil;

	if (state & AIM_ICQ_STATE_CHAT)
		statusMessage = STATUS_DESCRIPTION_FREE_FOR_CHAT;
	else if (state & AIM_ICQ_STATE_DND)
		statusMessage = STATUS_DESCRIPTION_DND;
	else if (state & AIM_ICQ_STATE_OUT)
		statusMessage = STATUS_DESCRIPTION_NOT_AVAILABLE;
	else if (state & AIM_ICQ_STATE_BUSY)
		statusMessage = STATUS_DESCRIPTION_OCCUPIED;
	else if (state & AIM_ICQ_STATE_WEBAWARE)
		statusMessage = AILocalizedString(@"Web Aware",nil);
	else if (state & AIM_ICQ_STATE_INVISIBLE)
		statusMessage = STATUS_DESCRIPTION_INVISIBLE;

	return statusMessage;
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	GaimBuddy	*buddy;
	const char	*uidUTF8String = [[theContact UID] UTF8String];
	
	if ((gaim_account_is_connected(account)) &&
		(buddy = gaim_find_buddy(account, uidUTF8String))) {
		
		NSString		*statusMsgString = nil;
		NSString		*oldStatusMsgString = [theContact statusObjectForKey:@"StatusMessageString"];

		/* ((buddy->uc & 0xffff0000) >> 16) is nicely undocumented magic from oscar.c.  It turns out that real
		 * men don't document their code. */
		statusMsgString = [self ICQStatusMessageForState:((buddy->uc & 0xffff0000) >> 16)];
		
		if (statusMsgString && [statusMsgString length]) {
			if (![statusMsgString isEqualToString:oldStatusMsgString]) {
				NSAttributedString *attrStr;
				
				attrStr = [[NSAttributedString alloc] initWithString:statusMsgString];
				
				[theContact setStatusObject:statusMsgString forKey:@"StatusMessageString" notify:NO];
				[theContact setStatusObject:attrStr forKey:@"StatusMessage" notify:NO];
				
				[attrStr release];
			}
			
		} else if (oldStatusMsgString && [oldStatusMsgString length]) {
			//If we had a message before, remove it
			[theContact setStatusObject:nil forKey:@"StatusMessageString" notify:NO];
			[theContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
		}
		
		//apply changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
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

	switch(statusType){
		case AIAvailableStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]){
				gaimStatusType = "Free For Chat";
			}else{
				/* ICQ uses "Online" rather than "Available" for the base available state.
				 * For any available state we don't have a specific statusType for, use "Online"
				 * rather than the "Available" CBGaimAccount will provide. */ 				
				gaimStatusType = "Online";
			}
			
			break;
		}

		case AIAwayStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_DND])
				gaimStatusType = "Do Not Disturb";
			else if ([statusName isEqualToString:STATUS_NAME_NOT_AVAILABLE])
				gaimStatusType = "Not Available";
			else if ([statusName isEqualToString:STATUS_NAME_OCCUPIED])
				gaimStatusType = "Occupied";
			
			break;
		}
	}

	//If we are setting one of our custom statuses, don't use a status message
	if(gaimStatusType != NULL) 	*statusMessage = nil;

	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

//ICQ doesn't support automatic typing notification clearing after a send, but AIM and .Mac do, so we return YES
//for smooth operation, particularly with iChat where this is very noticeable.
- (BOOL)suppressTypingNotificationChangesAfterSend
{
	return(YES);
}

@end
