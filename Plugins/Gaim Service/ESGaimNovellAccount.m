//
//  ESGaimNovellAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimNovellAccount.h"

@implementation ESGaimNovellAccount

static BOOL didInitNovell;

- (const char*)protocolPlugin
{
	[super initSSL];
	if (!didInitNovell) didInitNovell = gaim_init_novell_plugin();
    return "prpl-novell";
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError) {
		if ([disconnectionError rangeOfString:@"Invalid username or password"].location != NSNotFound) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if ([disconnectionError rangeOfString:@"you logged in at another workstation"].location != NSNotFound) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
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
#warning Novell invisible = "Appear Offline"
- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage
{
	NSString		*statusName = [statusState statusName];
	AIStatusType	statusType = [statusState statusType];
	char			*gaimStatusType = NULL;
	
	switch(statusType){
		case AIAvailableStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_AVAILABLE]){
				gaimStatusType = "Available";

				//Don't use a status message for an available state, as Novell would go Away
				*statusMessage = nil;
			}
			break;
		}
			
		case AIAwayStatusType:
		{
			if ([statusName isEqualToString:STATUS_NAME_AWAY])
				gaimStatusType = "Away";
			else if([statusName isEqualToString:STATUS_NAME_BUSY])
				gaimStatusType = "Busy";
			
			break;
		}
	}
	
	/* XXX Novell supports status messages along with Away and Busy, so let our message stay 
	 * Note that "Busy" will actually become a generic away if we have a message, but that's probably desired. */

	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

@end
