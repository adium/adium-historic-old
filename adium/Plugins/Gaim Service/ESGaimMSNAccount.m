//
//  ESGaimMSNAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimMSNAccount.h"

#define KEY_MSN_HOST	@"MSN:Host"
#define KEY_MSN_PORT	@"MSN:Port"

@interface ESGaimMSNAccount (PRIVATE)
-(void)_setFriendlyNameTo:(NSString *)inAlias;
@end

@implementation ESGaimMSNAccount

static BOOL didInitMSN = NO;

- (void)initAccount
{
	[super initAccount];
	currentFriendlyName = nil;
}

- (const char*)protocolPlugin
{
	[super initSSL];
	if (!didInitMSN) didInitMSN = gaim_init_msn_plugin();
    return "prpl-msn";
}

#pragma mark Connection
- (void)createNewGaimAccount
{
	[super createNewGaimAccount];
	
	BOOL HTTPConnect = [[self preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "http_method", HTTPConnect);
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 2:
			return AILocalizedString(@"Syncing with server",nil);
			break;			
		case 3:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 4:
			return AILocalizedString(@"Syncing with server",nil);
			break;
		case 5:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 6:
			return AILocalizedString(@"Password sent",nil);
			break;
		case 7:
			return AILocalizedString(@"Retrieving buddy list",nil);
			break;
			
	}
	return nil;
}

- (NSString *)hostKey
{
	return KEY_MSN_HOST;
}
- (NSString *)portKey
{
	return KEY_MSN_PORT;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError){
		if (([disconnectionError rangeOfString:@"Type your e-mail address and password correctly"].location != NSNotFound)) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if (([disconnectionError rangeOfString:@"You have signed on from another location"].location != NSNotFound)) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return([AIHTMLDecoder encodeHTML:inAttributedString
							 headers:NO
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:NO
						  imagesPath:nil
				   attachmentsAsText:YES
	  attachmentImagesOnlyForSending:NO
					  simpleTagsOnly:YES]);
}

#pragma mark Status
//Update our full name on connect
- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];
	[self updateStatusForKey:@"FullNameAttr"];
}	

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	[super updateStatusForKey:key];
	
    //Now look at keys which only make sense while online
	if([[self statusObjectForKey:@"Online"] boolValue]){

		if([key isEqualToString:@"FullNameAttr"]){
			
			NSString	*friendlyName = [[self autoRefreshingOutgoingContentForStatusKey:key] string];
			
			if (!friendlyName || ![friendlyName isEqualToString:currentFriendlyName]){
				[self _setFriendlyNameTo:friendlyName];
			}
		}
	}
}

-(void)_setFriendlyNameTo:(NSString *)inAlias
{
 	if (gaim_account_is_connected(account)){
		if (GAIM_DEBUG) NSLog(@"Updating FullNameAttr to %@",inAlias);

 		msn_set_friendly_name(account->gc, [inAlias UTF8String]);
		[currentFriendlyName release]; currentFriendlyName = [inAlias retain];
	}
}

- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
	[super delayedUpdateContactStatus:inContact];
	
	if ([[inContact numberStatusObjectForKey:@"Online"] boolValue]){
		[[super gaimThread] MSNRequestBuddyIconFor:[inContact UID] onAccount:self];
	}
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)){
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
		
		return msn_xfer_new(account->gc,destsn);
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



/*
 //Added to msn.c
//**ADIUM
void msn_set_friendly_name(GaimConnection *gc, const char *entry)
{
	msn_act_id(gc, entry);
}

GaimXfer *msn_xfer_new(GaimConnection *gc, char *who)
{
	session = gc->proto_data;
	
	xfer = gaim_xfer_new(gc->account, GAIM_XFER_SEND, who);
	
	slplink = msn_session_get_slplink(session, who);
	
	xfer->data = slplink;
	
	gaim_xfer_set_init_fnc(xfer, t_msn_xfer_init);
	
	return xfer;
}
*/
 
@end

