/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIFlexibleTableView.h"
#import "AIFlexibleTableCell.h"

#define COPY_MENU_ITEM AILocalizedString(@"Copy","Copy to the clipboard")

@interface AIFlexibleTableView (PRIVATE)
- (void)_init;
- (NSAttributedString *)_selectedString;
- (void)_resizeViewToWidth:(int)width height:(int)height;
- (void)_resizeContents:(BOOL)resizeContents;
- (AIFlexibleTableRow *)_rowAtPoint:(NSPoint)inPoint rowOrigin:(NSPoint *)outOrigin;
- (void)_resetCursorRectsForVisibleRect:(NSRect)visibleRect;
- (void)_selectFromPoint:(NSPoint)startPoint toPoint:(NSPoint)endPoint;
- (void)_deselectAll;
- (void)_dragMouseWithEvent:(NSEvent *)theEvent;
- (void)_dragSelectedContentWithEvent:(NSEvent *)theEvent;
- (void)forwardSelector:(SEL)selector withObject:(id)object;
@end

@implementation AIFlexibleTableView

//Init ------------------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _init];
    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self _init];
    return(self);
}

- (id)init
{
    [super init];
    [self _init];
    return(self);
}

- (void)_init
{
    cursorTrackingRowArray = [[NSMutableArray alloc] init];
    rowArray = [[NSMutableArray alloc] init];
    contentsHeight = 0;
    forwardsKeyEvents = NO;
    selectClicks = 1;
    contentOrigin = NSMakePoint(0, 0);
    topPadding = 0;
    bottomPadding = 0;

    contentBottomAligned = YES;
    lockFocus = NO;
    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
}

- (void)dealloc
{
    //Remove cursor tracking (by passing an empty rect)
    [self _resetCursorRectsForVisibleRect:NSMakeRect(0,0,0,0)];

    //Ensure we're no longer observing
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];

    //Clean up
    [cursorTrackingRowArray release];
    [rowArray release];

    [super dealloc];
}


//Config -------------------------------------------------------------------------------
//Set the content cells bottom aligned
- (void)setContentBottomAligned:(BOOL)inValue{
    contentBottomAligned = inValue;
}

//Set content padding
- (void)setContentPaddingTop:(int)inTop bottom:(int)inBottom
{
    topPadding = inTop;
    bottomPadding = inBottom;
}

//Pass all keypresses to the next responder
- (void)setForwardsKeyEvents:(BOOL)inValue{
    forwardsKeyEvents = inValue;
}

//Access to our delegate
- (void)setDelegate:(id)inDelegate{
    delegate = inDelegate;
}
- (id)delegate{
    return(delegate);
}

//
- (void)lockTable
{
    lockFocus = YES;
}

- (void)unlockTable
{
    lockFocus = NO;
    [self resetCursorRects];
    [self _resizeContents:YES];
    
    [self display];
}


//Drawing -------------------------------------------------------------------------------
//Draw
- (void)drawRect:(NSRect)rect
{
    if(!lockFocus){
        NSEnumerator		*rowEnumerator;
        AIFlexibleTableRow	    *row;
        NSRect			documentVisibleRect;
        NSPoint			cellPoint = contentOrigin;
        BOOL			foundVisible = NO;
        
        //Get our visible rect (we don't want to draw non-visible rows)
        documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
        
        //Enumerate through each row
        //We draw from the bottom up, so we can avoid enumerating through rows that have scrolled out of view
        rowEnumerator = [rowArray objectEnumerator];
        while((row = [rowEnumerator nextObject])){
            int	rowHeight = [row height];
            
            cellPoint.y -= rowHeight;
            if(NSIntersectsRect(NSMakeRect(cellPoint.x, cellPoint.y, rect.size.width, rowHeight), documentVisibleRect) || (foundVisible && [row spansRows])){ //If visible
                [row drawAtPoint:cellPoint visibleRect:documentVisibleRect inView:self];
                if(!foundVisible) foundVisible = YES;
            }else{
                if(foundVisible) break; //Stop scanning once we hit a non-visible (after having drawn something)
            }
        }
    }
}


