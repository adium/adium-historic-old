//
//  ESGaimYahooAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimYahooAccountViewController.h"
#import "ESGaimYahooAccount.h"

#import <Libgaim/yahoo_filexfer.h>

#define KEY_YAHOO_HOST  @"Yahoo:Host"
#define KEY_YAHOO_PORT  @"Yahoo:Port"

@implementation ESGaimYahooAccount

- (const char*)protocolPlugin
{
    return "prpl-yahoo";
}

#pragma mark Connection
- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
	}
	return nil;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	if (([disconnectionError rangeOfString:@"Incorrect password"].location != NSNotFound)) {
		[[adium accountController] forgetPasswordForAccount:self];
	}
		
	return YES;
}

- (NSString *)hostKey
{
	return KEY_YAHOO_HOST;
}

- (NSString *)portKey
{
	return KEY_YAHOO_PORT;
}

#pragma mark Encoding
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
    //gaim's yahoo_html_to_codes seems to be messed up...
	return ([AIHTMLDecoder encodeHTML:inAttributedString
							  headers:NO
							 fontTags:NO
						closeFontTags:NO
							styleTags:NO
		   closeStyleTagsOnFontChange:NO
					   encodeNonASCII:NO
						   imagesPath:nil
					attachmentsAsText:YES]);
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
	
	GaimXfer *xfer = yahoo_xfer_new(gc,destsn);
	
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
