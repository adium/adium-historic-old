//
//  ESGaimJabberAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimJabberAccountViewController.h"
#import "ESGaimJabberAccount.h"

#import <Libgaim/si.h>

@implementation ESGaimJabberAccount

- (const char*)protocolPlugin
{
    return "prpl-jabber";
}

- (void)initAccount
{
	[super initAccount];
}
- (void)dealloc
{
	[super dealloc];
}

- (void)createNewGaimAccount
{
	NSString	*connectServer, *resource, *server, *userNameWithHost = nil, *completeUserName = nil;
	BOOL		forceOldSSL, useTLS, allowPlaintext, serverAppended, resourceAppended;
	
	[super createNewGaimAccount];
	
	//'Connect via' server (nil by default)
	connectServer = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	if (connectServer){
		gaim_account_set_string(account, "connect_server", [connectServer UTF8String]);
	}
	
	//Force old SSL usage? (off by default)
	forceOldSSL = [[self preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "old_ssl", forceOldSSL);

	//Allow TLS useage? (on by default)
	useTLS = [[self preferenceForKey:KEY_JABBER_USE_TLS group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "use_tls", useTLS);

	//Allow plaintext authorization over an unencrypted connection? Gaim will prompt if this is NO and is needed.
	allowPlaintext = [[self preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "auth_plain_in_clear", allowPlaintext);
		
	//Gaim stores the username in the format username@server/resource.  We need to pass it a username in this format
	//createNewGaimAccount gets called on every connect, so we need to make sure we don't append the information more
	//than once.  Also, if the user puts the uesrname in username@server format, which is common for Jabber, we should
	//handle this gracefully, ignoring the server preference entirely.

	serverAppended = ([UID rangeOfString:@"@"].location != NSNotFound);

	if (!serverAppended){
		server = [self host];
		userNameWithHost = [NSString stringWithFormat:@"%@@%@",UID,server];
		[UID release]; UID = [userNameWithHost retain];
	}
	
	resourceAppended = ([UID rangeOfString:@"/"].location != NSNotFound);
	if (!resourceAppended){
		resource = [self preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
		completeUserName = [NSString stringWithFormat:@"%@/%@",UID,resource];
	}
	
	gaim_account_set_username(account, [UID UTF8String]);
}

- (NSString *)unknownGroupName {
    return (AILocalizedString(@"Roster","Roster - the Jabber default group"));
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data",nil);
			break;			
		case 3:
			return AILocalizedString(@"Authenticating",nil);
			break;
		case 5:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 6:
			return AILocalizedString(@"Authenticating",nil);
			break;
	}
	return nil;
}

- (NSString *)hostKey
{
	return KEY_JABBER_HOST;
}

- (NSString *)portKey
{
	return KEY_JABBER_PORT;
}


#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
	
	GaimXfer *xfer = jabber_outgoing_xfer_new(gc,destsn);

	//gaim will free filename when necessary
	char *filename = g_strdup([[fileTransfer localFilename] UTF8String]);
	
	//Associate the fileTransfer and the xfer with each other
	[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
    xfer->ui_data = [fileTransfer retain];
	
	//Set the filename
	gaim_xfer_set_local_filename(xfer, [[fileTransfer localFilename] UTF8String]);
	
    //request that the transfer begins
	gaim_xfer_request(xfer);
    
	//tell the fileTransferController to display appropriately
    [[adium fileTransferController] beganFileTransfer:fileTransfer];
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}


@end