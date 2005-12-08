//
//  AIStatusIconPreviewView.m
//  Adium
//
//  Created by David Smith on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIStatusIconPreviewView.h"

@implementation AIStatusIconPreviewView

- (void) setXtraPath:(NSString *)path
{
	[images autorelease];
	images = [[NSMutableArray alloc] init];
	NSBundle * bundle = [NSBundle bundleWithPath:path];
	NSEnumerator * paths;
	NSString * resourcePath = [bundle resourcePath];
	NSFileManager * manager = [NSFileManager defaultManager];
	if(!bundle)
		paths =	[[manager directoryContentsAtPath:path] objectEnumerator];
	else
		paths = [[manager directoryContentsAtPath:resourcePath] objectEnumerator];
	
	NSImage * image;
	NSString * imageName;
	NSString * imagePath;
	while((imageName = [paths nextObject]))
	{	
		imagePath = [resourcePath stringByAppendingPathComponent:imageName];
		if([[imagePath pathExtension] isEqualToString:@"icns"]) continue; //skip the xtra icon
		image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
		if(image)
			[images addObject:image];
	}
	[gridView setImageSize:NSMakeSize(32, 32)];
#warning this is SUCH a hack
	[(NSSplitView *)[[self superview] superview] adjustSubviews];
}

@end
