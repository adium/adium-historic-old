//
//  AIRecentImage.h
//  Adium
//
//  Created by Evan Schoenberg on 10/29/07.
//

#import <Cocoa/Cocoa.h>

@interface AIRecentImage : NSObject {
	NSImage		*image;
	NSString	*path;
}

+ (AIRecentImage *)recentImageWithImage:(NSImage *)inImage path:(NSString *)inPath;
- (NSImage *)image;
- (NSString *)originalImagePath;
@end
