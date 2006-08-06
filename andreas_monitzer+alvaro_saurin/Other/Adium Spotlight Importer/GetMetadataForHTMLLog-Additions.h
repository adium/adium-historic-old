//
//  GetMetadataForHTMLLog-Additions.h
//  AdiumSpotlightImporter
//
//  Created by Evan Schoenberg on 5/25/06.
//

#import <Cocoa/Cocoa.h>

@interface NSString (AdiumSpotlightImporterAdditions)
- (NSString *)stringByUnescapingFromHTML;
+ (NSString *)stringWithContentsOfUTF8File:(NSString *)path;
@end

@interface NSScanner (AdiumSpotlightImporterAdditions)
- (BOOL)scanUnsignedInt:(unsigned int *)unsignedIntValue;
@end

