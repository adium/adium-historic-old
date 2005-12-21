//
//  AIMenuItemView.h
//  Adium
//
//  Created by Evan Schoenberg on 12/20/05.
//

#import <Cocoa/Cocoa.h>

@interface AIMenuItemView : NSView {
	NSMenu			*menu;
	id				delegate;

	NSMutableSet	*trackingTags;
	NSDictionary	*menuItemAttributes;
	NSDictionary	*hoveredMenuItemAttributes;

	int currentHoveredIndex;
}

- (void)setMenu:(NSMenu *)inMenu;
- (void)setDelegate:(id)inDelegate;
- (void)sizeToFit;

@end

@interface NSObject (AIMenuItemViewDelegate)
- (NSMenu *)menuForMenuItemView:(AIMenuItemView *)inMenuItemView;
- (void)menuItemViewDidChangeMenu:(AIMenuItemView *)inMenuItemView;
@end

