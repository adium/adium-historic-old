//
//  AIToolbarTabView.h
//  Adium
//
//  Created by Adam Iser on Sat May 22 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

/*!
 * @class AIToolbarTabView
 * @brief <tt>NSTabView</tt> subclass for creating preference-type windows
 *
 * <p>This is a special <tt>NSTabView</tt> subclass which is useful when creating preference-type windows.  The tabview will automatically create a window toolbar and add an toolbar item for each tab it contains.  The tabview delegate will be asked for the toolbar images.</p>
 * <p>This class also contains methods for auto-sizing the parent window based on the selected tab.  The delegate is asked for the window size, and this tabview takes care of the animation.</p>
 * @see <tt><a href="category_n_s_object(_a_i_toolbar_tab_view_delegate).html" target="_top">NSObject(AIToolbarTabViewDelegate)</a></tt>
*/
@interface AIToolbarTabView : NSTabView {
    NSMutableDictionary *toolbarItems;
	int					oldHeight;
	
	IBOutlet NSTabViewItem			*tabViewItem_loading;
	IBOutlet NSProgressIndicator	*progressIndicator_loading;
}

@end


/*!
 * @category NSObject(AIToolbarTabViewDelegate)
 * @brief Methods which may optionally be implemented by an <tt>AIToolbarTabView</tt>'s delegate
 *
 * These methods allow the delegate greater control over the tab view.
 */
@interface NSObject (AIToolbarTabViewDelegate)
/*!
 * @brief Allows automatic creation of toolbar items for each <tt>NSTabViewItem</tt> the <tt>AIToolbarTabView</tt> contains.
 *
 * If this method is implemented by the delegate, the delegate will be queried for an image for each <tt>NSTabViewItem</tt>.  These images will be used to automatically populate the window's toolbar with toolbar items.
 * @param tabView The <tt>NSTabView</tt> sending the message
 * @param tabViewItem The <tt>NSTabViewItem</tt> for which an image is requested
 * @return An <tt>NSImage</tt> to use for a toolbar item associated with <b>tabViewItem</b>.
 */
- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem;

/*!
 * @brief Allows automatic resizing of the window when the toolbar is used to switch to an <tt>NSTabViewItem</tt>.
 *
 * If this method is implemented by the delegate, the delegate will be queried for a desired height when the user clicks the toolbar button associated with an <tt>NSTabViewItem</tt> (the toolbar item is created by implementation of tabView:imageForTabViewItem: by the delegate -- see its description.).	
 * @param tabView The <tt>NSTabView</tt> sending the message	
 * @param tabViewItem The <tt>NSTabViewItem</tt> for a height is requested	
 * @return The height needed to display <b>tabViewItem</b>.  The window will be smoothly resized to this height.
 */
- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem;

@end