//Context menu ------------------------------------------------------------------------
//Return the contextual menu for an event
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    AIFlexibleTableRow	*clickedRow;
    NSPoint		clickLocation, rowClickLocation;
    NSPoint		rowOrigin;
    NSMutableArray      *tableViewItemArray = [[[NSMutableArray alloc] init] autorelease];
    NSMenu              *menu = nil;
    NSEnumerator        *enumerator;
    NSMenuItem          *menuItem;
    
    //Determine clicked row
    clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    clickedRow = [self _rowAtPoint:clickLocation rowOrigin:&rowOrigin];
    rowClickLocation = NSMakePoint(clickLocation.x - rowOrigin.x, clickLocation.y - rowOrigin.y); //Local to the row
    
    NSArray *rowContextArray = [clickedRow menuItemsForEvent:theEvent atPoint:rowClickLocation offset:rowOrigin];
    if(rowContextArray && [rowContextArray count]){
        [tableViewItemArray addObjectsFromArray:rowContextArray];
    }
    
    //[returnArray addObject:[NSMenuItem separatorItem]];
    
    //Copy
    if([clickedRow pointIsSelected:rowClickLocation offset:rowOrigin]) {
        [tableViewItemArray addObject:[[[NSMenuItem alloc] initWithTitle:COPY_MENU_ITEM
                                                                  target:self
                                                                  action:@selector(copy:)
                                                           keyEquivalent:@""] autorelease]];
    }
    
    //Pass this on to our delegate
    if([delegate respondsToSelector:@selector(contextualMenuForFlexibleTableView:)]){
        menu = ([(id<AIFlexibleTableViewDeleagte>)delegate contextualMenuForFlexibleTableView:self]);
    }
    
    //Add any table-specific menu items to the front of the menu
    if (tableViewItemArray && [tableViewItemArray count]) {
        //If the delegate didn't respond or responded nil, initialize a menu
        //Otherwise, prepend a separator
        if(!menu){
            menu = [[[NSMenu alloc] init] autorelease];
        }else{
            [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        }
        enumerator = [tableViewItemArray reverseObjectEnumerator];
        while (menuItem = [enumerator nextObject]) {
            [menu insertItem:menuItem atIndex:0];
        }
    }
    
    return(menu);   
}


//Clicking --------------------------------------------------------------------------------
//
- (void)mouseDown:(NSEvent *)theEvent
{
    AIFlexibleTableRow	*clickedRow;
    NSPoint		clickLocation, rowClickLocation;
    NSPoint		rowOrigin;
    int			clicks;

    //Determine clicked row
    clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    clickedRow = [self _rowAtPoint:clickLocation rowOrigin:&rowOrigin];
    rowClickLocation = NSMakePoint(clickLocation.x - rowOrigin.x, clickLocation.y - rowOrigin.y); //Local to the row

    //Remember the number of clicks
    if(![theEvent shiftKey]){
        clicks = [theEvent clickCount];
        if(!(clicks % 3)){ //Tripple click (Select line)
            selectClicks = 3;
        }else if(!(clicks % 2)){ //Double Click (Select word)
            selectClicks = 2;
        }else{
            selectClicks = 1;
        }
    }

    //Give the row a chance to handle the click
    if(![clickedRow handleMouseDownEvent:theEvent atPoint:rowClickLocation offset:rowOrigin]){
        NSEvent	*newEvent = nil;
        BOOL	handled = NO;

        //Drag --------------------
        if(selectClicks < 3 && [clickedRow pointIsSelected:rowClickLocation offset:rowOrigin]){
            //Trigger a periodic event to start the drag after a short delay
            [NSEvent startPeriodicEventsAfterDelay:0.25 withPeriod:0];

            //Grab the next event
            newEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO];
            switch([newEvent type]){
                case NSPeriodic: //If the user stays still, initiate the drag
                    [self _dragSelectedContentWithEvent:theEvent];
                    handled = YES;
                break;
                default: break; //Mouse up or drag will cancel
            }

            //Stop the periodic event
            [NSEvent stopPeriodicEvents];
        }

        //Select --------------------
        if(!handled){
            //Update selected range
            [self _deselectAll];
            selection_startPoint = clickLocation;
            [clickedRow selectContentFrom:rowClickLocation to:rowClickLocation offset:rowOrigin mode:selectClicks];
            
            //Handle selection until a mouse up
            [NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:0.05];
            do{
                newEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)];
    
                switch([newEvent type]){
                    case NSLeftMouseDraggedMask:
                    case NSPeriodic:
                        [self _dragMouseWithEvent:newEvent];
                    break;
                    default: break;
                }
                
            }while(newEvent == nil || [newEvent type] != NSLeftMouseUp);
            [NSEvent stopPeriodicEvents];
        }
    }
}

