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

#import "AIFlexibleTableRow.h"
#import "AIFlexibleTableCell.h"
#import "AIFlexibleTableSpanCell.h"

@interface AIFlexibleTableRow (PRIVATE)
- (id)initWithCells:(NSArray *)inCells representedObject:(id)inRepresentedObject;
- (AIFlexibleTableCell *)_cellAtPoint:(NSPoint)inPoint cellOrigin:(NSPoint *)outOrigin;
@end
int _factorHeightOfCell(AIFlexibleTableCell *cell, int currentHeight);

@implementation AIFlexibleTableRow

//Create a new row
+ (id)rowWithCells:(NSArray *)inCells representedObject:(id)inRepresentedObject
{
    return([[[self alloc] initWithCells:inCells representedObject:inRepresentedObject] autorelease]);
}

//Create a new row
- (id)initWithCells:(NSArray *)inCells representedObject:(id)inRepresentedObject
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;

    //Init
    [super init];
    cellArray = [inCells retain];
    representedObject = [inRepresentedObject retain];
    tableView = nil;
    spansRows = NO;
    isSpannedInto = NO;
    tag = -1;
    
    //Let all the cells know we are their row
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        [cell setTableRow:self];
    }
    
    //Update spanning
    [self updateSpanningAndResizeRow:NO];

    return(self);
}

//Dealloc
- (void)dealloc
{
    [cellArray release];
    [representedObject release];

    [super dealloc];
}

//Tableview that owns this row
- (void)setTableView:(AIFlexibleTableView *)inView{
    tableView = inView;
}
- (AIFlexibleTableView *)tableView{
    return(tableView);
}

//Our represented object
- (id)representedObject
{
    return(representedObject);
}

//set the amount that rows which follow this one should indent
- (void)setHeadIndent:(float)inHeadIndent
{
    headIndent = inHeadIndent;
}
//returns the amount that rows which follow this one should indent
- (float)headIndent
{
    return (headIndent);   
}


//Cell access ---------------------------------------------------------------------------
//Finds a cell in this row with the specified class
- (id)cellWithClass:(Class)theClass
{
    NSEnumerator        *enumerator;
    AIFlexibleTableCell *cell;
    
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell isKindOfClass:theClass]) return(cell);
    }
    
    return(nil);
}

//Finds the last cell in this row with the specified class
- (id)lastCellWithClass:(Class)theClass
{
    NSEnumerator        *enumerator;
    AIFlexibleTableCell *cell;
    
    enumerator = [cellArray reverseObjectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell isKindOfClass:theClass]) return(cell);
    }
    
    return(nil);
}

//Finds all cells in this row with the specified class
- (NSArray *)cellsWithClass:(Class)theClass
{
    NSMutableArray      *outArray = [[NSMutableArray alloc] init];
    NSEnumerator        *enumerator;
    AIFlexibleTableCell *cell;
    
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell isKindOfClass:theClass]) [outArray addObject:cell];
    }
    
    return([outArray autorelease]);
}


//Row Spanning ----------------------------------------------------------------------
//Returns YES if this row spans into another row's cells
- (BOOL)spansRows
{
    return(spansRows);
}

//Returns YES if another row spans into this row's cells
- (BOOL)isSpannedInto{
    return(isSpannedInto);
}

//Update spanning
- (void)updateSpanningAndResizeRow:(BOOL)resize
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;

    //Update our spansRow flag
    spansRows = NO;
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell rowSpan] != 1) spansRows = YES;
	if([cell isSpannedInto]) isSpannedInto = YES;
    }
    
    //Recalculate height
    if(resize) [tableView resizeRow:self];
}


//Drawing ----------------------------------------------------------------------
//Draw this row
- (void)drawAtPoint:(NSPoint)point visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    int			x = point.x;

    //Draw our cells
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        NSSize	cellSize = [cell cellSize];
        
        [cell drawWithFrame:NSMakeRect(x, point.y, cellSize.width, (cellSize.height > height ? cellSize.height : height)) inView:controlView];

        x += cellSize.width;
    }
}


