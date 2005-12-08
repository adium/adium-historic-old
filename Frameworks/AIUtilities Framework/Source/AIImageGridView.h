/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

//Selection changed notification.  Object is the image grid whose selection changed.
#define AIImageGridViewSelectionDidChangeNotification	@"AIImageGridViewSelectionDidChangeNotification"
#define AIImageGridViewSelectionIsChangingNotification	@"AIImageGridViewSelectionIsChangingNotification"

@class AIScaledImageCell;

/*!
 * @class AIImageGridView
 * @brief View that displays a grid of images
 *
 * This view displays images in a grid similiar to iPhoto.  Image size is adjustable and the view handles image layout
 * and spacing automatically.
 */
@interface AIImageGridView : NSView {
	id					delegate;
	AIScaledImageCell	*cell;
	NSTrackingRectTag	trackingTag;
	
	NSSize				imageSize;
	NSSize				padding;			//Padding between images
	int					columns;			//Number of columns
	int 				selectedIndex;		//Currently selected image index
	int					hoveredIndex;		//Currently hovered image index
	
	//The optional methods our current delegate responds to (So we don't have to ask it repeatedly)
	BOOL		_respondsToShouldSelect;
	BOOL		_respondsToSelectionDidChange;
	BOOL		_respondsToSelectionIsChanging;
	BOOL		_respondsToDeleteSelection;
	BOOL		_respondsToImageHovered;
	BOOL		drawsBackground;
}

/*!
 * @brief Set the delegate for this view
 *
 * The delegate is informed of selection changes, cursor movement, and serves as the data source for the images
 * that will be displayed.
 * @param inDelegate Delegate and datasource 
 */
- (void)setDelegate:(id)inDelegate;

/*!
 * @brief Retrieve the delegate for this view
 *
 * @return the current delegate 
 */
- (id)delegate;

/*!
 * @brief Set the size images will display
 *
 * Set the size for image display and layout within the grid.  The view will automatically re-layout and column the
 * the images as this value is changed.
 * @param inSize <tt>NSSize</tt> for image display
 */
- (void)setImageSize:(NSSize)inSize;

/*!
 * @brief Retrieve image display size
 *
 * @return <tt>NSSize</tt> current image size
 */
- (NSSize)imageSize;

/*!
 * @brief Reload images from delegate
 *
 * Invokes a reload of images from the delegate.  Call this method when the images or number of images changes and the
 * view needs re-layout in response.  The view will automatically redisplay if needed.
 */
- (void)reloadData;
		
/*!
 * @brief Returns the rect occupied by an image in our grid
 *
 * @param index Index of the image
 * @return <tt>NSRect</tt> the image occupies in our grid
 */
- (NSRect)rectForImageAtIndex:(int)index;

/*!
 * @brief Returns the image present at a point in our grid
 *
 * @param point Location
 * @return index of the image at point
 */
- (int)imageIndexAtPoint:(NSPoint)point;

/*!
 * @brief Redisplay an image in our grid
 *
 * @param index Index of the image
 */
- (void)setNeedsDisplayOfImageAtIndex:(int)index;

/*!
 * @brief Set the selected image
 *
 * Set the currently selected image.  The delegate is informed of selection changes.
 * @param index Image index to select
 */
- (void)selectIndex:(int)index;

/*!
 * @brief Retrieve the selected image
 *
 * @return index of the currently selected image
 */
- (int)selectedIndex;

/*!
 * @brief Check whether the receiver is set to draw its background
 *
 * @return a BOOL indicating if the background is drawn
 */
- (BOOL)drawsBackground;

/*!
 * @brief Set whether the receiver draws its background
 *
 * @param flag A BOOL indicating whether or not to draw the background
 */
- (void)setDrawsBackground:(BOOL)flag;

@end

//AIImageGridView delegate methods.  These are very similar to NSTableView.
@interface NSObject (AIImageGridViewDelegate)
- (int)numberOfImagesInImageGridView:(AIImageGridView *)imageGridView;
- (NSImage *)imageGridView:(AIImageGridView *)imageGridView imageAtIndex:(int)index;
- (BOOL)imageGridView:(AIImageGridView *)imageGridView shouldSelectIndex:(int)index;			//Optional
- (void)imageGridViewDeleteSelectedImage:(AIImageGridView *)imageGridView;						//Optional
- (void)imageGridView:(AIImageGridView *)imageGridView cursorIsHoveringImageAtIndex:(int)index;	//Optional
@end

//Notifications.  These are automatically sent to the delegate.
@interface NSObject(AIImageGridViewNotifications)
- (void)imageGridViewSelectionDidChange:(NSNotification *)notification;
- (void)imageGridViewSelectionIsChanging:(NSNotification *)notification;
@end