//Deselect all content
- (void)_deselectAll
{
    NSEnumerator		*rowEnumerator;
    AIFlexibleTableRow		*row;

    //Determine the clicked row
    rowEnumerator = [rowArray objectEnumerator];
    while((row = [rowEnumerator nextObject])){
        [row deselectContent];
    }    
}

//
- (void)_dragMouseWithEvent:(NSEvent *)theEvent
{
    NSScrollView	*scrollView = [self enclosingScrollView];
    NSClipView		*clipView = [scrollView contentView];
    NSPoint		location = [self convertPoint:[[self window] convertScreenToBase:[theEvent locationInWindow]] fromView:nil];
    NSRect		visibleRect = [scrollView documentVisibleRect];

    if(!NSPointInRect(location, visibleRect)){
        NSPoint	scrollPoint = location;

        //down
        if(scrollPoint.y >= visibleRect.origin.y + visibleRect.size.height){
            scrollPoint.y -= visibleRect.size.height;
        }

        //accelerate
        scrollPoint.y -= visibleRect.origin.y;
        scrollPoint.y *= [scrollView lineScroll] / 3.0;
        scrollPoint.y += visibleRect.origin.y;

        [clipView scrollToPoint:[clipView constrainScrollPoint:scrollPoint]];
        [scrollView reflectScrolledClipView:clipView];
    }

    [self _selectFromPoint:selection_startPoint
                   toPoint:location];
}

//
- (void)_dragSelectedContentWithEvent:(NSEvent *)theEvent
{
    NSPoint		location = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    NSImage             *image;
    NSImage             *dragImage;
    NSSize 		dragOffset = NSMakeSize(0.0, 0.0);
    NSSize              dragSize;
    
    NSPasteboard 	*pboard;
    NSAttributedString 	*copyString = [self _selectedString];
    
    //Put the text to drag on our pasteboard
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:self];
    [pboard setData:[copyString RTFFromRange:NSMakeRange(0,[copyString length]) documentAttributes:nil] forType:NSRTFPboardType];

    //Create a temporary drag image
    dragSize = [copyString size];       
    image = [[NSImage alloc] initWithSize:dragSize];
    dragImage = [[NSImage alloc] initWithSize:dragSize]; 
    
    [image lockFocus];
    [copyString drawInRect:NSMakeRect(0, 0,[self frame].size.width,[self frame].size.height)];
    [image unlockFocus];
    
    [dragImage lockFocus];
    [image dissolveToPoint:NSMakePoint(0,0) fraction:0.8]; //20% transparent
    [dragImage unlockFocus];
    
    location.y += ([dragImage size].height / 2.0);
//    location.x -= ([dragImage size].width / 2.0);
    [[self superview] dragImage:dragImage at:location offset:dragOffset event:theEvent pasteboard:pboard source:self slideBack:YES];
}

//
- (void)_selectFromPoint:(NSPoint)startPoint toPoint:(NSPoint)endPoint
{
    NSEnumerator		*rowEnumerator;
    AIFlexibleTableRow		*row;
    NSPoint			rowPoint = contentOrigin;

    //Deselect all
    [self _deselectAll];

    //Flip, so we're working from top to bottom
    if(endPoint.y < startPoint.y){
        NSPoint	temp = startPoint;
        startPoint = endPoint;
        endPoint = temp;
    }

    //Determine the clicked row
    rowEnumerator = [rowArray objectEnumerator];
    while((row = [rowEnumerator nextObject])){

        rowPoint.y -= [row height];

        if(rowPoint.y < endPoint.y && (rowPoint.y + [row height]) > startPoint.y){
            BOOL end = NO, start = NO;

            if(rowPoint.y + [row height] > endPoint.y) end = YES; //selection ends in this row
            if(rowPoint.y  < startPoint.y) start = YES; //starts in this row

            [row selectContentFrom:(start ? NSMakePoint(startPoint.x - rowPoint.x, startPoint.y - rowPoint.y) : NSMakePoint(-1,-1))
                                to:(end ? NSMakePoint(endPoint.x - rowPoint.x, endPoint.y - rowPoint.y) : NSMakePoint(1e7,1e7))
                            offset:rowPoint
                              mode:selectClicks];
        }
    }
}

    
//Misc --------------------------------------------------------------------------------
- (BOOL)needsPanelToBecomeKey
{
    return(YES);
}

