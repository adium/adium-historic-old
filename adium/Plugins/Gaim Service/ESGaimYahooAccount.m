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

- (NSString *)hostKey
{
	return KEY_YAHOO_HOST;
}

- (NSString *)portKey
{
	return KEY_YAHOO_PORT;
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
	
	GaimXfer *xfer = yahoo_xfer_new(gc,destsn);
	
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
