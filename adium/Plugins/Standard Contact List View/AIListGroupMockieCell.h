//
//  AIListGroupMockieCell.h
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupGradientCell.h"

#define MOCKIE_RADIUS		6		//Radius of the rounded mockie corners

@interface AIListGroupMockieCell : AIListGroupGradientCell {
	NSImage		*_groupGradient;
	NSImage		*_groupExpandedGradient;
	NSSize		_groupGradientSize;
	NSSize		_groupExpandedGradientSize;
}

- (id)copyWithZone:(NSZone *)zone;
- (void)drawBackgroundWithFrame:(NSRect)rect;

@end
