//
//  AIImageGridXtraPreviewView.m
//  Adium
//
//  Created by David Smith on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIImageGridXtraPreviewView.h"
#import <AIUtilities/AIImageGridView.h>

@implementation AIImageGridXtraPreviewView

- (id) initWithFrame:(NSRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		images = [[NSMutableArray alloc] init];
		gridView = [[[AIImageGridView alloc] initWithFrame:[self bounds]]autorelease];
		[gridView setDelegate:self];
		[gridView setDrawsBackground:NO];
		[self addSubview:gridView];
	}
	return self;
}

- (int)numberOfImagesInImageGridView:(AIImageGridView *)imageGridView
{
	return [images count];
}

- (NSImage *)imageGridView:(AIImageGridView *)imageGridView imageAtIndex:(int)index
{
	return [images objectAtIndex:index];
}

- (BOOL)imageGridView:(AIImageGridView *)imageGridView shouldSelectIndex:(int)index
{
	return NO;
}

- (BOOL)isFlipped
{
	return YES;
}

@end
