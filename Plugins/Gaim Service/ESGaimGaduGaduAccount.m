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

#import "ESGaimGaduGaduAccountViewController.h"
#import "ESGaimGaduGaduAccount.h"
#import "AIStatusController.h"
#import "AIAccountController.h"
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>

#define AGG_STATUS_AVAIL              "Available"
#define AGG_STATUS_AVAIL_FRIENDS      "Available for friends only"
#define AGG_STATUS_BUSY               "Away"
#define AGG_STATUS_BUSY_FRIENDS       "Away for friends only"
#define AGG_STATUS_INVISIBLE          "Invisible"
#define AGG_STATUS_INVISIBLE_FRIENDS  "Invisible for friends only"
#define AGG_STATUS_NOT_AVAIL          "Unavailable"

@interface ESGaimGaduGaduAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimGaduGaduAccount

gboolean gaim_init_gg_plugin(void);
- (const char*)protocolPlugin
{
	static BOOL didInitGG = NO;
	if (!didInitGG) didInitGG = gaim_init_gg_plugin();
    return "prpl-gg";
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Looking up server",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data","Connection step");
			break;			
		case 3:
			return AILocalizedString(@"Balancer handshake","Connection step");
			break;
		case 4:
			return AILocalizedString(@"Reading server key","Connection step");
			break;
		case 5:
			return AILocalizedString(@"Exchanging key hash","Connection step");
			break;
	}
	return nil;
}

- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];	

	GaimAccount		*gaimAccount = [self gaimAccount];
	GaimConnection  *gc;
	
	if ((gc = gaim_account_get_connection(gaimAccount))) {
		gg_userlist_request(((struct agg_data *)gc->proto_data)->sess, GG_USERLIST_GET, NULL);
	}
}

#pragma mark Contact status

- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)b
{
	NSAttributedString  *statusMessage = nil;
	
	if (b && b->proto_data) {
		NSString	*statusMessageString = [NSString stringWithUTF8String:b->proto_data];
		if (statusMessageString && [statusMessageString length]) {
			statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
															 attributes:nil] autorelease];
		}
	}   
	
	return statusMessage;
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
			if ([statusName isEqualToString:STATUS_NAME_AVAILABLE])
				gaimStatusType = AGG_STATUS_AVAIL;
			else if ([statusName isEqualToString:STATUS_NAME_AVAILABLE_FRIENDS_ONLY])
				gaimStatusType = AGG_STATUS_AVAIL_FRIENDS;
			break;
		}
			
		case AIAwayStatusType:
		{
			if ([statusName isEqualToString:STATUS_NAME_AWAY])
				gaimStatusType = AGG_STATUS_BUSY;
			else if ([statusName isEqualToString:STATUS_NAME_AWAY_FRIENDS_ONLY])
				gaimStatusType = AGG_STATUS_BUSY_FRIENDS;
			else if ([statusName isEqualToString:STATUS_NAME_NOT_AVAILABLE])
				gaimStatusType = AGG_STATUS_NOT_AVAIL;
			
			break;
		}
			
		case AIInvisibleStatusType:
			gaimStatusType = AGG_STATUS_INVISIBLE;
			break;
		
		case AIOfflineStatusType:
			break;
	}

	/* Gadu-Gadu supports status messages along with the status types, so let our message stay */
	
	//If we didn't get a gaim status type, request one from super
	if (gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError && *disconnectionError) {
		if ([*disconnectionError rangeOfString:@"Authentication failed"].location != NSNotFound) {
			[self serverReportedInvalidPassword];
		}
	}
	
	return shouldAttemptReconnect;
}		
@end
