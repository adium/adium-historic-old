//
//  SHMozillaCommonParser.h
//  Adium
//
//  Created by Stephen Holt on Sat Jun 05 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface SHMozillaCommonParser : NSObject {
}

+ (NSArray *)parseBookmarksfromString:(NSString *)inString;
+ (NSString *)simplyReplaceHTMLCodes:(NSString *)inString;
@end
