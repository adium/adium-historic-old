//
//  AIGradientCell.h
//  Adium
//
//  Created by Chris Serino on Wed Jan 28 2004.
//


@interface AIGradientCell : NSCell {
	BOOL			drawsGradient;
	BOOL			ignoresFocus;
}

- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient;
- (BOOL)drawsGradientHighlight;
- (void)setIgnoresFocus:(BOOL)inIgnoresFocus;
- (BOOL)ignoresFocus;
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

@end
