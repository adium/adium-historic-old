//
//  AIListContactBubbleCell.h
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactCell.h"

@interface AIListContactBubbleCell : AIListContactCell {
	BOOL drewSelection;
}

- (NSRect)bubbleRectForFrame:(NSRect)rect;

@end
