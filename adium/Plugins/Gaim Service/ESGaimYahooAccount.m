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

static BOOL didInitYahoo = NO;

- (const char*)protocolPlugin
{
	if (!didInitYahoo) didInitYahoo = gaim_init_yahoo_plugin();
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
	if (disconnectionError && ([disconnectionError rangeOfString:@"Incorrect password"].location != NSNotFound)) {
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
	/*return ([AIHTMLDecoder encodeHTML:inAttributedString
							  headers:NO
							 fontTags:NO
				   includingColorTags:NO
						closeFontTags:NO
							styleTags:NO
		   closeStyleTagsOnFontChange:NO
					   encodeNonASCII:NO
						   imagesPath:nil
					attachmentsAsText:YES
						   simpleTagsOnly:YES]);*/
	
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
						  simpleTagsOnly:YES]);
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
	
	return yahoo_xfer_new(gc,destsn);
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
