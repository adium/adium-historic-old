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
#import "AIContactController.h"
#import "AIStatusController.h"
#import "CBGaimOscarAccount.h"
#import "SLGaimCocoaAdapter.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/CBObjectAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>

@implementation CBGaimOscarAccount

- (const char*)protocolPlugin
{
	static BOOL didInitOscar = NO;
	if (!didInitOscar){
		didInitOscar = gaim_init_oscar_plugin();
		if (!didInitOscar) NSLog(@"CBGaimOscarAccount: Oscar plugin failed to load.");
	}
	
    return "prpl-oscar";
}

#pragma mark AIListContact and AIService special cases for OSCAR
//Override contactWithUID to mark mobile and ICQ users as such via the displayServiceID
- (AIListContact *)contactWithUID:(NSString *)sourceUID
{
	AIListContact	*contact;
	
	if (!namesAreCaseSensitive){
		sourceUID = [sourceUID compactedString];
	}
	
	contact = [[adium contactController] existingContactWithService:service
															account:self
																UID:sourceUID];
	if(!contact){
		contact = [[adium contactController] contactWithService:[self _serviceForUID:sourceUID]
														account:self
															UID:sourceUID];
	}
	
	return(contact);
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	AIService	*contactService;
	NSString	*contactServiceID = nil;
	
	const char	firstCharacter = ([contactUID length] ? [contactUID characterAtIndex:0] : '\0');

	//Determine service based on UID
	if([contactUID hasSuffix:@"@mac.com"]){
		contactServiceID = @"libgaim-oscar-Mac";
	}else if(firstCharacter && (firstCharacter >= '0' && firstCharacter <= '9')){
		contactServiceID = @"libgaim-oscar-ICQ";
	//		}else if(isMobile = (firstCharacter == '+')){
	//			contactServiceID = @"libgaim-oscar-AIM";
	}else{
		contactServiceID = @"libgaim-oscar-AIM";
	}

	contactService = [[adium accountController] serviceWithUniqueID:contactServiceID];

	return(contactService);
}
	
#pragma mark Account Connection

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;

	if (disconnectionError) {
		if ([disconnectionError rangeOfString:@"Incorrect nickname or password."].location != NSNotFound) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if ([disconnectionError rangeOfString:@"signed on with this screen name at another location"].location != NSNotFound) {
			shouldAttemptReconnect = NO;
		}else if ([disconnectionError rangeOfString:@"too frequently"].location != NSNotFound) {
			shouldAttemptReconnect = NO;	
		}
	}
	
	return shouldAttemptReconnect;
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Screen name sent",nil);
			break;
		case 2:
			return AILocalizedString(@"Password sent",nil);
			break;			
		case 3:
			return AILocalizedString(@"Received authorization",nil);
			break;
		case 4:
			return AILocalizedString(@"Connection established",nil);
			break;
		case 5:
			return AILocalizedString(@"Finalizing connection",nil);
			break;
	}

	return nil;
}

- (oneway void)updateUserInfo:(AIListContact *)theContact withData:(NSString *)userInfoString
{
	//For AIM contacts, we get profiles by themselves and don't want this userInfo with all its fields, so
	//we override this method to prevent the information from reaching the rest of Adium.
	
	//For ICQ contacts, however, we want to pass this data on as the profile
	const char	firstCharacter = [[theContact UID] characterAtIndex:0];
	
	if((firstCharacter >= '0' && firstCharacter <= '9') || [theContact isStranger]){
		[super updateUserInfo:theContact withData:userInfoString];
	}
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)){
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];

		return oscar_xfer_new(account->gc,destsn);
	}
	
	return nil;
}

#pragma mark Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type
{
    return [super addListObject:inObject toPrivacyList:type];
}
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type
{
    return [super removeListObject:inObject fromPrivacyList:type]; 
}

@end

#pragma mark Coding Notes

/*if (isdigit(b->name[0])) {
char *status;
status = gaim_icq_status((b->uc & 0xffff0000) >> 16);
tmp = ret;
ret = g_strconcat(tmp, _("<b>Status:</b> "), status, "\n", NULL);
g_free(tmp);
g_free(status);
}

if ((bi != NULL) && (bi->ipaddr)) {
    char *tstr =  g_strdup_printf("%hhd.%hhd.%hhd.%hhd",
                                  (bi->ipaddr & 0xff000000) >> 24,
                                  (bi->ipaddr & 0x00ff0000) >> 16,
                                  (bi->ipaddr & 0x0000ff00) >> 8,
                                  (bi->ipaddr & 0x000000ff));
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>IP Address:</b> "), tstr, "\n", NULL);
    g_free(tmp);
    g_free(tstr);
}

if ((userinfo != NULL) && (userinfo->capabilities)) {
    char *caps = caps_string(userinfo->capabilities);
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>Capabilities:</b> "), caps, "\n", NULL);
    g_free(tmp);
}

static void oscar_ask_direct_im(GaimBlistNode *node, gpointer ignored);

*/

#if 0
//**Adium
GaimXfer *oscar_xfer_new(GaimConnection *gc, const char *destsn) {
	OscarData *od = (OscarData *)gc->proto_data;
	GaimXfer *xfer;
	struct aim_oft_info *oft_info;
	
	/* You want to send a file to someone else, you're so generous */
	
	/* Build the file transfer handle */
	xfer = gaim_xfer_new(gaim_connection_get_account(gc), GAIM_XFER_SEND, destsn);
	xfer->local_port = 5190;
	
	/* Create the oscar-specific data */
	oft_info = aim_oft_createinfo(od->sess, NULL, destsn, xfer->local_ip, xfer->local_port, 0, 0, NULL);
	xfer->data = oft_info;
	
	/* Setup our I/O op functions */
	gaim_xfer_set_init_fnc(xfer, oscar_xfer_init);
	gaim_xfer_set_start_fnc(xfer, oscar_xfer_start);
	gaim_xfer_set_end_fnc(xfer, oscar_xfer_end);
	gaim_xfer_set_cancel_send_fnc(xfer, oscar_xfer_cancel_send);
	gaim_xfer_set_cancel_recv_fnc(xfer, oscar_xfer_cancel_recv);
	gaim_xfer_set_ack_fnc(xfer, oscar_xfer_ack);
	
	/* Keep track of this transfer for later */
	od->file_transfers = g_slist_append(od->file_transfers, xfer);
	
	return xfer;
}
#endif