//YES, we accept first responder
- (BOOL)acceptsFirstResponder
{
    return(YES);
}

//Return yes so our view's origin is in the top left
- (BOOL)isFlipped{
    return(YES);
}

//
- (void)viewDidMoveToSuperview
{
    //Remove existing observers
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];

    if([self enclosingScrollView] != nil){
        //Observe scroll view frame changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewFrameChanged:) name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];

        //fit our new view
        [self _resizeContents:YES];
    }
}

//Called when our scroll view's frame changes.  Adjust our view to completely fill the new frame
- (void)scrollViewFrameChanged:(NSNotification *)notification
{
    //Resize our contents (We skip resizing our cells if the scrollview's width did not change)
    [self _resizeContents:([self frame].size.width != oldWidth)];
    oldWidth = [self frame].size.width;
}

//Called when a live resize ends, perform a full resize
- (void)viewDidEndLiveResize
{
    [self _resizeContents:YES]; //Resize our cells, our view vertically, and redisplay
}


//Content -------------------------------------------------------------------------------
//Load the content in a newly added row (Quicker than doing a full reload of the content)
- (void)addRow:(AIFlexibleTableRow *)inRow
{
    //Add the new row (To the head of our array)
    [self addRow:inRow atIndex:0];
}
- (void)addRow:(AIFlexibleTableRow *)inRow atIndex:(int)index
{
    //Add the new row
    [rowArray insertObject:inRow atIndex:index];
    [inRow setTableView:self];
    
    //Resize the row above (if necessary) to update any spanning
    if([inRow isSpannedInto]){
	[self resizeRow:[rowArray objectAtIndex:(index+1)]];
    }
    
    //Resize the new row
    [self resizeRow:inRow];
    if (!lockFocus) {  
        //Update our cursor tracking (We can skip this if our view is tall enough to scroll, since it will be called automatically then)
        if([self frame].size.height <= [[self enclosingScrollView] documentVisibleRect].size.height){
            [self resetCursorRects];
        }
    }
}

//Remove all rows
- (void)removeAllRows
{
    [rowArray release]; rowArray = [[NSMutableArray alloc] init];
    if (!lockFocus) {
        [self resetCursorRects];
        [self _resizeContents:YES];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)removeBlockOfRowsWithTag:(int)tag
{
    NSEnumerator        *rowEnumerator;
    AIFlexibleTableRow  *row;
    
    //Enumerate through each row
    //We move from the bottom up, so we can avoid enumerating through rows after we remove a block of rows with a given tag
    NSMutableArray *rowsToRemove = [NSMutableArray arrayWithCapacity:2]; //2 is a good guess for our purposes; NSMutableArray expands as necessary if we need more rows
    
    BOOL foundTag  = NO;
    
    
    rowEnumerator = [rowArray objectEnumerator];
    while((row = [rowEnumerator nextObject])){
        if ([row tag] == tag) {
            [rowsToRemove addObject:row];
            foundTag = YES;
        }else{
            if (foundTag) break; //Stop scanning once we hit a non-match (after having found an approriate row or rows)
        }
    }
    
    //removeObjectsFromArray is the intuitive choice, but our rows don't respond to hash and isEqual (nor do we want them to) so it isn't applicable
    if ([rowsToRemove count]) {
        rowEnumerator = [rowsToRemove objectEnumerator];
        while (row = [rowEnumerator nextObject]){
            [rowArray removeObjectIdenticalTo:row];
        }
        
        if (!lockFocus) {
            [self resetCursorRects];
            [self _resizeContents:YES];
        }
        
        [self setNeedsDisplay:YES];
    }
}



//Cursor Tracking -----------------------------------------------------------------------------------
//This method is automatically called when our size or position changes, allowing for our cells to
//re-configure any cursor tracking rects they've set up.
- (void)resetCursorRects
{
    if(!lockFocus){
        //Reset cursor tracking for our visible rect
        [self _resetCursorRectsForVisibleRect:[[self enclosingScrollView] documentVisibleRect]];
    }
}

//If we're being removed from the window, we need to remove our tracking rects
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if(newWindow == nil){
        //Remove cursor tracking (by passing an empty rect)
        [self _resetCursorRectsForVisibleRect:NSMakeRect(0,0,0,0)];
    }
}

