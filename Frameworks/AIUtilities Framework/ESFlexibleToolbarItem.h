//
//  ESFlexibleToolbarItem.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESFlexibleToolbarItem;

/*!
 * @class ESFlexibleToolbarItem
 * @brief Toolbar item with a validation delegate
 *
 * Normally, an NSToolbarItem does not validate if it has a custom view. <tt>ESFlexibleToolbarItem</tt> sends its delegate validate methods regardless of its configuration, allowing validation when using custom views.  Adium uses this, for example, to change the image on a toolbar button when conditions change in its window.
 */
@interface ESFlexibleToolbarItem : NSToolbarItem {
	id	validationDelegate;
}

/*!
 * @brief Set the validation delegate
 *
 * Set the validation delegate, which must implement the <tt>ESFlexibleToolbarItemDelegate/tt> protocol and will receive validation messages.
 * @param inDelegate The delegate
 */
- (void)setValidationDelegate:(id)inDelegate;

@end
