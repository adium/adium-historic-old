//
//  AIContactListStatusMenuView.h
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//

#import <Cocoa/Cocoa.h>

@interface AIContactListStatusMenuView : NSButton {
	NSTrackingRectTag					trackingTag;
}

- (void)setTitle:(NSString *)inTitle;
- (void)setImage:(NSImage *)inImage;

@end