//Cursor Tracking ---------------------------------------------------------------------------
//Updates any cursor tracking rects.  Returns YES if cursor rects were modified
- (BOOL)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    int			x = offset.x;
    int			installedCursorRects = 0;

    //Reset the cursor rects of our cells
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        NSSize	cellSize = [cell cellSize];

        installedCursorRects += [cell resetCursorRectsAtOffset:NSMakePoint(x, offset.y)
                                                   visibleRect:NSIntersectionRect(visibleRect, NSMakeRect(x, offset.y, cellSize.width, cellSize.height))
                                                        inView:controlView];
        
        x += cellSize.width;
    }

    return(installedCursorRects != 0);
}


//Clicking -----------------------------------------------------------------------------------
//Handles a mouse down event (point local to this row)
- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    AIFlexibleTableCell	*cell;
    NSPoint		cellOrigin;
    
    //Determine the clicked cell
    cell = [self _cellAtPoint:inPoint cellOrigin:&cellOrigin];
    if(cell){
        return([cell handleMouseDownEvent:theEvent atPoint:NSMakePoint(inPoint.x - cellOrigin.x, inPoint.y - cellOrigin.y) offset:NSMakePoint(inOffset.x + cellOrigin.x, inOffset.y + cellOrigin.y)]);
    }else{
        return(NO);
    }
}

//Returns the desired menu contents for a right click
- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    AIFlexibleTableCell	*cell;
    NSPoint		cellOrigin;
    
    //Determine the clicked cell
    cell = [self _cellAtPoint:inPoint cellOrigin:&cellOrigin];
    if(cell){
        return([cell menuItemsForEvent:theEvent atPoint:NSMakePoint(inPoint.x - cellOrigin.x, inPoint.y - cellOrigin.y) offset:NSMakePoint(inOffset.x + cellOrigin.x, inOffset.y + cellOrigin.y)]);
    }else{
        return(nil);
    }    
}

//Returns the cell at a given point (and it's origin)
- (AIFlexibleTableCell *)_cellAtPoint:(NSPoint)inPoint cellOrigin:(NSPoint *)outOrigin
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    
    //
    *outOrigin = NSMakePoint(0,0);
    
    //Determine the clicked cell
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        float	nextOriginX = (*outOrigin).x + [cell cellSize].width;
        
        if(inPoint.x < nextOriginX) return(cell);
        (*outOrigin).x = nextOriginX;
    }
    
    return(nil);
}


//Content selection --------------------------------------------------------------------------
//Select content in this row
- (void)selectContentFrom:(NSPoint)startPoint to:(NSPoint)endPoint offset:(NSPoint)offset mode:(int)selectMode
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    NSPoint		cellPoint = NSMakePoint(0,0);
    
    //Flip, so we're working from left to right
    if(endPoint.x < startPoint.x){
        NSPoint	temp = startPoint;
        startPoint = endPoint;
        endPoint = temp;
    }
    
    //Select content in each cell
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
	
        if(cellPoint.x + [cell cellSize].width > startPoint.x && cellPoint.x < endPoint.x){
            BOOL end = NO, start = NO;
	    
            if(cellPoint.x < startPoint.x) start = YES; //selection starts in this cell
            if(cellPoint.x + [cell cellSize].width > endPoint.x) end = YES; //ends in this row
	    
            [cell selectContentFrom:(start ? NSMakePoint(startPoint.x - cellPoint.x, startPoint.y - cellPoint.y) : NSMakePoint(-1,-1))
                                 to:(end ? NSMakePoint(endPoint.x - cellPoint.x, endPoint.y - cellPoint.y) : NSMakePoint(1e7,1e7))
                             offset:NSMakePoint(offset.x + cellPoint.x, offset.y + cellPoint.y)
                               mode:selectMode];
        }
        
        cellPoint.x += [cell cellSize].width;
    }
}

//Deselect all in this row
- (void)deselectContent
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;

    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        [cell deselectContent];
    }
}