//Reset cursor tracking for cells within the passed visible rect
//Pass an empty visible rect to remove all cursor tracking
- (void)_resetCursorRectsForVisibleRect:(NSRect)visibleRect
{
    NSPoint			cellPoint = contentOrigin;
    NSEnumerator		*rowEnumerator, *enumerator;
    AIFlexibleTableRow		*row;
    BOOL			foundVisible = NO;
    NSRect			documentVisibleRect;

    //Remove any existing cursor rects
    enumerator = [cursorTrackingRowArray objectEnumerator];
    while(row = [enumerator nextObject]){
        //Pass an empty visible rect to remove any cursor rects
        [row resetCursorRectsAtOffset:NSMakePoint(0,0) visibleRect:NSMakeRect(0,0,0,0) inView:self];
    }
    [cursorTrackingRowArray release]; cursorTrackingRowArray = [[NSMutableArray alloc] init];
    
    //Install new cursor rects
    if(visibleRect.size.width != 0 && visibleRect.size.height != 0){
        //Get our visible rect (we don't want to process non-visible rows)
        documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    
        //Enumerate through each row
        //We move from the bottom up, so we can avoid enumerating through rows that have scrolled out of view
        rowEnumerator = [rowArray objectEnumerator];
        while((row = [rowEnumerator nextObject])){
            int	rowHeight = [row height];
    
            cellPoint.y -= [row height];
    
            if(NSIntersectsRect(NSMakeRect(cellPoint.x, cellPoint.y, visibleRect.size.width, rowHeight), documentVisibleRect) || [row spansRows]){ //If visible

                if([row resetCursorRectsAtOffset:cellPoint visibleRect:visibleRect inView:self]){
                    [cursorTrackingRowArray addObject:row];
                }

                if(!foundVisible && ![row spansRows]) foundVisible = YES;
            }else{
                if(foundVisible) break; //Stop scanning once we hit a non-visible (after having drawn something)
            }
        }
    }
}


//Key/Paste Forwarding ---------------------------------------------------------------------------------
//When the user attempts to type into the table view, we push the keystroke to the next responder,
//and make it key.  This isn't required, but convienent behavior since one will never want to type
//into this view.  If the user attempts to scroll and we are inside an AIAutoScrollView
//we should pass the request to the scroll view.
- (void)keyDown:(NSEvent *)theEvent
{
	id superview = [self superview];
	
	while (superview && !([superview isKindOfClass:[AIAutoScrollView class]])){
		superview = [superview superview];
	}

	if (superview){
		NSString *charactersIgnoringModifiers = [theEvent charactersIgnoringModifiers];
		
		if ([charactersIgnoringModifiers length]) {
			unichar inChar = [charactersIgnoringModifiers characterAtIndex:0];
			
			if(inChar == NSUpArrowFunctionKey || inChar == NSDownArrowFunctionKey ||
			   inChar == NSPageUpFunctionKey || inChar == NSPageDownFunctionKey || 
			   inChar == NSHomeFunctionKey || inChar == NSEndFunctionKey){
				[[self superview] keyDown:theEvent];
			}else{
				[self forwardSelector:@selector(keyDown:) withObject:theEvent];
			}
		}else{
			[self forwardSelector:@selector(keyDown:) withObject:theEvent];	
		}
	}else{
		[self forwardSelector:@selector(keyDown:) withObject:theEvent];
	}
}
	
- (void)pasteAsPlainText:(id)sender
{
    [self forwardSelector:@selector(pasteAsPlainText:) withObject:sender];
}

- (void)pasteAsRichText:(id)sender
{
    [self forwardSelector:@selector(pasteAsRichText:) withObject:sender];
}

- (void)forwardSelector:(SEL)selector withObject:(id)object
{
    if(forwardsKeyEvents){
        id	responder = [self nextResponder];
        
        //Make the next responder key (When walking the responder chain, we want to skip ScrollViews and ClipViews).
        while(responder && ([responder isKindOfClass:[NSClipView class]] || [responder isKindOfClass:[NSScrollView class]])){
            responder = [responder nextResponder];
        }
        
        if(responder){
            [[self window] makeFirstResponder:responder]; //Make it first responder
            [responder tryToPerform:selector with:object]; //Pass it this key event
        }
        
    }else{
        [super tryToPerform:selector with:object]; //Pass it this key event
    }
}


