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
- (void)addCellsForRow:(int)inRow;
- (void)resizeCells;
- (void)resizeToFillContainerView;
@end

@implementation AIFlexibleTableView

- (id)init
{
    //init
    [super init];
    columnArray = [[NSMutableArray alloc] init];
    delegate = nil;
    contentsHeight = 0;
    oldWidth = 0;

    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:self];

    return(self);
}

- (void)setDelegate:(id <AIFlexibleTableViewDelegate>)inDelegate
{
    if(inDelegate != delegate){
        [delegate release]; delegate = nil;
        delegate = [inDelegate retain];
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
    if(contentsHeight < documentVisibleRect.size.height){
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

//Reloading --------------------------------------------------------------------------------
//Call after adding a new row
- (void)loadNewRow
{
    //Add the new content
    [self addCellsForRow:([delegate numberOfRows] - 1)];

    //Resize and redisplay
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Call when the data is changed, reloads all the cells
- (void)reloadData
{
    int	numberOfRows = [delegate numberOfRows];
    int	row;

    for(row = 0;row < numberOfRows;row++){
        [self addCellsForRow:row];
    }

    //Resize and redisplay
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

//Add a cell
- (void)addCellsForRow:(int)inRow
{
    NSEnumerator		*columnEnumerator;
    AIFlexibleTableColumn	*column;
    int				newRowHeight = 0;
    
    //Add a cell to each column
    columnEnumerator = [columnArray objectEnumerator];
    while((column = [columnEnumerator nextObject])){
        AIFlexibleTableCell	*cell = [delegate cellForColumn:column row:inRow];
        int			cellHeight;

        cellHeight = [column addCell:cell];

        //By comparing the heights of each cell, we find the largest height and set it as the height of our row
        if(cellHeight > newRowHeight){
            newRowHeight = cellHeight;
        }
    }

    [rowHeightArray addObject:[NSNumber numberWithInt:newRowHeight]];
    contentsHeight += newRowHeight;
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
                [rowHeightArray addObject:[NSNumber numberWithInt:[cell sizeCellForWidth:columnWidth]]];
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
    BOOL			autoScroll;
    NSSize			size;

    //Before resizing the view, we decide if the user is close to the bottom of our view.  If they are, we want to keep them at the bottom no matter what happens during the resize.
    enclosingScrollView = [self enclosingScrollView];
    documentVisibleRect = [enclosingScrollView documentVisibleRect];
    autoScroll = ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > ([self frame].size.height - AUTOSCROLL_CATCH_SIZE));

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

