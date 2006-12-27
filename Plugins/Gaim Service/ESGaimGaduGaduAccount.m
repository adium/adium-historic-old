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
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Libgaim/gg.h>
#import <Libgaim/buddylist.h>

#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define MAX_GADU_STATUS_MESSAGE_LENGTH 70

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
- (BOOL)canSendOfflineMessageToContact:(AIListContact *)inContact
{
	return YES;
}

- (void)uploadContactListToServer
{
	char *buddylist = ggp_buddylist_dump(account);
		
	if (buddylist) {
		GaimConnection *gc = account->gc;
		GGPInfo *info = gc->proto_data;
		
		AILog(@"Uploading gadu-gadu list...");
		
		gg_userlist_request(info->session, GG_USERLIST_PUT, buddylist);
		g_free(buddylist);
	}
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	[super moveListObjects:objects toGroup:group];
	
	[self uploadContactListToServer];
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group
{
	[super addContacts:objects toGroup:group];	
	
	[self uploadContactListToServer];
}

- (void)removeContacts:(NSArray *)objects
{
	[super removeContacts:objects];
	
	[self uploadContactListToServer];
}

- (void)downloadContactListFromServer
{
	//If we're connected and have no buddies, request 'em from the server.
	GaimConnection *gc = account->gc;
	GGPInfo *info = gc->proto_data;
	
	AILog(@"Requesting gadu-gadu list...");
	gg_userlist_request(info->session, GG_USERLIST_GET, NULL);	
}

- (void)accountConnectionConnected
{
	[self downloadContactListFromServer];

	[super accountConnectionConnected];
}

#pragma mark Status
/*!
 * @brief Encode an attributed string for a status type
 *
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forStatusState:(AIStatus *)statusState
{
	NSString	*messageString = [[inAttributedString attributedStringByConvertingLinksToStrings] string];
	return [messageString stringWithEllipsisByTruncatingToLength:MAX_GADU_STATUS_MESSAGE_LENGTH];
}

- (BOOL)handleOfflineAsStatusChange
{
	return YES;
}

#pragma mark Contact status

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

#pragma mark Menu Actions

- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* These are dumb and should be handled automatically */
	if (strcmp(label, "Download buddylist from Server") == 0) return nil;
	if (strcmp(label, "Upload buddylist to Server") == 0) return nil;
	if (strcmp(label, "Delete buddylist from Server") == 0) return nil;

	return [super titleForAccountActionMenuLabel:label];
}

@end
