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
- (void)resizeCells;
- (void)resizeToFillContainerView;
- (void)_init;
- (void)endEditing;
- (void)setSelected:(BOOL)selected row:(int)inRow;
@end

@implementation AIFlexibleTableView

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

- (void)addColumn:(AIFlexibleTableColumn *)inColumn
{
    [columnArray addObject:inColumn];
}

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
    NSRect			documentVisibleRect;
    NSPoint			clickLocation;
    NSEnumerator		*enumerator;
    AIFlexibleTableColumn	*column;
    int				width = 0;
    NSNumber			*rowHeight;
    int				height = 0;
    int				targetedRow = 0;
        
    //The cell check is broken by the bottom aligning offset, so we need to adjust our calculations
    documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    if(contentBottomAligned && contentsHeight < documentVisibleRect.size.height){
        height = (documentVisibleRect.size.height - contentsHeight);
    }

    //Get the click location relative to our view
    clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    //Determine the row that was clicked
    enumerator = [rowHeightArray objectEnumerator];
    while((rowHeight = [enumerator nextObject])){
        height += [rowHeight intValue];
        if(height > clickLocation.y) break;
        targetedRow++;
    }

    //Determine the column that was clicked
    enumerator = [columnArray objectEnumerator];
    while((column = [enumerator nextObject])){
        width += [column width];
        if(width > clickLocation.x) break;
    }

    //Select the row
    [self selectRow:targetedRow];

    //Open the selected cell for editing
    if([theEvent clickCount] >= 2){
        [self editRow:targetedRow column:column];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [self mouseDown:theEvent]; //Handle this as a mouse down
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
        AIFlexibleTableCell	*cell = [[column cellArray] objectAtIndex:inRow];

        [cell setSelected:selected];
        [self setNeedsDisplayInRect:[cell frame]];
    }
}

//returns the selected row
- (int)selectedRow
{
    return(selectedRow);
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
        
            //Create the editor
            editor = [[NSTextView alloc] init];
            [editor setDelegate:self];
            [editor setEditable:YES];
            [editor setSelectable:YES];
        //    [editor setTextContainerInset:[cell paddingInset]];
        //    [editor setBackgroundColor:[NSColor orangeColor]];
            [editor setFrame:NSMakeRect(0, 0, [cell frame].size.width, [cell frame].size.height)];
            [[editor textStorage] setAttributedString:[cell string]];
            [editor setSelectedRange:NSMakeRange(0,[[editor string] length])];
        
            editorScroll = [[NSScrollView alloc] init];
            [editorScroll setDocumentView:editor];
            [editorScroll setBorderType:NSBezelBorder];
            [editorScroll setHasVerticalScroller:NO];
            [editorScroll setHasHorizontalScroller:NO];
            [editorScroll setFrame:[cell frame]];
    
            editedColumn = inColumn;
            editedRow = inRow;
    
            //Make it visible and key
            [self addSubview:editorScroll];
            [[self window] makeFirstResponder:editor];
        }
    }
}

//Cancel any existing editing
- (void)endEditing
{
    if(editor){
        //Save
        if(respondsTo_setObjectValue){
            [(id <AIFlexibleTableViewDelegate_setObjectValue>)delegate setObjectValue:[editor textStorage] forTableColumn:editedColumn row:editedRow];
        }

        //Close
        [editorScroll removeFromSuperview];
        [editorScroll release]; editorScroll = nil;
        [editor release]; editor = nil;
    }
}

- (BOOL)resignFirstResponder
{
    [self endEditing];
    
    return(YES);
}


//Config --------------------------------------------------------------------------------
- (void)setContentBottomAligned:(BOOL)inValue{
    contentBottomAligned = inValue;
}

- (void)setScrollsOnNewContent:(BOOL)inValue{
    scrollsOnNewContent = inValue;
}


//Reloading --------------------------------------------------------------------------------
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

//Add a cell.  Returns YES if the cells should be resized
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

        if([column addCell:cell]){ //Returns YES if the column's width was changed
            columnWidthDidChange = YES;
        }

        //By comparing the heights of each cell, we find the largest height and set it as the height of our row
        if([cell cellSize].height > newRowHeight){
            newRowHeight = [cell cellSize].height;
        }
    }

    [rowHeightArray addObject:[NSNumber numberWithInt:newRowHeight]];
    contentsHeight += newRowHeight;

    return(columnWidthDidChange); //Return YES if the cells should be resized
}

//Recalculate the cell dimensions
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


@end

