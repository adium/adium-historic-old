//
//  AIStandardListOutlineView.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIStandardListOutlineView.h"


@implementation AIStandardListOutlineView

//- (void)viewWillMoveToSuperview:(NSView *)newSuperview
//{
//	[super viewWillMoveToSuperview:newSuperview];
//	
//	[(NSClipView *)newSuperview setCopiesOnScroll:NO];
//}
//
////Elisha! :)
//- (void)drawBackgroundInClipRect:(NSRect)clipRect
//{
//	static NSImage *image = nil;
//	NSRect visRect = [[self enclosingScrollView] documentVisibleRect];
//
//	[super drawBackgroundInClipRect:clipRect];
//	
//	//Draw Elisha
//	if(!image) image = [[NSImage imageNamed:@"elisha" forClass:[self class]] retain];
//	[image setFlipped:YES];
//	[image drawInRect:NSMakeRect(visRect.origin.x,visRect.origin.y,[image size].width, [image size].height)
//			 fromRect:NSMakeRect(0,0,[image size].width, [image size].height)
//			operation:NSCompositeCopy
//			 fraction:1.0];
//	[image setFlipped:NO];
//	
//}


@end