//Returns the selected string value in this row
- (NSAttributedString *)selectedString
{
    NSMutableAttributedString	*selectedString = nil;
    NSEnumerator		*rowEnumerator;
    AIFlexibleTableCell		*cell;
    NSAttributedString		*segment;

    //Enumerate through each cell
    rowEnumerator = [cellArray objectEnumerator];
    while((cell = [rowEnumerator nextObject])){
        if(segment = [cell selectedString]){
            if(!selectedString) selectedString = [[[NSMutableAttributedString alloc] init] autorelease];
            [selectedString appendAttributedString:segment];
        }
    }

    //
    return(selectedString);
}    

//Tests if a point is within selected content
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    NSPoint		cellOrigin;
    AIFlexibleTableCell	*cell;
    
    if(cell = [self _cellAtPoint:inPoint cellOrigin:&cellOrigin]){
        return([cell pointIsSelected:NSMakePoint(inPoint.x - cellOrigin.x, inPoint.y - cellOrigin.y) offset:cellOrigin]);
    }else{
        return(NO);
    }
}


//Sizing --------------------------------------------------------------------------
//Size this row for the passed width (returns our new height)
- (int)sizeRowForWidth:(int)inWidth
{
    NSEnumerator	    *enumerator;
    AIFlexibleTableCell     *cell;
    AIFlexibleTableSpanCell *spanCell = nil;
    int			    flexCellCount = 0;

    //
    height = 0;

    //Size all non-flexible cells
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
	if(![cell variableWidth]){
	    //Keep track of the spanned cell if we find it
	    if([cell isSpannedInto]){
		spanCell = (AIFlexibleTableSpanCell *)cell;
	    }
	    
	    //Factor the height of regular, non-spanning cells into the height of this row
	    if(![cell isSpannedInto] && [cell rowSpan] == 1){
		height = _factorHeightOfCell(cell, height);
	    }

	    //Subtract the cell's width from our total
	    inWidth -= [cell cellSize].width;
	    
	}else{
            flexCellCount++; //Keep track of the number of variable width cells
	     
	}
    }

    //Size all the flexible cells
    if(flexCellCount){
        BOOL	firstCell = YES;
        int	flexCellWidth = inWidth / flexCellCount; //Divide the remaining width among the flexible cells
        int	firstFlexCellWidth = (inWidth - (flexCellWidth * (flexCellCount - 1))); //We give any extra pixels to the first cell
        
        //Divide the available width among the flexible cells, and process their height.
        enumerator = [cellArray objectEnumerator];
        while(cell = [enumerator nextObject]){
            if([cell variableWidth]){
                [cell sizeCellForWidth:(firstCell ? firstFlexCellWidth : flexCellWidth)];
                height = _factorHeightOfCell(cell, height);
            }
        }
    }

    //Factors the height of the span cell into the height of our row.
    //A span cell has no effect on the height of a row unless:
    // - It is the last span cell
    // - The height of all spaned rows and the master cell's row is smaller than the height of the master cell
    //
    //In this case, the span cell will make the row tall enough for the master cell to fully display
    //This code assumes that only one span cell will exist per row
    //
    if(spanCell){
	AIFlexibleTableCell  *masterCell = [spanCell masterCell];
	
	//Is this cell the last span cell?
	if([spanCell spannedIndex] == [masterCell rowSpan] - 1){
	    int masterCellHeight = [masterCell cellSize].height;
	    int heightSoFar = 0;
	    
	    //Get the height of all previous span cell rows, and the master cell row
	    heightSoFar = [tableView heightOfSpanCellsAboveRow:self];
	    
	    //Adjust our height as necessary to make enough room for the master cell    
	    if(masterCellHeight > heightSoFar){
		height += (masterCellHeight - heightSoFar);
	    }
	}
    }

    //Return our required height
    return(height);
}

//Returns the height of this row
- (int)height
{
    return(height);
}

//Factors height of the passed cell into the height of our row
int _factorHeightOfCell(AIFlexibleTableCell *cell, int currentHeight)
{
    int	cellHeight = [cell cellSize].height;
    return((cellHeight > currentHeight) ? cellHeight : currentHeight );
}

//Tags
- (void)setTag:(int)inTag
{
    tag = inTag;
}
- (int)tag
{
    return tag;
}

//Opacity
- (void)setOpacity:(float)opacity
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    
    //Set our cells' opacities
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        [cell setOpacity:opacity];
    }
}
@end


