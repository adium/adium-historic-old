//
//  AIOutlineView.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//

#define AIOutlineViewUserDidExpandItemNotification		@"AIOutlineViewUserDidExpandItemNotification"
#define AIOutlineViewUserDidCollapseItemNotification	@"AIOutlineViewUserDidCollapseItemNotification"

@class AIOutlineView;

/*!
	@protocol AIOutlineViewDelegate
	@abstract Delegate protocol for <tt>AIOutlineView</tt>
	@discussion Delegate protocol for <tt>AIOutlineView</tt>.  Implementation of all methods is optional.
*/
@protocol AIOutlineViewDelegate
/*!
	@method outlineView:menuForEvent:
	@abstract Requests a contextual menu for an event from the delegate
	@discussion This delegate method gives the delegate an opportunity to return an <tt>NSMenu</tt> to be displayed when the user right-clicks (control-clicks) in the outline view.  The passed event can be used to determine where the click occurred to make the menu sensitive to which row or column was clicked.
	@param outlineView The <tt>NSOutlineView</tt> which was clicked
	@param theEvent The event of the click
	@result An <tt>NSMenu</tt> to be displayed, or nil if no menu should be displayed
*/
- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent;

/*!
	@method outlineView:setExpandState:ofItem:
	@abstract Informs the delegate that the item was collapsed or exapnded
	@discussion This delegate method informs the delegate that the item was collapsed or expanded.
	@param outlineView The <tt>NSOutlineView</tt> which was changed
	@param state YES if the item is now expanded; NO if it is no collapsed
	@param item The item which was changed
*/
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item;

/*!
	@method outlineView:expandStateOfItem:
	@abstract Requests the correct expanded state for an item
	@discussion After reloading data, NSOutlineView collapses all items, which is generally not a desired behavior.  <tt>AIOutlineView</tt> provides the delegate an opportunity to specify whether each item should be exapnded or collapsed after a reload. This delegate method should return the correct expanded state of the passed item.
	@param outlineView The <tt>NSOutlineView</tt> which is reloading data
	@param item The item whose expanded state is requested
	@result YES if the item should be expanded; NO if it should be collapsed
*/
- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item;

/*!
	@method outlineViewDeleteSelectedRows:
	@abstract Informs the delegate of a request to delete the selected rows
	@discussion Informs the delegate of a request to delete the selected rows (via the delete key, generally). The delegate may wish to retrieve the currently selected rows and remove them from the data source and subsequently reload the outline view.
	@param outlineView The <tt>NSOutlineView</tt> from which the user wants to delete one or more rows.
*/
- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)outlineView;

/*!
	@method outlineView:draggedImage:endedAt:operation:
	@abstract Passes on NSObject's <tt>draggedImage:endedAt:operation:</tt> to the delegate
	@discussion Passes on NSObject's <tt>draggedImage:endedAt:operation:</tt>, which is invoked in the dragging source as the drag ends, to the delegate.  See <tt>NSObject</tt>'s documentation for more details.
	@param outlineView The <tt>NSOutlineView</tt> which ended the drag
	@param image The <tt>NSImage</tt> drag image
	@param screenPoint An <tt>NSPoint</tt> in screen coordinates
	@param operation The <tt>NSDragOperation</tt> of the drag
*/
- (void)outlineView:(NSOutlineView *)outlineView draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
@end

/*!
	@class AIOutlineView
	@abstract An NSOutlineView subclass with several improvments
	@discussion <p>This <tt>NSOutlineView</tt> subclass has several improvements and serves as the base class for the other outline view subclasses in the AIUtilities framework.</p>
	<p>It supports contextual menu, expanded state, deletion, and dragging-ended notification methods for its delegate (see the <tt>AIOutlineViewDelegate</tt> protocol description for details).</p>
	<p>It posts AIOutlineViewUserDidExpandItemNotification and AIOutlineViewUserDidCollapseItemNotification to the default NSNotificationCenter when items expand and collapse, respectively; for these notifications, the object is the <tt>AIOutlineView</tt> and the userInfo is an NSDictionary with the changed item in the key @"Object".
	<p>It supports improved keyboard navigation of the outline view, including supporting the delete key.</p>
	<p>Finally, it fixes a crash when reloadData is called from 'outlineView:setObjectValue:forTableColumn:byItem:' while the last row is edited in a way that will reduce the number of rows in the outline view (crash fix is relevant on all system versions as of OS X 10.3.7).</p>
*/
@interface AIOutlineView : NSOutlineView {
    BOOL		needsReload;
	BOOL		ignoreExpandCollapse;
}

@end
