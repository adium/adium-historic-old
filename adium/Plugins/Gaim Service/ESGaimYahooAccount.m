//
//  ESGaimYahooAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimYahooAccountViewController.h"
#import "ESGaimYahooAccount.h"

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

@end
