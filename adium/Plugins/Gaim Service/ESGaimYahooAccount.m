//
//  ESGaimYahooAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimYahooAccountViewController.h"
#import "ESGaimYahooAccount.h"

@implementation ESGaimYahooAccount

- (const char*)protocolPlugin
{
    return "prpl-yahoo";
}

//Yahoo uses 
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
                                            imagesPath:nil]);
}

@end
