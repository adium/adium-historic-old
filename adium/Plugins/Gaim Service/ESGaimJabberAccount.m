//
//  ESGaimJabberAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimJabberAccountViewController.h"
#import "ESGaimJabberAccount.h"

#define KEY_JABBER_HOST @"Jabber:Host"
#define KEY_JABBER_PORT @"Jabber:Port"

@implementation ESGaimJabberAccount

- (const char*)protocolPlugin
{
    return "prpl-jabber";
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
    xfer->ui_data = fileTransfer;
	
    //accept the request
    gaim_xfer_request_accepted(xfer, filename);
    
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