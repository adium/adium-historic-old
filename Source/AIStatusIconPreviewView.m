//
//  AIStatusIconPreviewView.m
//  Adium
//
//  Created by David Smith on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIStatusIconPreviewView.h"

@implementation AIStatusIconPreviewView

- (void) setXtra:(AIXtraInfo *)xtraInfo
{
	[images autorelease];
	images = [[NSMutableArray alloc] init];
	NSEnumerator * paths;
	NSString * resourcePath = [xtraInfo resourcePath];
	NSFileManager * manager = [NSFileManager defaultManager];
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
