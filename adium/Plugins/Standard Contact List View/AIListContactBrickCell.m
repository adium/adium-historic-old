//
//  AIListContactBrickCell.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBrickCell.h"
#import "AIListGroupMockieCell.h"

@implementation AIListContactBrickCell

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{	
//make more global? .. margins for left & right in addition to top/bottom?
	//Indent
	rect.origin.x += 2;
	rect.size.width -= 4;
	
	[super drawContentWithFrame:rect];
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	int 			row = [controlView rowForItem:listObject];
	NSColor			*labelColor = nil;
	
	//Color
	labelColor = [[[listObject displayArrayForKey:@"Label Color"] objectValue] colorWithAlphaComponent:1.0];
	if(!labelColor) labelColor = [NSColor whiteColor];
	
	[labelColor set];
	
	//Draw
	if(row >= [controlView numberOfRows]-1 || [controlView isExpandable:[controlView itemAtRow:row+1]]){
		[[NSBezierPath bezierPathWithRoundedBottomCorners:rect radius:MOCKIE_RADIUS] fill];
	}else{
		[NSBezierPath fillRect:rect];
	}
}

@end
