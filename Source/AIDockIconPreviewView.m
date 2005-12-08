//
//  AIDockIconPreviewView.m
//  Adium
//
//  Created by David Smith on 12/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIDockIconPreviewView.h"
#import <Adium/AIIconState.h>
#import <Adium/AIObject.h>
#import <AIUtilities/AIImageGridView.h>

@implementation AIDockIconPreviewView

- (void) setXtraPath:(NSString *)path
{
	[images autorelease];
	images = [[NSMutableArray alloc] init];
	NSArray * iconStates = [[[[AIObject sharedAdiumInstance] dockController] iconPackAtPath:path] objectForKey:@"State"];
	NSEnumerator * e = [iconStates objectEnumerator];
	AIIconState * icon;
	NSImage * image;
	while((icon = [e nextObject])) {
		image = [icon image];
		if(image) 
			[images addObject:image];
	}
	float size = 64;//[self bounds].size.width / [images count];
	[gridView setImageSize:NSMakeSize(size, size)];
#warning this is SUCH a hack
	[(NSSplitView *)[[self superview] superview] adjustSubviews];
}

@end
