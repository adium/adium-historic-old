/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AIFlexibleTableView.h"
#import "AIFlexibleTableCell.h"
#import "AIFlexibleTableColumn.h"

#define AUTOSCROLL_CATCH_SIZE 	20	//The distance (in pixels) that the scrollview must be within (from the bottom) for auto-scroll to kick in.

@interface AIFlexibleTableView (PRIVATE)
- (BOOL)isFlipped;
- (void)frameChanged:(NSNotification *)notification;
- (void)buildMessageCellArray;
- (BOOL)_addCellsForRow:(int)inRow;
- (BOOL)_removeCellsForRow:(int)inRow;
- (void)resizeContents;
- (void)resizeToFillContainerView;
- (void)_init;
- (void)_endEditing;
- (void)_setSelected:(BOOL)selected row:(int)inRow;
- (AIFlexibleTableCell *)cellAtPoint:(NSPoint)inPoint row:(int *)outRow column:(int *)outColumn;
- (void)deselectAll;
- (AIFlexibleTableColumn *)columnAtIndex:(int)index;

- (void)_resizeColumns;
- (void)_resizeRows;
- (void)_resizeCellsRowHeightsChanged:(BOOL)rowHeightsChanged;
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
    cursorTrackingCellArray = [[NSMutableArray alloc] init];
    columnArray = [[NSMutableArray alloc] init];
    delegate = nil;
    contentsHeight = 0;
    selectedRow = -1;
    editor = nil;
    editorScroll = nil;
    editedColumn = nil;
    editedRow = -1;
    oldWidth = 0;
    
    contentBottomAligned = YES;
    scrollsOnNewContent = YES;

    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:self];
}


//Config -------------------------------------------------------------------------------
//Set the content cells bottom aligned
- (void)setContentBottomAligned:(BOOL)inValue{
    contentBottomAligned = inValue;
}

//YES for auto-scroll functionality
- (void)setScrollsOnNewContent:(BOOL)inValue{
    scrollsOnNewContent = inValue;
}


//Drawing -------------------------------------------------------------------------------
//Draw
- (void)drawRect:(NSRect)rect
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    NSRect			cellFrame = NSMakeRect(0, 0, 0, 0);
    NSRect			documentVisibleRect;

    //Get our visible rect (we don't want to draw non-visible cells)
    documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];

    //Enumerate through each column
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        NSEnumerator		*cellEnumerator;
        NSEnumerator		*rowHeightEnumerator;
        AIFlexibleTableCell	*cell;
        
	//Enumerate through each cell
        rowHeightEnumerator = [rowHeightArray objectEnumerator];
        cellEnumerator = [[column cellArray] objectEnumerator];
        while((cell = [cellEnumerator nextObject])){
            //Get the cell frame, and adjust it for our start origin
            cellFrame = [cell frame];

            //Only draw visible cells
            if(NSIntersectsRect(documentVisibleRect,cellFrame)){ 
                [cell drawWithFrame:cellFrame inView:self];
            }
        }
    }
}


