//
//  AIListContactBubbleCell.h
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIListContactCell.h"

@interface AIListContactBubbleCell : AIListContactCell {
	NSBezierPath	*lastBackgroundBezierPath;
	BOOL			outlineBubble;
	BOOL			drawWithGradient;
	float			outlineBubbleLineWidth;
}

- (NSRect)bubbleRectForFrame:(NSRect)rect;

- (void)setOutlineBubble:(BOOL)flag;
- (void)setOutlineBubbleLineWidth:(float)inWidth;

- (void)setDrawWithGradient:(BOOL)flag;

@end
