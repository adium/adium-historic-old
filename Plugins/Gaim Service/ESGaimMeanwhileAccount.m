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

#import "ESGaimMeanwhileAccount.h"
#import "AIAccountController.h"
#import "AIStatusController.h"
#import "UndeclaredLibgaimFunctions.h"
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <Libgaim/mwgaim-adium.h>

@interface ESGaimMeanwhileAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimMeanwhileAccount

#ifndef MEANWHILE_NOT_AVAILABLE

gboolean gaim_init_meanwhile_plugin(void);
- (const char*)protocolPlugin
{
	static gboolean didInitMeanwhile = NO;
	
	[self initSSL];
	if (!didInitMeanwhile) didInitMeanwhile = gaim_init_meanwhile_plugin(); 
    return "prpl-meanwhile";
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	int contactListChoice = [[self preferenceForKey:KEY_MEANWHILE_CONTACTLIST group:GROUP_ACCOUNT_STATUS] intValue];

	gaim_prefs_set_int(MW_PRPL_OPT_BLIST_ACTION, Meanwhile_CL_Load_And_Save);
}

#pragma mark Status Messages
- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)b
{
	NSString				*statusMessageString;
	NSAttributedString		*statusMessage = nil;
	const char				*statusMessageText;
	GaimConnection			*gc = b->account->gc;
	struct mwGaimPluginData	*pd = ((struct mwGaimPluginData *)(gc->proto_data));
	struct mwAwareIdBlock	t = { mwAware_USER,  b->name, NULL };
	
	statusMessageText = (const char *)mwServiceAware_getText(pd->srvc_aware, &t);
	statusMessageString = (statusMessageText ? [NSString stringWithUTF8String:statusMessageText] : nil);

	if (statusMessageString && [statusMessageString length]) {
		statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
														 attributes:nil] autorelease];
	}

	return statusMessage;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	BOOL shouldReconnect = YES;
	
	if (disconnectionError && *disconnectionError) {
		if ([*disconnectionError rangeOfString:@"Incorrect Username/Password"].location != NSNotFound) {
			[self serverReportedInvalidPassword];
		}
	}

	return shouldReconnect;
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
			if ([statusName isEqualToString:STATUS_NAME_AVAILABLE])
				gaimStatusType = "Active";
			break;
		}

		case AIAwayStatusType:
		{
			NSString	*statusMessageString = (*statusMessage ? [*statusMessage string] : @"");

			if ([statusName isEqualToString:STATUS_NAME_AWAY])
				gaimStatusType = "Away";
			else if (([statusName isEqualToString:STATUS_NAME_DND]) ||
					([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_DND] == NSOrderedSame))
				gaimStatusType = "Do Not Disturb";
			
			break;
		}
		
		case AIInvisibleStatusType:
		case AIOfflineStatusType:
			break;
	}
	
	/* XXX (?) Meanwhile supports status messages along with the status types, so let our message stay */
	
	//If we didn't get a gaim status type, request one from super
	if (gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (strcmp(label, "Set Active Message...") == 0) {
		return nil;

	} else if (strcmp(label, "Set Status Messages...") == 0) {
		return nil;

	} else if (strcmp(label, "Import Sametime List...") == 0) {
		return AILocalizedString(@"Import Sametime List...",nil);

	} else if (strcmp(label, "Export Sametime List...") == 0) {
		return AILocalizedString(@"Export Sametime List...",nil);
	}

	return [super titleForAccountActionMenuLabel:label];
}

#pragma mark File transfer
- (BOOL)canSendFolders
{
	return NO;
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)) {
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
		
		return mwgaim_xfer_new(account->gc,destsn);
	}
	
	return nil;
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

#endif /* #ifndef MEANWHILE_NOT_AVAILABLE */
@end