//Clicking --------------------------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
{
    AIFlexibleTableCell		*cell;
    int				row, column;
    NSPoint			clickLocation;

    //Determine the clicked cell/row/column
    clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    cell = [self cellAtPoint:clickLocation row:&row column:&column];

    //Give the cell a chance to process the mouse down.  If it returns YES, we ignore the event.
    if(![cell mouseDown:theEvent]){
        //Select the row
        [self selectRow:row];
    
        //Text selection
        {
            NSPoint			localPoint;
    
            //Deselect all text
            [self deselectAll];
    
            //Set the new selection start and end
            localPoint = NSMakePoint(clickLocation.x - [cell frame].origin.x, clickLocation.y - [cell frame].origin.y);
            selection_startRow = row;
            selection_startColumn = column;
            selection_startIndex = [cell characterIndexAtPoint:localPoint];
            selection_endRow = selection_startRow;
            selection_endColumn = selection_startColumn;
            selection_endIndex = selection_startIndex;
            
            //Redisplay
            [self setNeedsDisplay:YES];
        }
    
        //Open the selected cell for editing (If this was a double click)
        if([theEvent clickCount] >= 2){
            [self editRow:row column:[self columnAtIndex:column]];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{

}

//Enable/disable mouse moved events
- (void)setAcceptsMouseMovedEvents:(BOOL)flag
{
    [[self window] setAcceptsMouseMovedEvents:flag];
}

//pass mouse moved events to the hovered cell
- (void)mouseMoved:(NSEvent *)theEvent
{
    AIFlexibleTableCell		*cell;
    int				row, column;
    NSPoint			hoverLocation;

    //Determine the clicked cell/row/column
    hoverLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    cell = [self cellAtPoint:hoverLocation row:&row column:&column];

    [cell mouseMoved:theEvent];
}



//Selecting --------------------------------------------------------------------------------
- (void)deselectAll
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;

    //Enumerate through each column
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        NSEnumerator		*cellEnumerator;
        AIFlexibleTableCell	*cell;

        //Enumerate through each cell
        cellEnumerator = [[column cellArray] objectEnumerator];
        while((cell = [cellEnumerator nextObject])){
            [cell selectFrom:0 to:0];
        }
    }
}

- (void)clear:(id)sender
{
    NSLog(@"clear");
}

- (void)selectAll:(id)sender
{
    NSLog(@"selectAll");
}

- (void)copy:(id)sender
{
    NSMutableAttributedString	*copyString = [[NSMutableAttributedString alloc] init];
    AIFlexibleTableCell		*startCell, *endCell;
    int				row, column;

    //Select partial text in the start and end cells
    startCell = [[self columnAtIndex:selection_startColumn] cellAtIndex:selection_startRow];

    //Select text in the first cell
    if(selection_startRow == selection_endRow && selection_startColumn == selection_endColumn){ //The selection exists completely within one cell
        [copyString appendAttributedString:[startCell stringFromIndex:selection_startIndex to:selection_endIndex]];

    }else if(selection_startRow < selection_endRow){ //The start cell is above the end cell
        [copyString appendAttributedString:[startCell stringFromIndex:selection_startIndex to:10000]];

    }else if(selection_startRow > selection_endRow){ //The start cell is below the end cell
        [copyString appendAttributedString:[startCell stringFromIndex:selection_startIndex to:0]];

    }
    
    //Select all text in every cell between start and end
    for(column = ((selection_startColumn < selection_endColumn) ? selection_startColumn : selection_endColumn);
        column <= ((selection_startColumn < selection_endColumn) ? selection_endColumn : selection_startColumn);
        column++){
        for(row = ((selection_startRow < selection_endRow) ? selection_startRow : selection_endRow);
            row <= ((selection_startRow < selection_endRow) ? selection_endRow : selection_startRow);
            row++){

            if(!(row == selection_startRow && column == selection_startColumn) && !(row == selection_endRow && column == selection_endColumn)){ //Skip the first and last cells in the selection block
                AIFlexibleTableCell	*cell = [[self columnAtIndex:column] cellAtIndex:row];
                [copyString appendAttributedString:[cell stringFromIndex:0 to:10000]];
                [copyString appendString:@"\r" withAttributes:nil];
            }
        }
    }

    //Select text in the last cell
    endCell =[[self columnAtIndex:selection_endColumn] cellAtIndex:selection_endRow];
    if(selection_startRow < selection_endRow){ //The start cell is above the end cell
        [copyString appendAttributedString:[endCell stringFromIndex:0 to:selection_endIndex]];

    }else if(selection_startRow > selection_endRow){ //The start cell is below the end cell
        [copyString appendAttributedString:[endCell stringFromIndex:10000 to:selection_endIndex]];

    }

    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setData:[copyString RTFFromRange:NSMakeRange(0,[copyString length]) documentAttributes:nil] forType:NSRTFPboardType];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    AIFlexibleTableCell		*cell;
    AIFlexibleTableCell		*startCell = nil, *endCell = nil;
    int				row, column;
    NSPoint			clickLocation;

    //Determine the clicked cell/row/column
    clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    cell = [self cellAtPoint:clickLocation row:&row column:&column];

    //Remove all current selections
    [self deselectAll];
    
    //Save the new selection end information
    selection_endIndex = [cell characterIndexAtPoint:NSMakePoint(clickLocation.x - [cell frame].origin.x, clickLocation.y - [cell frame].origin.y)];
    selection_endRow = row;
    selection_endColumn = column;

    //Select partial text in the start and end cells
    startCell = [[self columnAtIndex:selection_startColumn] cellAtIndex:selection_startRow];
    endCell = [[self columnAtIndex:selection_endColumn] cellAtIndex:selection_endRow];    
    
    if(selection_startRow == selection_endRow && selection_startColumn == selection_endColumn){ //The selection exists completely within one cell
        [startCell selectFrom:selection_startIndex to:selection_endIndex];

    }else if(selection_startRow < selection_endRow || selection_startColumn < selection_endColumn){ //The start cell is above or left of the end cell
        [startCell selectFrom:selection_startIndex to:10000]; //insert generic big number here
        [endCell selectFrom:0 to:selection_endIndex];
        
    }else if(selection_startRow > selection_endRow || selection_startColumn > selection_endColumn){ //The start cell is below or right of the end cell
        [startCell selectFrom:selection_startIndex to:0];
        [endCell selectFrom:10000 to:selection_endIndex]; //insert generic big number here
        
    }

    //Select all text in every cell between start and end
    //These loops are conditioned so that they always run top to bottom, left to right (Allowing selection to occur in any direction)
    //We want to run through every cell within the selection block except the first and last cell (which have already been processed)
    for(column = ((selection_startColumn < selection_endColumn) ? selection_startColumn : selection_endColumn);
        column <= ((selection_startColumn < selection_endColumn) ? selection_endColumn : selection_startColumn);
        column++){
        for(row = ((selection_startRow < selection_endRow) ? selection_startRow : selection_endRow);
            row <= ((selection_startRow < selection_endRow) ? selection_endRow : selection_startRow);
            row++){

            if(!(row == selection_startRow && column == selection_startColumn) && !(row == selection_endRow && column == selection_endColumn)){ //Skip the first and last cells in the selection block
                AIFlexibleTableCell	*cell = [[self columnAtIndex:column] cellAtIndex:row]; 
                [cell selectFrom:0 to:10000]; //insert generic big number here
            }
        }
    }

    //Mark our view for redisplay
    [self setNeedsDisplay:YES];
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

//Redisplay when we become first responder
- (BOOL)becomeFirstResponder
{
    [self setNeedsDisplay:YES];
    return(YES);
}

//Redisplay and end editing when we lose first responder
- (BOOL)resignFirstResponder
{
    [self setNeedsDisplay:YES];
    [self _endEditing];
    return(YES);
}

//Return yes so our view's origin is in the top left
- (BOOL)isFlipped{
    return(YES);
}

//Called when the frame changes.  Adjust to fill the new frame
- (void)frameChanged:(NSNotification *)notification
{
    //Resize our cells
    //To make things faster, we only resize our contents if the width changed (requiring a column/cell resize), or if our view doesn't fully fill it's containing scrollview vertically (requiring a resize to keep the content bottom-aligned).
    if([self frame].size.width != oldWidth || !([self frame].size.height > [[self enclosingScrollView] documentVisibleRect].size.height)){
        [self resizeContents];
    }
    oldWidth = [self frame].size.width;
    
    //Resize ourself vertically and redisplay
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//called when a live resize ends, perform a full resize
- (void)viewDidEndLiveResize
{
    //Resize our cells, our view vertically, and redisplay
    [self resizeContents];
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}



//Delegate / Content -------------------------------------------------------------------------------
//Set our delegate
- (void)setDelegate:(id <AIFlexibleTableViewDelegate>)inDelegate
{
    if(inDelegate != delegate){
        [delegate release]; delegate = nil;
        delegate = [inDelegate retain];

        respondsTo_shouldEditTableColumn = [delegate respondsToSelector:@selector(shouldEditTableColumn:row:)];
        respondsTo_setObjectValue = [delegate respondsToSelector:@selector(setObjectValue:forTableColumn:row:)];
        respondsTo_shouldSelectRow = [delegate respondsToSelector:@selector(shouldSelectRow:)];
    }
}

//Add a Column
- (void)addColumn:(AIFlexibleTableColumn *)inColumn
{
    [columnArray addObject:inColumn];

    //If this column is flexible, mark it as our flexible column (used by other parts of the code)
    if([inColumn flexibleWidth]){
        flexibleColumn = inColumn;
    }
}

//Load the content in a newly added row (Quicker than doing a full reload of the content)
- (void)loadNewRow
{
    //Add the new content
    //To make things run faster, we can skip resizing of our contents if these conditions are true:
    // - The column widths do not change (signified by _addCellsForRow returning YES)
    // - Our view fully fill its scrollview vertically (otherwise we need to resize to keep our cells bottom aligned)
    if([self _addCellsForRow:([delegate numberOfRows] - 1)] || !([self frame].size.height > [[self enclosingScrollView] documentVisibleRect].size.height)){
        [self resizeContents];
    }

    //Resize and redisplay
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Call when the data is changed, reloads the content of all cells
- (void)reloadData
{
    NSEnumerator		*enumerator;
    AIFlexibleTableColumn	*column;
    AIFlexibleTableCell		*cell;
    int				numberOfRows = [delegate numberOfRows];
    int				row;

    //End editing
    [self _endEditing];

    //Reset all cursor tracking
    enumerator = [cursorTrackingCellArray objectEnumerator];
    while((cell = [enumerator nextObject])){
        [cell resetCursorRectsInView:self visibleRect:NSMakeRect(0,0,0,0)]; //Remove any current tracking rects for this cell
    }
    [cursorTrackingCellArray release]; cursorTrackingCellArray = [[NSMutableArray alloc] init]; //Flush the list of tracking cells

    //Remove all existing cells
    enumerator = [columnArray objectEnumerator];
    while((column = [enumerator nextObject])){
        [column removeAllCells];
    }

    //Rebuild our content
    for(row = 0;row < numberOfRows;row++){
        [self _addCellsForRow:row];
    }

    //Resize and redisplay
    [self resizeContents];
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Reload the content of a single row
- (void)reloadRow:(int)inRow
{
    //Remove the row and add the new cells
    if([self _removeCellsForRow:inRow] || [self _addCellsForRow:inRow]){
        [self resizeContents];
    }

    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}


//Cursor Tracking -----------------------------------------------------------------------------------
//This method is automatically called when our size or position changes, allowing for our cells to re-configure any cursor tracking rects they've set up.
- (void)resetCursorRects
{
    NSRect			documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    NSEnumerator		*enumerator;
    AIFlexibleTableCell		*cell;

    //Loop through all cursor-tracking cells, informing them of the cursor rect reset
    enumerator = [cursorTrackingCellArray objectEnumerator];
    while((cell = [enumerator nextObject])){
        [cell resetCursorRectsInView:self visibleRect:documentVisibleRect];
    }
}


//Key Forwarding ---------------------------------------------------------------------------------
//When the user attempts to type into the table view, we push the keystroke to the next responder, and make it key.  This isn't required, but convienent behavior since one will never want to type into this view.
- (void)keyDown:(NSEvent *)theEvent
{
    id	responder = [self nextResponder];
    NSLog(@"keyDown");
    //Make the next responder key (When walking the responder chain, we want to skip ScrollViews and ClipViews).
    while(responder && ([responder isKindOfClass:[NSClipView class]] || [responder isKindOfClass:[NSScrollView class]])){
        NSLog(@"  %@",responder);
        responder = [responder nextResponder];
    }

    NSLog(@" *%@",responder);
    if(responder){
        [[self window] makeFirstResponder:responder]; //Make it first responder
        [[self nextResponder] tryToPerform:@selector(keyDown:) with:theEvent]; //Pass it this key event
    }
}





//Row Selection ---------------------------------------------------------------------------------
//Open a specified row/column for editing
- (void)selectRow:(int)inRow
{
    if(inRow < 0 || inRow >= [delegate numberOfRows]){
        inRow = -1; //No selection
    }

    if(respondsTo_shouldSelectRow && [(id <AIFlexibleTableViewDelegate_shouldSelectRow>)delegate shouldSelectRow:inRow]){
        //Close any existing editor
        [self _endEditing];

        //Deselect the existing selection
        if(selectedRow != -1) [self _setSelected:NO row:selectedRow];

        //Select the new row
        if(inRow != -1) [self _setSelected:YES row:inRow];
        selectedRow = inRow;
    }

}

//Move selection up
- (void)moveUp:(id)sender
{
    if(selectedRow > 0){
        [self selectRow:selectedRow - 1];
    }
}

//Move selection down
- (void)moveDown:(id)sender
{
    if(selectedRow < [rowHeightArray count] - 1){
        [self selectRow:selectedRow + 1];
    }
}

//Returns the selected row
- (int)selectedRow
{
    return(selectedRow);
}

//Toggle the selection of a row
- (void)_setSelected:(BOOL)selected row:(int)inRow
{
    NSEnumerator		*enumerator;
    AIFlexibleTableColumn	*column;

    enumerator = [columnArray objectEnumerator];
    while((column = [enumerator nextObject])){
        NSArray			*cellArray = [column cellArray];

        if(inRow >= 0 && inRow < [cellArray count]){
            AIFlexibleTableCell	*cell = [cellArray objectAtIndex:inRow];

            [cell setSelected:selected];
            [self setNeedsDisplayInRect:[cell frame]];
        }
    }
}


//Cell Editing --------------------------------------------------------------------
//Open a specified row/column for editing
- (void)editRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn
{
    if(inRow >= 0 && inRow < [delegate numberOfRows]){
        if(respondsTo_shouldEditTableColumn && [(id <AIFlexibleTableViewDelegate_shouldEditTableColumn>)delegate shouldEditTableColumn:inColumn row:inRow]){
            AIFlexibleTableCell	*cell;

            //Get the cell targeted for editing
            cell = [[inColumn cellArray] objectAtIndex:inRow];

            //Close any existing editor
            [self _endEditing];

            [cell editAtRow:inRow column:inColumn inView:self];
            editedCell = cell;
            editedColumn = inColumn;
            editedRow = inRow;
        }
    }
}

//Cancel any existing editing
- (void)_endEditing
{
    if(editedCell){
        //Close & Save
        if(respondsTo_setObjectValue){
            [(id <AIFlexibleTableViewDelegate_setObjectValue>)delegate setObjectValue:[editedCell endEditing] forTableColumn:editedColumn row:editedRow];
        }

        //Reload
        [self reloadRow:editedRow];
        editedCell = nil;
        editedRow = 0;
        editedColumn = nil;
    }
}


//Cell, Column, and Row Access --------------------------------------------------------------------
//Returns the specified column
- (AIFlexibleTableColumn *)columnAtIndex:(int)index
{
    if(index >= 0 && index < [columnArray count]){
        return([columnArray objectAtIndex:index]);
    }else{
        return(nil);
    }
}

//Returns the cell and column index at the passed point
- (AIFlexibleTableCell *)cellAtPoint:(NSPoint)inPoint row:(int *)outRow column:(int *)outColumn
{
    NSRect			documentVisibleRect;
    NSEnumerator		*enumerator;
    AIFlexibleTableColumn	*column;
    int				width = 0;
    NSNumber			*rowHeight;
    int				height = 0;
    int				targetedRow = 0;
    int				targetedColumn = 0;

    //The cell check is broken by the bottom aligning offset, so we need to adjust our calculations
    documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    if(contentBottomAligned && contentsHeight < documentVisibleRect.size.height){
        height = (documentVisibleRect.size.height - contentsHeight);
    }

    //Determine the row that was clicked
    enumerator = [rowHeightArray objectEnumerator];
    while((rowHeight = [enumerator nextObject])){
        height += [rowHeight intValue];
        if(height > inPoint.y) break;
        targetedRow++;
    }

    //Determine the column that was clicked
    enumerator = [columnArray objectEnumerator];
    while((column = [enumerator nextObject])){
        width += [column width];
        if(width > inPoint.x) break;
        targetedColumn++;
    }

    //Return the row, column, and cell
    if(outRow) *outRow = targetedRow;
    if(outColumn) *outColumn = targetedColumn;
    if(column && targetedRow >= 0 && targetedRow < [[column cellArray] count]){
        return([[column cellArray] objectAtIndex:targetedRow]);
    }else{
        return(nil);
    }
}

//Removes a row of cells.  Returns YES if the other cells should be resized in response.
- (BOOL)_removeCellsForRow:(int)inRow
{
    BOOL			columnWidthDidChange = NO;
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;

    //Remove the cell from each column
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        AIFlexibleTableCell	*cell = [column cellAtIndex:inRow];

        //If this cell is tracking the cursor, we must reset its cursor rects and remove it from our tracking array.
        if([cursorTrackingCellArray containsObject:cell]){
            [cell resetCursorRectsInView:self visibleRect:NSMakeRect(0,0,0,0)];
            [cursorTrackingCellArray removeObject:cell];
        }

        //Remove the cell
        if([column removeCellAtRow:inRow]){ //Returns YES if the column's width was changed
            columnWidthDidChange = YES;
        }
    }

    contentsHeight -= [[rowHeightArray objectAtIndex:inRow] intValue];
    [rowHeightArray removeObjectAtIndex:inRow];

    return(columnWidthDidChange); //Return YES if the cells should be resized
}

//Add a row of cells.  Returns YES if the other cells should be resized in response.
- (BOOL)_addCellsForRow:(int)inRow
{
    NSRect			documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    BOOL			columnWidthDidChange = NO;
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				newRowHeight = 0;
    NSRect			cellFrame;
    
    //Process each column, adding a cell to each one
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        AIFlexibleTableCell	*cell = [delegate cellForColumn:column row:inRow];

        if(cell){
            //Add the cell, recording if column width changed (so we can return YES indicating a resize is necessary)
            columnWidthDidChange = [column addCell:cell forRow:inRow];
            [cell setTableView:self];

            //By comparing the heights of each cell, we find the largest height and set it as the height of our row
            if([cell cellSize].height > newRowHeight){
                newRowHeight = [cell cellSize].height;
            }

            //If this cell tracks the cursor, reset its cursor rects and add it to our tracking array
            if([cell resetCursorRectsInView:self visibleRect:documentVisibleRect]){
                [cursorTrackingCellArray addObject:cell];
            }
        }
    }

    //Go back through and correctly set the frames of the cells we just added
    //This avoids having to call resizeContents when adding new rows, speeding things up quite a bit.
    cellFrame.origin.x = 0;
    cellFrame.origin.y = contentsHeight; //Start at the bottom of our view
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        AIFlexibleTableCell	*cell = [column cellAtIndex:inRow];

        cellFrame.size.width = [column width];
        cellFrame.size.height = newRowHeight;
        [cell setFrame:cellFrame]; //Set the cell's frame

        cellFrame.origin.x += [column width]; //Move to the next column
    }

    //Add this row's height to our array, and increase our total contents height to include it
    [rowHeightArray insertObject:[NSNumber numberWithInt:newRowHeight] atIndex:inRow];
    contentsHeight += newRowHeight;
    
    return(columnWidthDidChange); //Return YES if the other cells should be resized
}


//Sizing calculations ------------------------------------------------------------------------------
//Recalculate our table view's dimensions so it completely fills the contianing scrollview's visible rect
- (void)resizeToFillContainerView
{
    NSScrollView		*enclosingScrollView;
    NSRect			documentVisibleRect;
    BOOL			autoScroll = NO;
    NSSize			size;

    //Before resizing the view, we decide if the user is close to the bottom of our view.  If they are, we want to keep them at the bottom no matter what happens during the resize.
    if(scrollsOnNewContent){
        enclosingScrollView = [self enclosingScrollView];
        documentVisibleRect = [enclosingScrollView documentVisibleRect];
        autoScroll = ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > ([self frame].size.height - AUTOSCROLL_CATCH_SIZE));
    }

    //Resize our view
    size.width = documentVisibleRect.size.width;
    size.height = contentsHeight;
    if(size.height < documentVisibleRect.size.height){
        size.height = documentVisibleRect.size.height;
    }
    if(!NSEqualSizes([self frame].size, size)){
        [self setFrameSize:size];
    }

    //If the user was near the bottom, move them back to the bottom (autoscroll)
    if(autoScroll){
        [[enclosingScrollView contentView] scrollToPoint:NSMakePoint(0, [self frame].size.height - documentVisibleRect.size.height)];
        [enclosingScrollView reflectScrolledClipView:[enclosingScrollView contentView]];
    }
}

