//
//  AIListContactBubbleCell.h
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//

#import "AIListContactCell.h"

@interface AIListContactBubbleCell : AIListContactCell {
	NSBezierPath	*lastBackgroundBezierPath;
}

- (NSRect)bubbleRectForFrame:(NSRect)rect;

@end
