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

#import <Cocoa/Cocoa.h>

//Selection changed notification.  Object is the image grid whose selection changed.
#define AIImageGridViewSelectionDidChangeNotification	@"AIImageGridViewSelectionDidChangeNotification"
#define AIImageGridViewSelectionIsChangingNotification	@"AIImageGridViewSelectionIsChangingNotification"

@class AIScaledImageCell;

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
}

//Configuration
- (void)setDelegate:(id)inDelegate;
- (id)delegate;
- (void)setImageSize:(NSSize)inSize;
- (NSSize)imageSize;
- (void)reloadData;
		
//Drawing and sizing
- (NSRect)rectForImageAtIndex:(int)index;
- (int)imageIndexAtPoint:(NSPoint)point;
- (void)setNeedsDisplayOfImageAtIndex:(int)index;

//Behavior
- (void)selectIndex:(int)index;
- (int)selectedIndex;

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
