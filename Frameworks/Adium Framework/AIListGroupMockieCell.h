//
//  AIListGroupMockieCell.h
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupCell.h"

#define MOCKIE_RADIUS		6		//Radius of the rounded mockie corners

typedef enum {
	AIGroupCollapsed = 0,
	AIGroupExpanded
} AIGroupState;
#define NUMBER_OF_GROUP_STATES	2

@interface AIListGroupMockieCell : AIListGroupCell {
	NSImage		*_mockieGradient[NUMBER_OF_GROUP_STATES];
	NSSize		_mockieGradientSize[NUMBER_OF_GROUP_STATES];
}

- (id)copyWithZone:(NSZone *)zone;

@end
