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
			break;
			
		case AIAwayStatusType:
			if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
				([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BUSY] == NSOrderedSame))
				statusID = "busy";
			break;

		case AIInvisibleStatusType:
			statusID = "appearoffline";
			break;

		case AIOfflineStatusType:
			break;
	}

	//If we didn't get a gaim status ID, request one from super
	if (statusID == NULL) statusID = [super gaimStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

@end
