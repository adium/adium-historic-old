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
 *
 * @see <tt><a href="category_n_s_object(_e_s_flexible_toolbar_item_delegate).html">NSObject(ESFlexibleToolbarItemDelegate)</a></tt>
 */
@interface ESFlexibleToolbarItem : NSToolbarItem {
	id	validationDelegate;
}

/*!
 * @brief Set the validation delegate
 *
 * Set the validation delegate, which must implement the methods in <tt><a href="category_n_s_object(_e_s_flexible_toolbar_item_delegate).html">NSObject(ESFlexibleToolbarItemDelegate)</a></tt> and will receive validation messages.
 * @param inDelegate The delegate
 */
- (void)setValidationDelegate:(id)inDelegate;

@end

/*!
 * @category NSObject(ESFlexibleToolbarItemDelegate)
 * @brief Required protocol for an ESFlexibleToolbarItem's validation delegate
 *
 * The delegate is sent - (void)validateFlexibleToolbarItem:(ESFlexibleToolbarItem *)toolbarItem, which must be efficient
 */
@interface NSObject (ESFlexibleToolbarItemDelegate)
/*!
 * @brief Sent when the toolbar item is validated
 *
 * @param toolbarItem The toolbar item
 */
- (void)validateFlexibleToolbarItem:(ESFlexibleToolbarItem *)toolbarItem;
@end

