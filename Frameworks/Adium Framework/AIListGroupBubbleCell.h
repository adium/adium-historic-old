//
//  AIListGroupBubbleCell.h
//  Adium
//
//  Created by Adam Iser on 8/12/04.
//

#import "AIListGroupCell.h"

@interface AIListGroupBubbleCell : AIListGroupCell {
	BOOL			outlineBubble;
	BOOL			drawBubble;
	
	float			outlineBubbleLineWidth;
}

- (NSRect)bubbleRectForFrame:(NSRect)rect;
- (void)setOutlineBubble:(BOOL)flag;
- (void)setOutlineBubbleLineWidth:(float)inWidth;

//This is the inverse of drawBubble so a default of NO will draw the bubble
- (void)setHideBubble:(BOOL)flag;

@end
