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
-(NSString *)encodedStringFromAttributedString:(NSAttributedString *)inAttributedString
{
    return ([AIHTMLDecoder encodeHTML:inAttributedString
                              headers:YES
                             fontTags:YES   closeFontTags:NO
                            styleTags:YES   closeStyleTagsOnFontChange:NO
                       encodeNonASCII:NO
                           imagesPath:nil]);
}

@end
