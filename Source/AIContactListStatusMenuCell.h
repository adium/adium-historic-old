//
//  AIContactListStatusMenuCell.h
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//

#import <Cocoa/Cocoa.h>


@interface AIContactListStatusMenuCell : NSButtonCell {
	NSMutableAttributedString		*title;
	NSSize							textSize;

	NSImage							*currentImage;
	NSSize							imageSize;

	NSMutableDictionary				*statusAttributes;
	NSMutableParagraphStyle			*statusParagraphStyle;
	
	BOOL					hovered;
	float					hoveredFraction;
}

- (void)setTitle:(NSString *)inTitle;
- (void)setImage:(NSImage *)inImage;

- (void)setHovered:(BOOL)inHovered;
- (float)trackingWidth;

@end
