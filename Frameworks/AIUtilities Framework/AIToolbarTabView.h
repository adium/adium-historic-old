//
//  AIToolbarTabView.h
//  Adium
//
//  Created by Adam Iser on Sat May 22 2004.
//

/*!
	@class AIToolbarTabView
	@abstract <tt>NSTabView</tt> subclass for creating preferencet-type windows
	@discussion <p>This is a special <tt>NSTabView</tt> subclass that's useful in creating preference-type windows.  The tabview will automatically create a window toolbar and add an toolbar item for each tab it contains.  The tabview delegate will be asked for the toolbar images.</p>
	<p>This class also contains methods for auto-sizing the parent window based on the selected tab.  The delegate is asked for the window size, and this tabview takes care of the animation.</p>
*/
@interface AIToolbarTabView : NSTabView {
    NSMutableDictionary *toolbarItems;
	int					oldHeight;
}

@end

/*!
	@protocol AIToolbarTabViewDelegate
	@abstract Methods which may optionally be implemented by an <tt>AIToolbarTabView</tt>'s delegate
	@discussion These methods allow the delegate greater control over the tab view.
*/
@interface NSObject(AIToolbarTabViewDelegate)
/*!
	@method tabView:imageForTabViewItem:
	@abstract Allows automatic creation of toolbar items for each <tt>NSTabViewItem</tt> the <tt>AIToolbarTabView</tt> contains.
	@discussion If this method is implemented by the delegate, the delegate will be queried for an image for each <tt>NSTabViewItem</tt>.  These images will be used to automatically populate the window's toolbar with toolbar items.
	@param tabView The <tt>NSTabView</tt> sending the message
	@param tabViewItem The <tt>NSTabViewItem</tt> for which an image is requested
	@result An <tt>NSImage</tt> to use for a toolbar item associated with <b>tabViewItem</b>.
*/
- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem;

/*!
	@method tabView:heightForTabViewItem:
	@abstract Allows automatic resizing of the window when the toolbar is used to switch to an <tt>NSTabViewItem</tt>.
	@discussion If this method is implemented by the delegate, the delegate will be queried for a desired height when the user clicks the toolbar button associated with an <tt>NSTabViewItem</tt> (the toolbar item is created by implementation of tabView:imageForTabViewItem: by the delegate -- see its description.).
	@param tabView The <tt>NSTabView</tt> sending the message
	@param tabViewItem The <tt>NSTabViewItem</tt> for a height is requested
	@result The height needed to display <b>tabViewItem</b>.  The window will be smoothly resized to this height.
*/
- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem;
@end