//Resize our columns, rows, and cells so everything is visible and correctly positioned
- (void)resizeContents
{    
    //Resize our columns first
    [self _resizeColumns];

    //During a live resize, we don't recalcluate row heights to give things a little speed boost
    if([self inLiveResize]){
        [self _resizeCellsRowHeightsChanged:NO];
    }else{
        [self _resizeRows];
        [self _resizeCellsRowHeightsChanged:YES];
    }

    //Reset our tracking rects
    [self resetCursorRects];
}

//Adjust the height of an existing row
- (void)setHeightOfCellAtRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn to:(int)inHeight
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				newRowHeight = 0;

    //We subtract this row's height from our total, recalculate the new required row height, then add the new height back the total.
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        int	cellHeight;

        if(column != inColumn){
            cellHeight = [[[column cellArray] objectAtIndex:inRow] cellSize].height;
        }else{
            cellHeight = inHeight;
        }

        if(cellHeight > newRowHeight){
            newRowHeight = cellHeight;
        }
    }

    [rowHeightArray replaceObjectAtIndex:inRow withObject:[NSNumber numberWithInt:newRowHeight]];

    //Resize and redisplay
    [self resizeToFillContainerView];
    [self resizeContents];
    [self setNeedsDisplay:YES];
}

//Resize the columns
- (void)_resizeColumns
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				columnWidth = [self frame].size.width;

    //This enumeration is to determine the remaining table width (total width - width of every fixed-width column)
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        if(![column flexibleWidth]){
            columnWidth -= [column width];
        }
    }

    //Set the width of our flexible column to the remainding width
    if(flexibleColumn){
        [flexibleColumn setWidth:columnWidth];
    }
}

