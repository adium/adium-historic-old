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
#import "ESGaimMeanwhileAccount.h"
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>

@interface ESGaimMeanwhileAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimMeanwhileAccount

#ifndef MEANWHILE_NOT_AVAILABLE

- (const char*)protocolPlugin
{
	static BOOL didInitMeanwhile = NO;
	
	[self initSSL];
	if (!didInitMeanwhile) didInitMeanwhile = gaim_init_meanwhile_plugin(); 
    return "prpl-meanwhile";
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	int contactListChoice = [[self preferenceForKey:KEY_MEANWHILE_CONTACTLIST group:GROUP_ACCOUNT_STATUS] intValue];

	gaim_prefs_set_int(MW_PRPL_OPT_BLIST_ACTION, contactListChoice);
}

#pragma mark Status Messages
- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	SEL updateSelector = nil;
	
	switch ([event intValue]){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
	}
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	if (gaim_account_is_connected(account)){
		const char  *uidUTF8String = [[theContact UID] UTF8String];
		GaimBuddy   *buddy;
		
		NSLog(@"%@: update %@ gives %x",self, theContact, gaim_find_buddy(account, uidUTF8String));
	
		if (buddy = gaim_find_buddy(account, uidUTF8String)){			
			AIStatusType	statusType = ((buddy->uc & UC_UNAVAILABLE) ? AIAwayStatusType : AIAvailableStatusType);
			
			[theContact setStatusWithName:nil
							   statusType:statusType
							statusMessage:[self statusMessageForContact:theContact]
								   notify:NotifyLater];
			
			//Apply the change
			[theContact notifyOfChangedStatusSilently:silentAndDelayed];
		}
	}
}

//Away and away return
- (void)_updateAwayOfContact:(AIListContact *)theContact toAway:(BOOL)newAway
{
	NSLog(@"update away");
	[self updateStatusMessage:theContact];
}

- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact
{
	NSAttributedString		*statusMessage = nil;
	GaimConnection			*gc = [self gaimAccount]->gc;
		
	struct mw_plugin_data	*pd = ((struct mw_plugin_data *)(gc->proto_data));
	struct mwAwareIdBlock	t = { mwAware_USER, (char *)[[theContact UID] UTF8String], NULL };
	
	const char				*statusMessageText = (const char *)mwServiceAware_getText(pd->srvc_aware, &t);
	NSString				*statusMessageString = (statusMessageText ? [NSString stringWithUTF8String:statusMessageText] : nil);
	
	if (statusMessageString && [statusMessageString length]){
		statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
														 attributes:nil] autorelease];
	}
	NSLog(@"%@ stauts message is %@",theContact,statusMessage);
	
	return statusMessage;
}

#pragma mark Status
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
			if([statusName isEqualToString:STATUS_NAME_AVAILABLE])
				gaimStatusType = "Active";
			break;
		}
			
		case AIAwayStatusType:
		{
			NSString	*statusMessageString = (*statusMessage ? [*statusMessage string] : @"");

			if ([statusName isEqualToString:STATUS_NAME_AWAY])
				gaimStatusType = "Away";
			else if(([statusName isEqualToString:STATUS_NAME_DND]) ||
					([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_DND] == NSOrderedSame))
				gaimStatusType = "Do Not Disturb";
			
			break;
		}
	}
	
	/* XXX (?) Meanwhile supports status messages along with the status types, so let our message stay */
	
	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if(strcmp(label, "Set Active Message...") == 0){
		return(nil);
		
	}else if(strcmp(label, "Import Sametime List...") == 0){
		return(AILocalizedString(@"Import Sametime List...",nil));
		
	}else if(strcmp(label, "Export Sametime List...") == 0){
		return(AILocalizedString(@"Export Sametime List...",nil));
	}

	return([super titleForAccountActionMenuLabel:label]);
}

#endif /* #ifndef MEANWHILE_NOT_AVAILABLE */
@end
