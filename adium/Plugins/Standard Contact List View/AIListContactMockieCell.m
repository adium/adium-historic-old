//
//  AIListContactMockieCell.m
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactMockieCell.h"
#import "AIListGroupMockieCell.h"

@implementation AIListContactMockieCell

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	int		row = [controlView rowForItem:listObject];
	
	if(row >= [controlView numberOfRows]-1 || [controlView isExpandable:[controlView itemAtRow:row+1]]){
		NSColor	*labelColor = [self labelColor];
		if(labelColor){
			[labelColor set];
			[[NSBezierPath bezierPathWithRoundedBottomCorners:rect radius:MOCKIE_RADIUS] fill];
		}
	}else{
		[super drawBackgroundWithFrame:rect];
	}
}

@end