//Cell, Column, and Row Access --------------------------------------------------------------------
//Returns a row by point
- (AIFlexibleTableRow *)_rowAtPoint:(NSPoint)inPoint rowOrigin:(NSPoint *)outOrigin
{
    NSEnumerator		*rowEnumerator;
    AIFlexibleTableRow		*row;

    *outOrigin = contentOrigin;

    //Determine the clicked row
    rowEnumerator = [rowArray objectEnumerator];
    while((row = [rowEnumerator nextObject])){
        (*outOrigin).y -= [row height];
        if(inPoint.y > (*outOrigin).y) return(row);
    }

    return(nil);
}

//Returns a row by index
- (AIFlexibleTableRow *)rowAtIndex:(int)index
{
    if(index >= 0 && index < [rowArray count]){
        return([rowArray objectAtIndex:index]);
    }else{
        return(nil);
    }
}


//Sizing calculations ------------------------------------------------------------------------------
//Recalculate our table view's dimensions so it completely fills the contianing scrollview's visible rect.
//If YES is passed, recalculates the size of all our rows as well.
- (void)_resizeContents:(BOOL)resizeContents
{
    if(!lockFocus){
        NSRect		    documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
        NSEnumerator	    *rowEnumerator;
        AIFlexibleTableRow  *row;
        NSSize		    size;
        
        //Get our view's new width
        size.width = documentVisibleRect.size.width;
        
        //Enumerate through each row, resizing it to the new width
        if(resizeContents){
            contentsHeight = topPadding + bottomPadding;
            rowEnumerator = [rowArray objectEnumerator];
            while((row = [rowEnumerator nextObject])){
                contentsHeight += [row sizeRowForWidth:size.width];
            }
        }
        
        //Resize our view
        [self _resizeViewToWidth:size.width height:contentsHeight];
    }
}

//Recalculate the size of an individual row
- (void)resizeRow:(AIFlexibleTableRow *)inRow
{
    //Resize the row
    contentsHeight -= [inRow height];
    contentsHeight += [inRow sizeRowForWidth:[self frame].size.width];
    
    //Resize our view
    if(!lockFocus){        
        [self _resizeViewToWidth:[self frame].size.width height:contentsHeight];
    }
}

//Resize our view to the passed dimensions
- (void)_resizeViewToWidth:(int)width height:(int)height
{
    NSRect	documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    NSSize	size;

    //Get our view's new dimensions
    size.width = width;
    size.height = height;
    if(size.height < documentVisibleRect.size.height){
        size.height = documentVisibleRect.size.height;
    }

    //Remember our content origin
    if(contentBottomAligned && contentsHeight < documentVisibleRect.size.height){
        contentOrigin = NSMakePoint(0, documentVisibleRect.size.height - bottomPadding);
    }else{
        contentOrigin = NSMakePoint(0, contentsHeight - bottomPadding);
    }

    //Resize our view, and redisplay
    if(!NSEqualSizes([self frame].size, size)){
        [self setFrameSize:size];
    }
    [self setNeedsDisplay:YES];
}

//
- (int)heightOfSpanCellsAboveRow:(AIFlexibleTableRow *)startRow
{
    AIFlexibleTableRow  *row;
    int rowIndex = [rowArray indexOfObject:startRow];
    int height = 0;

    do{
	row = [rowArray objectAtIndex:rowIndex];
	height += [row height];
    }while(++rowIndex < [rowArray count] && ![row spansRows]);
    
    return(height);
}


//Selecting ------------------------------------------------------------------------------
//Copy all selected content
- (void)copy:(id)sender
{    
    NSAttributedString *copyString = [self _selectedString];
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setData:[copyString RTFFromRange:NSMakeRange(0,[copyString length]) documentAttributes:nil] forType:NSRTFPboardType];
}

//Returns the currently selected string
- (NSAttributedString *)_selectedString
{
    NSMutableAttributedString	*selectedString = nil;
    NSEnumerator		*rowEnumerator;
    AIFlexibleTableRow		*row;
    NSAttributedString		*segment;

    //Enumerate through each row
    rowEnumerator = [rowArray reverseObjectEnumerator];
    while((row = [rowEnumerator nextObject])){
        if(segment = [row selectedString]){
            if(!selectedString) selectedString = [[[NSMutableAttributedString alloc] init] autorelease];
            [selectedString appendAttributedString:segment];
        }
    }

    //Each row appends a carriage return.  Remove the last one.
    int length = [[selectedString string] length];
    [selectedString deleteCharactersInRange:NSMakeRange(length-1,1)];
    
    return(selectedString);
}


@end

