//
//  AIGradientImageCell.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 3/12/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @class AIGradientImageCell
 * @brief A combination of AIScaledImageCell and AIGradientCell
 */
@interface AIGradientImageCell : NSImageCell {
	BOOL			drawsGradient;
	BOOL			ignoresFocus;
	BOOL			isHighlighted;
	
	NSSize			maxSize;
}

/*
 * @brief Set if the highlight should be drawn as a gradient
 *
 * Set if the highlight should be drawn as a gradient across the selectedControlColor. Defaults to NO.
 * @param inDrawsGradient YES if the highlight should be drawn as a gradient
 */
- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient;

	/*
	 * @brief Returns if the highlight is drawn as a gradient
	 *
	 * Returns if the highlight is drawn as a gradient
	 * @return YES if the highlight is drawn as a gradient
	 */
- (BOOL)drawsGradientHighlight;

	/*
	 * @brief Set if the cell should ignore focus for purposes of highlight drawing.
	 *
	 * Set if the cell should ignore focus for purposes of highlight drawing.  If it ignores focus, it will look the same regardless of whether it has focus or not. The default is NO.
	 * @param inIgnoresFocus YES if focus is ignored.
	 */
- (void)setIgnoresFocus:(BOOL)inIgnoresFocus;
- (BOOL)ignoresFocus;

/*
 * @brief Set the maximum image size
 *
 * A 0 width or height indicates no maximum. The default is NSZeroSize, no maximum besides the cell bounds.
 */
- (void)setMaxSize:(NSSize)inMaxSize;

@end
