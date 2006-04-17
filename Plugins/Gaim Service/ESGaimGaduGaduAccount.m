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

@interface ESGaimGaduGaduAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimGaduGaduAccount

- (const char*)protocolPlugin
{
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

/*!
 * @brief Supports offline messaging?
 *
 * Gadu-Gadu supports offline messaging.
 */
- (BOOL)supportsOfflineMessaging
{
	return YES;
}

/*
- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];	

	GaimAccount		*gaimAccount = [self gaimAccount];
	GaimConnection  *gc;

	//We need to do this if we don't cache the gadu-gadu list, which gaim does by default
	if ((gc = gaim_account_get_connection(gaimAccount))) {
		gg_userlist_request(((struct agg_data *)gc->proto_data)->sess, GG_USERLIST_GET, NULL);
	}
}
*/

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
