/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIListOutlineView.h"

#define	CONTACT_LIST_EMPTY_MESSAGE      AILocalizedString(@"No Available Contacts","Message to display when the contact list is empty")
#define TOOL_TIP_CHECK_INTERVAL			45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY					25.0	//Number of check intervals of no movement before a tip is displayed

@implementation AIListOutlineView

//Prevent the display of a focus ring around the contact list in 10.3 and greater
- (NSFocusRingType)focusRingType
{
    return(NSFocusRingTypeNone);
}

//When our delegate is set, ask it for our data cells
- (void)setDelegate:(id)delegate
{
	[super setDelegate:delegate];
	
	if([[self delegate] respondsToSelector:@selector(outlineView:dataCellForColumn:)]){
		NSEnumerator	*enumerator = [[self tableColumns] objectEnumerator];
		NSTableColumn	*column;
		
		while(column = [enumerator nextObject]){
			[column setDataCell:[[self delegate] outlineView:self dataCellForColumn:column]];
		}
	}
	
	[self setRowHeightFromDataCellOfColumn:[[self tableColumns] objectAtIndex:0]];
}

//Set row height based on the desired height of a column's data cell
- (void)setRowHeightFromDataCellOfColumn:(NSTableColumn *)column
{	
	NSCell	*cell = [column dataCell];
	
	if([cell respondsToSelector:@selector(cellHeightForGroup)]){
		[self setGroupRowHeight:[cell cellHeightForGroup]];
	}
	
	if([cell respondsToSelector:@selector(cellHeightForContent)]){
		[self setContentRowHeight:[cell cellHeightForContent]];
	}
}

#warning WTF is up with this?  Uncomment out this method and resize the contact list.  Why does this make a difference?
//If we DO NOT subcalss drawRect, the system will not update our view correctly while resizing (10.3.3)
- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}


//Frame and superview tracking -----------------------------------------------------------------------------------------
#pragma mark Frame and superview tracking
//We're going to move to a new superview
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];

	//Stop tracking our scrollview's frame
	if([self enclosingScrollView]){
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSViewFrameDidChangeNotification
													  object:[self enclosingScrollView]];
	}
	
	//Configure various things for the new superview
	[self configureSelectionHidingForNewSuperview:newSuperview];
	[self configureTooltipsForNewSuperview:newSuperview];
}

//We've moved to a new superview
- (void)viewDidMoveToSuperview
{	
	[super viewDidMoveToSuperview];
	
	//Start tracking our new scrollview's frame
	if([self enclosingScrollView]){
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(frameDidChange:)
													 name:NSViewFrameDidChangeNotification 
												   object:[self enclosingScrollView]];
		[self performSelector:@selector(frameDidChange:) withObject:nil afterDelay:0.0001];
	}
}

//Our enclosing scrollview has changed size
- (void)frameDidChange:(NSNotification *)notification
{
	[self configureTooltipsForNewScrollViewFrame];
}


//Selection Hiding -----------------------------------------------------------------------------------------------------
#warning do this at the cell level so as not to lose actual selection
//When our view is inserted into a window, observe that window so we can hide selection when it's not main
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if([newSuperview window]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameMain:) name:NSWindowDidBecomeMainNotification object:[newSuperview window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResignedMain:) name:NSWindowDidResignMainNotification object:[newSuperview window]];
    }
}

//Restore the selection
- (void)windowBecameMain:(NSNotification *)notification
{
	NSLog(@"Unhide selection");
}

