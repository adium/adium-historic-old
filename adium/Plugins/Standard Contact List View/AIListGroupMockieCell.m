//
//  AIListGroupMockieCell.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupMockieCell.h"

@implementation AIListGroupMockieCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
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
