//
//  AIListGroupCell.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListCell.h"

@interface AIListGroupCell : AIListCell {
	NSColor		*shadowColor;
	NSColor		*backgroundColor;
	NSColor		*gradientColor;
	BOOL		drawsBackground;
	
	NSImage		*_gradient;
	NSSize		_gradientSize;
}

- (int)flippyIndent;
- (void)setShadowColor:(NSColor *)inColor;
- (NSColor *)shadowColor;
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor;
- (void)setDrawsBackground:(BOOL)inValue;
- (NSImage *)cachedGradient:(NSSize)inSize;
- (void)drawBackgroundGradientInRect:(NSRect)inRect;
- (AIGradient *)backgroundGradient;
- (void)flushGradientCache;
- (NSColor *)flippyColor;

@end