//Hide the selection
- (void)windowResignedMain:(NSNotification *)notification
{
	NSLog(@"Hide selection");
}

    
//Auto Sizing --------------------------------------------------------------------------
//Updates the horizontal size of several objects, posting a desired size did change notification if necessary
//- (void)updateHorizontalSizeForObjects:(NSArray *)inObjects
//{
//	NSEnumerator	*enumerator = [inObjects objectEnumerator];
//	AIListObject	*object;
//	BOOL			changed = NO;
//	
//	while(object = [enumerator nextObject]){
//		if([self _performPartialRecalculationForObject:object]) changed = YES;
//	}
//	
//    if(changed){
//        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self]; //Resize
//    }
//}
//
////Updates the horizontal size of an object, posting a desired size did change notification if necessary
//- (void)updateHorizontalSizeForObject:(AIListObject *)inObject
//{
//	if([self _performPartialRecalculationForObject:inObject]){
//        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self]; //Resize
//	}
//}
//
////Recalulate an object's size and determine if we need to resize our view
//- (BOOL)_performPartialRecalculationForObject:(AIListObject *)inObject
//{
//    NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
//    AISCLCell 		*cell = [column dataCell];
//    float			cellWidth;
//    NSArray			*cellSizeArray;
//    BOOL			changed = NO;
//    int				j;
//
//	if([self rowForItem:inObject] == -1){ //We don't cache hidden objects
//		for(j=0; j < 3; j++){ //check left, middle, and right
//			if(hadMax[j] == inObject){ //if this object was the largest in terms of j before but is now hidden, then we need to search for the now-largest
//				[self _performFullRecalculationFor:j];
//				changed = YES;
//			}
//		}
//	}else{ //object is in the active contact list
//		[[self delegate] outlineView:self willDisplayCell:cell forTableColumn:column item:inObject];        
//		for(j=0 ; j < 3; j++){  //check left, middle, and right
//			cellSizeArray = [cell cellSizeArrayForBounds:NSMakeRect(0,0,0,[self rowHeight]) inView:self];
//			cellWidth = [[cellSizeArray objectAtIndex:j] floatValue];
//			if(cellWidth > desiredWidth[j]) {
//				desiredWidth[j] = cellWidth;
//				hadMax[j] = inObject;
//				changed = YES;
//			} else if ((hadMax[j] == inObject) && (cellWidth != desiredWidth[j]) ) {   //if this object was the largest in terms of j before but is not now, then we need to search for the now-largest
//				[self _performFullRecalculationFor:j];
//				changed = YES;
//			}
//		}   
//	}
//	
//	return(changed);
//}
//
//- (void)_performFullRecalculation
//{
//    int j;
//    for (j=0 ; j < 3 ; j++) {
//        [self _performFullRecalculationFor:j];
//    }
//    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
//}
//
//- (void)_performFullRecalculationFor:(int)j
//{
//    NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
//    AISCLCell		*cell = [column dataCell];
//    AIListObject	*object;
//    float			cellWidth;
//    NSArray			*cellSizeArray;
//    int				i;
//    
//	desiredWidth[j]=0;
//	hadMax[j]=nil;
//    for(i = 0; i < [self numberOfRows]; i++){
//        object = [self itemAtRow:i];
//
//        [[self delegate] outlineView:self willDisplayCell:cell forTableColumn:column item:object];
//        
//        cellSizeArray = [cell cellSizeArrayForBounds:NSMakeRect(0,0,0,[self rowHeight]) inView:self];
//		
//        cellWidth = [[cellSizeArray objectAtIndex:j] floatValue];
//        if(cellWidth > desiredWidth[j]){
//            desiredWidth[j] = cellWidth;
//            hadMax[j] = object;
//        }
//    } 
//}
//
//// Returns our desired size
//- (NSSize)desiredSize
//{
//    //We need to convert this to a lazy cache
//    
//    if([self numberOfRows] == 0){
//        return( NSMakeSize(EMPTY_WIDTH, EMPTY_HEIGHT) );
//    }else{
//        float	desiredHeight;
//        int     j;
//        float   totalWidth = 0;
//        
//        desiredHeight = [self numberOfRows] * ([self rowHeight] + [self intercellSpacing].height);
//         for (j = 0; j < 3; j++) {
//             totalWidth += desiredWidth[j]; 
//         }
//         
//         totalWidth += [self intercellSpacing].width + 3; //+3 is to account for variable-width letters.  stupid things.
//         
//         if(totalWidth < DESIRED_MIN_WIDTH) totalWidth = DESIRED_MIN_WIDTH;
//         if(desiredHeight < DESIRED_MIN_HEIGHT) desiredHeight = DESIRED_MIN_HEIGHT;
//         
//         return( NSMakeSize(totalWidth, desiredHeight) );
//    }
//}


