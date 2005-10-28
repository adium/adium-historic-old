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
#import "ESGaimNovellAccount.h"
#import <Adium/AIStatus.h>

@implementation ESGaimNovellAccount

gboolean gaim_init_novell_plugin(void);
- (const char*)protocolPlugin
{
	static gboolean didInitNovell = NO;

	[self initSSL];
	if (!didInitNovell) didInitNovell = gaim_init_novell_plugin();
    return "prpl-novell";
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError && *disconnectionError) {
		if ([*disconnectionError rangeOfString:@"Invalid username or password"].location != NSNotFound) {
			[self serverReportedInvalidPassword];
		} else if ([*disconnectionError rangeOfString:@"you logged in at another workstation"].location != NSNotFound) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
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
	
	switch (statusType) {
		case AIAvailableStatusType:
		{
			if ([statusName isEqualToString:STATUS_NAME_AVAILABLE]) {
				gaimStatusType = "Available";

				//Don't use a status message for an available state, as Novell would go Away
				*statusMessage = nil;
			}
			break;
		}
			
		case AIAwayStatusType:
		{
			NSString	*statusMessageString = (*statusMessage ? [*statusMessage string] : @"");

			if ([statusName isEqualToString:STATUS_NAME_AWAY])
				gaimStatusType = "Away";
			else if ([statusName isEqualToString:STATUS_NAME_BUSY])
				gaimStatusType = "Busy";
			
			//With a status message of "Busy" we should ensure we actually go to the Busy state, not the generic away
			//with a message of Busy.
			if ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BUSY] == NSOrderedSame) {
				gaimStatusType = "Busy";
				*statusMessage = nil;
			}
			
			break;
		}
			
		case AIInvisibleStatusType:
			gaimStatusType = "Appear Offline";
		
		case AIOfflineStatusType:
			break;
	}
	
	/* XXX Novell supports status messages along with Away and Busy, so let our message stay 
	 * Note that "Busy" will actually become a generic away if we have a message, but that's probably desired. */

	//If we didn't get a gaim status type, request one from super
	if (gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

@end
