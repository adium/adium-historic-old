//
//  AIScaledImageCell.h
//  AIUtilities.framework
//
//  Created by Adam Iser on 8/17/04.
//

#import <Cocoa/Cocoa.h>

/*!
	@class AIScaledImageCell
	@abstract An <tt>NSImageCell</tt> subclass which scales its image to fit.
	@discussion An <tt>NSImageCell</tt> subclass which scales its image to fit.  The image will be scaled proportionally if needed, modifying the size in the optimal direction.
*/
@interface AIScaledImageCell : NSImageCell {
	BOOL	isHighlighted;
}

@end