//Contact menu ---------------------------------------------------------------
//Return the selected object (to auto-configure the contact menu)
- (AIListObject *)listObject
{
    int selectedRow = [self selectedRow];

    if(selectedRow >= 0 && selectedRow < [self numberOfRows]){
        return([self itemAtRow:selectedRow]);
    }else{
        return(nil);
    }
}



#warning still need this?
//Our default drag image will be cropped incorrectly, so we need a custom one here
//- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset
//{
//	NSRect			rowRect, cellRect;
//	int				count = [dragRows count];
//	
//	int				firstRow = [[dragRows objectAtIndex:0] intValue];
//	NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
//	NSCell			*cell;
//	NSImage			*image;
//	
//	//Since our cells draw outside their bounds, this drag image code will create a drag image as big as the table row
//	//and then draw the cell into it at the regular size.  This way the cell can overflow its bounds as normal and not
//	//spill outside the drag image.
//	rowRect = [self rectOfRow:firstRow];
//	image = [[NSImage alloc] initWithSize:NSMakeSize(rowRect.size.width,
//													 rowRect.size.height*count + [self intercellSpacing].height*(count-1))];
//
//	
//NSEnumerator	*enumerator = [dragRows objectEnumerator];
//NSNumber		*rowNumber;
//int				row;
//float			yOffset = 0;
//
//	//Draw (Since the OLV is normally flipped, we have to be flipped when drawing)
//	[image setFlipped:YES];
//	[image lockFocus];
//
//	while (rowNumber = [enumerator nextObject]){
//		row = [rowNumber intValue];
//		cell = [column dataCellForRow:row];
//		cellRect = [self frameOfCellAtColumn:0 row:row];
//		
//		//Render the cell
//		[[self dataSource] outlineView:self willDisplayCell:cell forTableColumn:column item:[self itemAtRow:row]];
////		NSLog(@"%i is %f %f %f = %f",row,cellRect.origin.y,rowRect.origin.y,yOffset,cellRect.origin.y - rowRect.origin.y + yOffset);
//		[cell drawWithFrame:NSMakeRect(cellRect.origin.x - rowRect.origin.x, /*cellRect.origin.y - rowRect.origin.y +*/ yOffset,cellRect.size.width,cellRect.size.height)
//					 inView:self];
//		yOffset += (rowRect.size.height + [self intercellSpacing].height);
//	}
//	
//	[image unlockFocus];
//	[image setFlipped:NO];
//	
//	//Offset the drag image (Remember: The system centers it by default, so this is an offset from center)
//	NSPoint clickLocation = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
//	dragImageOffset->x = (rowRect.size.width / 2.0) - clickLocation.x;
//	
//	return([image autorelease]);
//}


	
	
	
	
	
//Tooltips (Cursor rects) ----------------------------------------------------------------------------------------------
//We install a cursor rect for our enclosing scrollview.  When the cursor is within this rect, we track it's
//movement.  If our scrollview changes, or the size of our scrollview changes, we must re-install our rect.
#pragma mark Tooltips (Cursor rects)
//Stop cursor tracking before we're moved out of our scrollview
- (void)configureTooltipsForNewSuperview:(NSView *)newSuperview
{
	[self _removeCursorRect];
}

//Reset our cursor tracking for the new scrollview frame
- (void)configureTooltipsForNewScrollViewFrame
{
	[self _removeCursorRect];
	[self _installCursorRect];
}

//Install the cursor rect for our enclosing scrollview
- (void)_installCursorRect
{
	if(tooltipTrackingTag == -1){
		NSScrollView	*scrollView = [self enclosingScrollView];
		NSRect	 		trackingRect;
		BOOL			mouseInside;
		
		//Add a new tracking rect (The size of our scroll view minus the scrollbar)
		trackingRect = [scrollView frame];
		trackingRect.size.width = [scrollView contentSize].width;
		mouseInside = NSPointInRect([[self window] convertScreenToBase:[NSEvent mouseLocation]], trackingRect);
		tooltipTrackingTag = [[[self window] contentView] addTrackingRect:trackingRect
																			   owner:self
																			userData:scrollView
																		assumeInside:mouseInside];
		
		//If the mouse is already inside, begin tracking the mouse immediately
		if(mouseInside) [self _startTrackingMouse];
	}
}

