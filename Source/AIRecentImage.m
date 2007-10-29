//
//  AIRecentImage.m
//  Adium
//
//  Created by Evan Schoenberg on 10/29/07.
//

#import "AIRecentImage.h"

@interface AIRecentImage (PRIVATE)
- (id)initWithImage:(NSImage *)inImage path:(NSString *)inPath;
@end

@implementation AIRecentImage

+ (AIRecentImage *)recentImageWithImage:(NSImage *)inImage path:(NSString *)inPath
{
	return [[[self alloc] initWithImage:inImage path:inPath] autorelease];
}

- (id)initWithImage:(NSImage *)inImage path:(NSString *)inPath
{
	if ((self = [super init])) {
		image = [inImage retain];
		path = [inPath retain];
	}
	
	return self;
}

- (NSImage *)image
{
	return image;
}

- (NSString *)originalImagePath
{
	return path;
}

- (void)dealloc
{
	[image release];
	[path release];

	[super dealloc];
}
@end
