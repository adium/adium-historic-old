//
//  SHMozillaCommonParser.h
//  Adium
//
//  Created by Stephen Holt on Sat Jun 05 2004.

@interface SHMozillaCommonParser : NSObject {
}

+ (NSArray *)parseBookmarksfromString:(NSString *)inString;
+ (NSString *)simplyReplaceHTMLCodes:(NSString *)inString;
@end
