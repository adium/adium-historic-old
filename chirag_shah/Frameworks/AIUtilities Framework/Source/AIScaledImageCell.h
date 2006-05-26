//
//  AIScaledImageCell.h
//  AIUtilities.framework
//
//  Created by Adam Iser on 8/17/04.
//

/*!
 * @class AIScaledImageCell
 * @brief An <tt>NSImageCell</tt> subclass which scales its image to fit.
 *
 * An <tt>NSImageCell</tt> subclass which scales its image to fit.  The image will be scaled proportionally if needed, modifying the size in the optimal direction.
 */
@interface AIScaledImageCell : NSImageCell {
	BOOL	isHighlighted;
}

@end
