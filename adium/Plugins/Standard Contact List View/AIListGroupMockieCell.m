//
//  AIListGroupMockieCell.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupMockieCell.h"

#define MOCKIE_GROUP_TOP_PADDING		2
#define MOCKIE_GROUP_BOTTOM_PADDING		0

@implementation AIListGroupMockieCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListGroupMockieCell	*newCell = [[AIListGroupMockieCell alloc] init];
	[newCell setListObject:listObject];
	return(newCell);
}

- (int)topPadding
{
	return(MOCKIE_GROUP_TOP_PADDING);
}

- (int)bottomPadding
{
	return(MOCKIE_GROUP_BOTTOM_PADDING);
}

//Draw a gradient behind our group
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSBezierPath 	*path;
	
	if([controlView isItemExpanded:listObject]){
		path = [NSBezierPath bezierPathWithRoundedTopCorners:rect radius:MOCKIE_RADIUS];
	}else{
		path = [NSBezierPath bezierPathWithRoundedRect:rect radius:MOCKIE_RADIUS];
	}
	
	[[self backgroundGradient] drawInBezierPath:path];
}


@end