//Remove the cursor rect
- (void)_removeCursorRect
{
	if(tooltipTrackingTag != -1){
		[[[self window] contentView] removeTrackingRect:tooltipTrackingTag];
		tooltipTrackingTag = -1;
		[self _stopTrackingMouse];
	}
}
	

//Tooltips (Cursor movement) -------------------------------------------------------------------------------------------
//We use a timer to poll the location of the mouse.  Why do this instead of using mouseMoved: events?
// - Webkit eats mousemoved events, even when those events occur elsewhere on the screen
// - Mousemoved events do not work when Adium is in the background
#pragma mark Tooltips (Cursor movement)
//Mouse entered our list, begin tracking it's movement
- (void)mouseEntered:(NSEvent *)theEvent
{
	[self _startTrackingMouse];
}

//Mouse left our list, cease tracking
- (void)mouseExited:(NSEvent *)theEvent
{
	[self _stopTrackingMouse];
}

//Start tracking mouse movement
- (void)_startTrackingMouse
{
	if(!tooltipMouseLocationTimer){
		tooltipCount = 0;
		tooltipMouseLocationTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/TOOL_TIP_CHECK_INTERVAL)
																	  target:self
																	selector:@selector(mouseMovementTimer:)
																	userInfo:nil
																	 repeats:YES] retain];
	}
}

//Stop tracking mouse movement
- (void)_stopTrackingMouse
{
	[self _showTooltipAtPoint:NSMakePoint(0,0)];
	[tooltipMouseLocationTimer invalidate];
	[tooltipMouseLocationTimer release];
	tooltipMouseLocationTimer = nil;
}

//Time to poll mouse location
- (void)mouseMovementTimer:(NSTimer *)inTimer
{
	NSPoint mouseLocation = [NSEvent mouseLocation];

	//tooltipCount is used for delaying the appearence of tooltips.  We reset it to 0 when the mouse moves.  When
	//the mouse is left still tooltipCount will eventually grow greater than TOOL_TIP_DELAY, and we will begin
	//displaying the tooltips
	tooltipCount++;
	if(tooltipCount > TOOL_TIP_DELAY){
		[self _showTooltipAtPoint:mouseLocation];
		
	}else{
		if(!NSEqualPoints(mouseLocation,lastMouseLocation)){
			lastMouseLocation = mouseLocation;
			tooltipCount = 0; //reset tooltipCount to 0 since the mouse has moved
		}
	}
}


//Tooltips (Display) -------------------------------------------------------------------------------------------
#pragma mark Tooltips (Display)
//Hide any active tooltip and reset the initial appearance delay
- (void)hideTooltip
{
	[self _showTooltipAtPoint:NSMakePoint(0,0)];
	tooltipCount = 0;
}

//Show a tooltip at the specified screen point.  If point is (0,0) the tooltip will be hidden
- (void)_showTooltipAtPoint:(NSPoint)screenPoint
{
	if(!NSEqualPoints(tooltipLocation, screenPoint)){
		AIListObject	*hoveredObject = nil;

		if(screenPoint.x != 0 && screenPoint.y != 0){
			NSPoint			viewPoint;
			int				hoveredRow;
			
			//Extract data from the event
			viewPoint = [self convertPoint:[[self window] convertScreenToBase:screenPoint] fromView:nil];
			
			//Get the hovered contact
			hoveredRow = [self rowAtPoint:viewPoint];
			hoveredObject = [self itemAtRow:hoveredRow];
		}
		
		
		[[[AIObject sharedAdiumInstance] interfaceController] showTooltipForListObject:hoveredObject
																		 atScreenPoint:screenPoint
																			  onWindow:[self window]];
		tooltipLocation = screenPoint;
	}
}
		
@end