//Recalculate our row heights
- (void)_resizeRows
{
    NSEnumerator		*rowHeightEnumerator, *columnEnumerator, *cellEnumerator;
    AIFlexibleTableColumn	*column;
    AIFlexibleTableCell		*cell;
    NSNumber			*rowHeight;
    int 			columnWidth;

    //Reset the row height array
    [rowHeightArray release]; rowHeightArray = [[NSMutableArray alloc] init];

    //Since the flexible column is most likely to determine the height of each row, we use the height of its cells to fill the row height array.
    columnWidth = [flexibleColumn width];
    cellEnumerator = [[flexibleColumn cellArray] objectEnumerator];
    while((cell = [cellEnumerator nextObject])){
        [cell sizeCellForWidth:columnWidth]; //Resize the cell to fit its column width
        [rowHeightArray addObject:[NSNumber numberWithInt:[cell cellSize].height]]; //The resulting height will be the new row height
    }

    //After the height array is filled, we process the other columns and correct any instances where the flexible column's cells were not the tallest
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        if(column != flexibleColumn){ //We've already processed the flexible column
            NSEnumerator	*cellEnumerator;
            AIFlexibleTableCell	*cell;
            int			rowIndex = 0;

            //Step through each cell in this column
            columnWidth = [column width];
            rowHeightEnumerator = [rowHeightArray objectEnumerator];
            cellEnumerator = [[column cellArray] objectEnumerator];
            while((cell = [cellEnumerator nextObject])){
                int	cellHeight, existingHeight;
                
                [cell sizeCellForWidth:columnWidth]; //Resize the cell to fit its column width

                //Check the cell's height
                cellHeight = [cell cellSize].height;
                existingHeight = [[rowHeightEnumerator nextObject] intValue];
                if(cellHeight > existingHeight){ //The row height is too small to fit this cell, correct it
                    [rowHeightArray replaceObjectAtIndex:rowIndex withObject:[NSNumber numberWithInt:cellHeight]];
                }

                rowIndex++;
            }
        }
    }

    //Recalculate our total height
    contentsHeight = 0;
    rowHeightEnumerator = [rowHeightArray objectEnumerator];
    while((rowHeight = [rowHeightEnumerator nextObject])){
        contentsHeight += [rowHeight intValue];
    }
}

