//
//  ESFlexibleToolbarItem.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
	@class ESFlexibleToolbarItem
	@abstract Toolbar item with a validation delegate
	@discussion Normally, an NSToolbarItem does not validate if it has a custom view. <tt>ESFlexibleToolbarItem</tt> sends its delegate validate methods regardless of its configuration, allowing validation when using custom views.  Adium uses this, for example, to change the image on a toolbar button when conditions change in its window.
*/
@interface ESFlexibleToolbarItem : NSToolbarItem {
	id	validationDelegate;
}

/*!
	@method setValidationDelegate:
	@abstract Set the validation delegate
	@discussion Set the validation delegate, which should implement - (void)validateToolbarItem:(ESFlexibleToolbarItem *)item and will receive validation messages.
	@param inDelegate The delegate
*/
- (void)setValidationDelegate:(id)inDelegate;

@end
