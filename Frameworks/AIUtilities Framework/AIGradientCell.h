//
//  AIGradientCell.h
//  Adium
//
//  Created by Chris Serino on Wed Jan 28 2004.
//

/*
	@class AIGradientCell
	@abstract An <tt>NSCell</tt> which can draw its highlight as a gradient
	@discussion This <tt>NSCell</tt> can draw its highlight as a gradient across the selectedControlColor. It can also be set to ignore focus for purposes of highlight drawing.
*/
@interface AIGradientCell : NSCell {
	BOOL			drawsGradient;
	BOOL			ignoresFocus;
}

/*
	@method setDrawsGradientHighlight:
	@abstract Set if the highlight should be drawn as a gradient
	@discussion Set if the highlight should be drawn as a gradient across the selectedControlColor. Defaults to NO.
	@param inDrawsGradient YES if the highlight should be drawn as a gradient
*/
- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient;
/*
	@method drawsGradientHighlight
	@abstract Returns if the highlight is drawn as a gradient
	@discussion Returns if the highlight is drawn as a gradient
	@result YES if the highlight is drawn as a gradient
*/
- (BOOL)drawsGradientHighlight;

/*
	@method setIgnoresFocus:
	@abstract Set if the cell should ignore focus for purposes of highlight drawing.
	@discussion Set if the cell should ignore focus for purposes of highlight drawing.  If it ignores focus, it will look the same regardless of whether it has focus or not. The default is NO.
	@param inIgnoresFocus YES if focus is ignored.
*/
- (void)setIgnoresFocus:(BOOL)inIgnoresFocus;
- (BOOL)ignoresFocus;

@end
