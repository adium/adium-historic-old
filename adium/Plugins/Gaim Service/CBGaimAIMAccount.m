//
//  CBGaimAIMAccount.m
//  Adium
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "CBGaimOscarAccount.h"
#import "CBGaimAIMAccount.h"
#import "aim.h"

@implementation CBGaimAIMAccount

//AIM doesn't require we close our tags, so don't waste the characters
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	BOOL	noHTML = NO;
	
	//We don't want to send HTML to ICQ users, or mobile phone users
	if(inListObject){
		char	firstCharacter = [[inListObject UID] characterAtIndex:0];
	    noHTML = ((firstCharacter >= '0' && firstCharacter <= '9') || firstCharacter == '+');
	}
	
	return((noHTML ? [inAttributedString string] : [AIHTMLDecoder encodeHTML:inAttributedString
									 headers:YES
									fontTags:YES
								   closeFontTags:NO
								       styleTags:YES
						      closeStyleTagsOnFontChange:NO
								  encodeNonASCII:NO
								      imagesPath:nil]));
}

@end
