//
//  ESGaimMeanwhileAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimMeanwhileAccount.h"

@interface ESGaimMeanwhileAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimMeanwhileAccount

#ifndef MEANWHILE_NOT_AVAILABLE

static BOOL didInitMeanwhile = NO;

- (const char*)protocolPlugin
{
	[super initSSL];
	if (!didInitMeanwhile) didInitMeanwhile = gaim_init_meanwhile_plugin(); 
    return "prpl-meanwhile";
}

- (NSString *)hostKey
{
	return KEY_MEANWHILE_HOST;
}

- (NSString *)portKey
{
	return KEY_MEANWHILE_PORT;
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	int contactListChoice = [[self preferenceForKey:KEY_MEANWHILE_CONTACTLIST group:GROUP_ACCOUNT_STATUS] intValue];

	gaim_prefs_set_int(MW_PRPL_OPT_BLIST_ACTION, contactListChoice);
}

//Away and away return
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data
{
	[super updateWentAway:theContact withData:data];
	[theContact setStatusObject:[self statusMessageForContact:theContact]
						 forKey:@"StatusMessage"
						 notify:YES];
}

- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data
{
	[super updateAwayReturn:theContact withData:data];
	
	[theContact setStatusObject:[self statusMessageForContact:theContact]
						 forKey:@"StatusMessage"
						 notify:YES];
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
	NSAttributedString	*newStatusMessage = [self statusMessageForContact:theContact];
	NSAttributedString	*oldStatusMessage = [theContact statusObjectForKey:@"StatusMessage"];

	if(!oldStatusMessage || ![[newStatusMessage string] isEqualToString:[oldStatusMessage string]]){
		[theContact setStatusObject:newStatusMessage
							 forKey:@"StatusMessage"
							 notify:YES];
	}
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
	
	return statusMessage;
}

#pragma mark Status
/*
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
			if ([statusName isEqualToString:STATUS_NAME_AWAY])
				gaimStatusType = "Away";
			else if([statusName isEqualToString:STATUS_NAME_DND])
				gaimStatusType = "Do Not Disturb";
			
			break;
		}
	}
	
	/* XXX (?) Meanwhile supports status messages along with the status types, so let our message stay */
	
	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

#endif
@end
