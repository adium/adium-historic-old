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
- (BOOL)addCellsForRow:(int)inRow;
- (BOOL)removeCellsForRow:(int)inRow;
- (void)resizeCells;
- (void)resizeToFillContainerView;
- (void)_init;
- (void)endEditing;
- (void)setSelected:(BOOL)selected row:(int)inRow;
- (AIFlexibleTableCell *)cellAtPoint:(NSPoint)inPoint row:(int *)outRow column:(int *)outColumn;
- (void)deselectAll;
- (AIFlexibleTableColumn *)columnAtIndex:(int)index;
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
    columnArray = [[NSMutableArray alloc] init];
    delegate = nil;
    contentsHeight = 0;
    selectedRow = -1;
    oldWidth = 0;
    editor = nil;
    editorScroll = nil;
    editedColumn = nil;
    editedRow = -1;

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
}

//Call after adding a new row
- (void)loadNewRow
{
    //Add the new content
    if([self addCellsForRow:([delegate numberOfRows] - 1)]){
        [self resizeCells];
    }

    //Resize and redisplay
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Call when the data is changed, reloads all the cells
- (void)reloadData
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				numberOfRows = [delegate numberOfRows];
    int				row;

    //End editing
    [self endEditing];

    //Remove all existing cells
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        [column removeAllCells];
    }

    //Add a cell to each column
    for(row = 0;row < numberOfRows;row++){
        [self addCellsForRow:row];
    }

    //Resize and redisplay
    [self resizeCells];
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Reload a single row
- (void)reloadRow:(int)inRow
{
    BOOL	shouldResizeCells = NO;
    
    //Remove the row
    if([self removeCellsForRow:inRow]){
        shouldResizeCells = YES;
    }
    
    //add the new cells
    if([self addCellsForRow:inRow]){
        shouldResizeCells = YES;
    }

    //Resize and redisplay
    if(shouldResizeCells){
        [self resizeCells];
    }
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Set the height of a cell
- (void)setHeightOfCellAtRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn to:(int)inHeight
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				newRowHeight = 0;

    //We subtract this row's height from our total, recalculate the new required row height, then add the new height back the total.
    contentsHeight -= [[rowHeightArray objectAtIndex:inRow] intValue];

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

    contentsHeight += newRowHeight;
    [rowHeightArray replaceObjectAtIndex:inRow withObject:[NSNumber numberWithInt:newRowHeight]];

    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}


//Drawing -------------------------------------------------------------------------------
//Draw
- (void)drawRect:(NSRect)rect
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    NSRect			cellFrame = NSMakeRect(0, 0, 0, 0);
    NSRect			documentVisibleRect;
    int				startOriginY = 0;

    //If there isn't enough content to fill our entire view, we move down so the content is bottom-aligned
    documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    if(contentBottomAligned && contentsHeight < documentVisibleRect.size.height){
        startOriginY = (documentVisibleRect.size.height - contentsHeight);
    }

    //Enumerate through each column
    cellFrame.origin.x = 0;
    
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        NSEnumerator		*cellEnumerator;
        NSEnumerator		*rowHeightEnumerator;
        AIFlexibleTableCell	*cell;

        cellFrame.origin.y = startOriginY;
        cellFrame.size.width = [column width];

	//Enumerate through each cell
        rowHeightEnumerator = [rowHeightArray objectEnumerator];
        cellEnumerator = [[column cellArray] objectEnumerator];
        while((cell = [cellEnumerator nextObject])){            
            cellFrame.size.height = [[rowHeightEnumerator nextObject] intValue]; //Get the row's height

            if(NSIntersectsRect(documentVisibleRect,cellFrame)){ //Only draw visible cells
                [cell drawWithFrame:cellFrame inView:self];
            }
                
            //Next cell
            cellFrame.origin.y += cellFrame.size.height;
        }

        //Next Column
        cellFrame.origin.x += cellFrame.size.width;
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

