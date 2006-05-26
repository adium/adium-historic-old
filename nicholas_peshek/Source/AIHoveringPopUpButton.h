//
//  AIHoveringPopUpButton.h
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//

#import <Cocoa/Cocoa.h>

@interface AIHoveringPopUpButton : NSButton {
	NSTrackingRectTag	trackingTag;
	BOOL				highlightOnHoverAndClick;
	SEL					doubleAction;
}

- (void)setTitle:(NSString *)inTitle;
- (void)setImage:(NSImage *)inImage;
- (void)setDoubleAction:(SEL)inDoubleAction;
- (void)setHighlightOnHoverAndClick:(BOOL)inHighlightOnHoverAndClick;

@end
