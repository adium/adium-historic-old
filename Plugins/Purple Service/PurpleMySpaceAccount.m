//
//  PurpleMySpaceAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 9/11/07.
//

#import "PurpleMySpaceAccount.h"
#import <Adium/AIHTMLDecoder.h>

@implementation PurpleMySpaceAccount

- (const char*)protocolPlugin
{
    return "prpl-myspace";
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step) {
	case 0:
		return AILocalizedString(@"Connecting",nil);
		break;
	case 1:
		return AILocalizedString(@"Reading challenge",nil);
		break;
	case 2:
		return AILocalizedString(@"Logging in","Connection step");
		break;			
	case 3:
		return AILocalizedString(@"Connected","Connection step");
		break;
	}

	return nil;
}
	
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [AIHTMLDecoder encodeHTML:inAttributedString
							 headers:YES
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:YES
						encodeSpaces:NO
						  imagesPath:nil
				   attachmentsAsText:YES
		   onlyIncludeOutgoingImages:NO
					  simpleTagsOnly:NO
					  bodyBackground:NO
				 allowJavascriptURLs:YES];
}

@end