- (void)mouseUp:(NSEvent *)theEvent
{
    
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



//Row Selection ---------------------------------------------------------------------------------
//Open a specified row/column for editing
- (void)selectRow:(int)inRow
{
    if(inRow < 0 || inRow >= [delegate numberOfRows]){
        inRow = -1; //No selection
    }

    if(respondsTo_shouldSelectRow && [(id <AIFlexibleTableViewDelegate_shouldSelectRow>)delegate shouldSelectRow:inRow]){
        //Close any existing editor
        [self endEditing];
    
        //Deselect the existing selection
        if(selectedRow != -1) [self setSelected:NO row:selectedRow];

        //Select the new row
        if(inRow != -1) [self setSelected:YES row:inRow];
        selectedRow = inRow;
    }

}

//Toggle the selection of a row
- (void)setSelected:(BOOL)selected row:(int)inRow
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

//returns the selected row
- (int)selectedRow
{
    return(selectedRow);
}

- (void)moveUp:(id)sender
{
    if(selectedRow > 0){
        [self selectRow:selectedRow - 1];
    }
}

- (void)moveDown:(id)sender
{
    if(selectedRow < [rowHeightArray count] - 1){
        [self selectRow:selectedRow + 1];
    }
}


//Row Editing ---------------------------------------------------------------------------------
//Open a specified row/column for editing
- (void)editRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn
{
    if(inRow >= 0 && inRow < [delegate numberOfRows]){
        if(respondsTo_shouldEditTableColumn && [(id <AIFlexibleTableViewDelegate_shouldEditTableColumn>)delegate shouldEditTableColumn:inColumn row:inRow]){
            AIFlexibleTableCell	*cell;
    
            //Get the cell targeted for editing
            cell = [[inColumn cellArray] objectAtIndex:inRow];

            //Close any existing editor
            [self endEditing];

            [cell editAtRow:inRow column:inColumn inView:self];
            editedCell = cell;
            editedColumn = inColumn;
            editedRow = inRow;
        }
    }
}

//Cancel any existing editing
- (void)endEditing
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

- (BOOL)needsPanelToBecomeKey
{
    return(YES);
}

- (BOOL)acceptsFirstResponder
{
    return(YES);
}

- (BOOL)becomeFirstResponder
{
    [self setNeedsDisplay:YES];
    return(YES);
}

- (BOOL)resignFirstResponder
{
    [self setNeedsDisplay:YES];
    [self endEditing];
    return(YES);
}


//Private --------------------------------------------------------------------------------
//Return yes so our view's origin is in the top left
- (BOOL)isFlipped{
    return(YES);
}

//Called when the frame changes.  Adjust to fill the new frame
- (void)frameChanged:(NSNotification *)notification
{
    //If our width changed, resize our cells
    if([self frame].size.width != oldWidth){
        [self resizeCells];
        oldWidth = [self frame].size.width;
    }
    
    //Resize ourself vertically and redisplay
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

- (void)viewDidEndLiveResize
{
    //Resize our cells, our view vertically, and redisplay
    [self resizeCells];
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Add a row of cells.  Returns YES if the cells should be resized
- (BOOL)addCellsForRow:(int)inRow
{
    BOOL			columnWidthDidChange = NO;
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				newRowHeight = 0;
    
    //Add a cell to each column
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        AIFlexibleTableCell	*cell = [delegate cellForColumn:column row:inRow];

        if([column addCell:cell forRow:inRow]){ //Returns YES if the column's width was changed
            columnWidthDidChange = YES;
        }

        [cell setTableView:self];

        //By comparing the heights of each cell, we find the largest height and set it as the height of our row
        if([cell cellSize].height > newRowHeight){
            newRowHeight = [cell cellSize].height;
        }
    }

    [rowHeightArray insertObject:[NSNumber numberWithInt:newRowHeight] atIndex:inRow];
    contentsHeight += newRowHeight;

    return(columnWidthDidChange); //Return YES if the cells should be resized
}

//Removes a row of cells.  Returns YES if the cells should be resized
- (BOOL)removeCellsForRow:(int)inRow
{
    BOOL			columnWidthDidChange = NO;
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;

    //Remove the cell from each column
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        if([column removeCellAtRow:inRow]){ //Returns YES if the column's width was changed
            columnWidthDidChange = YES;
        }
    }

    contentsHeight -= [[rowHeightArray objectAtIndex:inRow] intValue];
    [rowHeightArray removeObjectAtIndex:inRow];

    return(columnWidthDidChange); //Return YES if the cells should be resized
}


//Recalculate the dimensions of all our cells
- (void)resizeCells
{ //This code only works with one flexible column for now...
    NSEnumerator		*rowHeightEnumerator;
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				columnWidth = [self frame].size.width;
    AIFlexibleTableColumn	*flexibleColumn = nil;
    NSNumber			*rowHeight;

    //add up the column size (excluding the flexible column(s))
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        if([column flexibleWidth]){
            flexibleColumn = column;
        }else{
            columnWidth -= [column width];
        }
    }
    [flexibleColumn setWidth:columnWidth];

    if(![self inLiveResize]){ //We don't recalculate row heights while resizing, so things run a bit faster
        //Reset the row height array
        [rowHeightArray release]; rowHeightArray = [[NSMutableArray alloc] init];
    
        //The flexible column is most likely to determine the height of each row, so we run through that column first.  The more row heights we get correct the first time, the less times we need to swap a value out of the row height array, and the faster this goes.
        {
            NSEnumerator	*cellEnumerator;
            AIFlexibleTableCell	*cell;
            int 		columnWidth = [flexibleColumn width];
    
            cellEnumerator = [[flexibleColumn cellArray] objectEnumerator];
            while((cell = [cellEnumerator nextObject])){
                [cell sizeCellForWidth:columnWidth]; //Resize the cell
                [rowHeightArray addObject:[NSNumber numberWithInt:[cell cellSize].height]]; //Add it's height
            }
        }
    
        //Run through the cells of the other columns, and adjust any row height calculations if needed
        //Calculate the height of every row
        columnEnumerator = [columnArray objectEnumerator];
        while((column = [columnEnumerator nextObject])){
            if(column != flexibleColumn){ // We've already processed the flexible column
                NSEnumerator		*cellEnumerator;
                AIFlexibleTableCell	*cell;
                int			row = 0;
    
                rowHeightEnumerator = [rowHeightArray objectEnumerator];
                cellEnumerator = [[column cellArray] objectEnumerator];
                while((cell = [cellEnumerator nextObject])){
                    int	cellHeight = [cell cellSize].height; //[cell sizeCellForWidth:[column width]];
                    int	existingHeight = [[rowHeightEnumerator nextObject] intValue];
    
                    if(cellHeight > existingHeight){ //The row height is too small to fit this cell
                        [rowHeightArray replaceObjectAtIndex:row withObject:[NSNumber numberWithInt:cellHeight]];
                    }
    
                    row++;
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
}

//Recalculate our dimensions, resizing our view to fill the entire space
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

- (AIFlexibleTableColumn *)columnAtIndex:(int)index
{
    if(index >= 0 && index < [columnArray count]){
        return([columnArray objectAtIndex:index]);
    }else{
        return(nil);
    }
}




@end