//Resize all our cells
//If row heights have not been changed since the last resize, pass NO and this method will perform faster.
- (void)_resizeCellsRowHeightsChanged:(BOOL)rowHeightsChanged
{
    NSEnumerator		*rowHeightEnumerator;
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    NSRect			cellFrame;

    cellFrame.origin.x = 0; //Start our cell frames on the left

    NSRect			documentVisibleRect;
    int				startOriginY = 0;

    //If there isn't enough content to fill our entire view, we move down so the content is bottom-aligned
    documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    if(contentBottomAligned && contentsHeight < documentVisibleRect.size.height){
        startOriginY = (documentVisibleRect.size.height - contentsHeight);
    }

    //Go through each column
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        NSEnumerator		*cellEnumerator;
        AIFlexibleTableCell	*cell;

        //Start our cell frames at the top for this new column
        cellFrame.origin.y = startOriginY;//0;
        cellFrame.size.width = [column width];

        //If row heights need to be reset, we set up an enumerator on the row height array
        if(rowHeightsChanged) rowHeightEnumerator = [rowHeightArray objectEnumerator];

        //Go through each cell
        cellEnumerator = [[column cellArray] objectEnumerator];
        while((cell = [cellEnumerator nextObject])){
            if(!rowHeightsChanged){ //We can assume the row height has not changed, and use the existing height
                cellFrame.size.height = [cell frame].size.height;
            }else{ //Otherwise we must fetch the row height from our array
                cellFrame.size.height = [[rowHeightEnumerator nextObject] intValue];
            }

            //Set the cell's new frame
            [cell setFrame:cellFrame];
            cellFrame.origin.y += cellFrame.size.height;
        }

        cellFrame.origin.x += cellFrame.size.width;
    }
}


@end

