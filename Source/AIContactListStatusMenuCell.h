//
//  AIContactListStatusMenuCell.h
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//

#import <Cocoa/Cocoa.h>


@interface AIContactListStatusMenuCell : NSButtonCell {
	NSMutableAttributedString		*currentStatus;
	NSMutableDictionary				*statusAttributes;
	NSMutableParagraphStyle			*statusParagraphStyle;
	
	BOOL					hovered;
}

- (void)setHovered:(BOOL)inHovered;
- (float)trackingWidth;

@end
