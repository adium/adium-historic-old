//
//  SHMozillaCommonParser.h
//  Adium
//
//  Created by Stephen Holt on Sat Jun 05 2004.

@interface SHMozillaCommonParser : NSObject {
}

+ (void)parseBookmarksfromString:(NSString *)inString forOwner:(id)owner andMenu:(NSMenu *)BookmarksMenu;
@end
