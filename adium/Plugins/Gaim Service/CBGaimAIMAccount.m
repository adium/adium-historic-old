//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "AIGaimAIMAccountViewController.h"
#import "CBGaimAIMAccount.h"
#import "aim.h"

@implementation CBGaimAIMAccount

- (id <AIAccountViewController>)accountView
{
    return([AIGaimAIMAccountViewController accountViewForAccount:self]);
}

//AIM doesn't require we close our tags, so don't waste the characters
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	BOOL	isICQ = NO;
	
	if(inListObject){
		char	firstCharacter = [[inListObject UID] characterAtIndex:0];
		isICQ = (firstCharacter >= '0' && firstCharacter <= '9');
	}
	
    return((isICQ ? [inAttributedString string] : [AIHTMLDecoder encodeHTML:inAttributedString
																	headers:YES
																   fontTags:YES
															  closeFontTags:NO
																  styleTags:YES
												 closeStyleTagsOnFontChange:NO
															 encodeNonASCII:YES
																 imagesPath:nil]));
}

@end
