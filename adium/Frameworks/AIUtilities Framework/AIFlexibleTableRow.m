//
//  AIFlexibleTableRow.m
//  Adium
//
//  Created by Adam Iser on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableRow.h"
#import "AIFlexibleTableCell.h"
#import "AIFlexibleTableSpanCell.h"

@interface AIFlexibleTableRow (PRIVATE)
- (id)initWithCells:(NSArray *)inCells;
- (AIFlexibleTableCell *)_cellAtPoint:(NSPoint)inPoint cellOrigin:(NSPoint *)outOrigin;
@end
int _factorHeightOfCell(AIFlexibleTableCell *cell, int currentHeight);

@implementation AIFlexibleTableRow
//
+ (id)rowWithCells:(NSArray *)inCells
{
    return([[[self alloc] initWithCells:inCells] autorelease]);
}

//
- (id)initWithCells:(NSArray *)inCells
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;

    //Init
    [super init];
    cellArray = [inCells retain];
    tableView = nil;
    spansRows = NO;
    
    //Let all the cells know we are their row
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        [cell setTableRow:self];
        if([cell rowSpan] != 1) spansRows = YES;
    }

    return(self);
}

- (void)dealloc
{
    [cellArray release];

    [super dealloc];
}

//Returns YES if this row spans into another row's cells
- (BOOL)spansRows{
    return(spansRows);
}

//
- (void)setTableView:(AIFlexibleTableView *)inView{
    tableView = inView;
}
- (AIFlexibleTableView *)tableView{
    return(tableView);
}

//
- (void)drawAtPoint:(NSPoint)point visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    int			x = point.x;

    //Draw our cells
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        NSSize	cellSize = [cell cellSize];
        
        [cell drawWithFrame:NSMakeRect(x,point.y,cellSize.width,cellSize.height) inView:controlView];

        x += cellSize.width;
    }
}

//
- (void)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    int			x = offset.x;

    //Reset the cursor rects of our cells
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        NSSize	cellSize = [cell cellSize];

        [cell resetCursorRectsAtOffset:NSMakePoint(x, offset.y)
                           visibleRect:NSIntersectionRect(visibleRect, NSMakeRect(x, offset.y, cellSize.width, cellSize.height))
                                inView:controlView];
        
        x += cellSize.width;
    }
}

// (point local to this row)
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

//
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

    //
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

//
- (void)deselectContent
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;

    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        [cell deselectContent];
    }
}

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

//
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

//
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

//
- (int)sizeRowForWidth:(int)inWidth
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;
    int			flexCellCount = 0;

    //
    height = 0;

    //Size all non-flexible cells
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){

        if([cell isKindOfClass:[AIFlexibleTableSpanCell class]]){ //If the cell is a 'span' zone
            //Set the void cell to the width of its master
            [cell sizeCellForWidth:[[(AIFlexibleTableSpanCell *)cell masterCell] cellSize].width];
            inWidth -= [cell cellSize].width;
            
        }else if(![cell variableWidth]){
            inWidth -= [cell cellSize].width;
            height = _factorHeightOfCell(cell, height);
            
        }else{
            flexCellCount++;
        }

    }

    //Size all the flexible cells
    if(flexCellCount){
        BOOL	firstCell = YES;
        int	flexCellWidth = inWidth / flexCellCount; //Divide the remaining width among the flexible cells
        int	firstFlexCellWidth = (inWidth - (flexCellWidth * (flexCellCount - 1))); //We give any extra pixels to the first cell
        
        //
        enumerator = [cellArray objectEnumerator];
        while(cell = [enumerator nextObject]){
            if([cell variableWidth]){
                [cell sizeCellForWidth:(firstCell ? firstFlexCellWidth : flexCellWidth)];
                height = _factorHeightOfCell(cell, height);
            }
        }
    }

    //Return our required height
    return(height);
}

//
- (int)height
{
    return(height);
}

// Factors height of the passed into the height of our row, correctly handling span zones and spanned cells
int _factorHeightOfCell(AIFlexibleTableCell *cell, int currentHeight)
{
    int height = currentHeight;
    int	cellHeight;
    
    if([cell isKindOfClass:[AIFlexibleTableSpanCell class]]){ //If the cell is a 'span' zone
        if(/*we are the last span zone*/YES){
            cellHeight = [[(AIFlexibleTableSpanCell *)cell masterCell] cellSize].height;
            if(cellHeight > height) height = cellHeight;
        }

    }else if([cell rowSpan] != 1){ //If the cell is spanning
        //Ignore its height

    }else{ //Normal cell, Use the height directly
        cellHeight = [cell cellSize].height;
        if(cellHeight > height) height = cellHeight;
    }

    return(height);
}

@end


