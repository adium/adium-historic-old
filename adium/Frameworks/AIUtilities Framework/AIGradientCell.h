//
//  AIGradientCell.h
//  Adium XCode
//
//  Created by Chris Serino on Wed Jan 28 2004.
//


@interface AIGradientCell : NSCell {
	BOOL			drawsGradient;
}

- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient;
- (BOOL)drawsGradientHighlight;

- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView; //stops warnings.

@end
