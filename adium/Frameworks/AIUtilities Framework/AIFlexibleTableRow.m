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
- (id)initWithCells:(NSArray *)inCells representedObject:(id)inRepresentedObject;
- (AIFlexibleTableCell *)_cellAtPoint:(NSPoint)inPoint cellOrigin:(NSPoint *)outOrigin;
@end
int _factorHeightOfCell(AIFlexibleTableCell *cell, int currentHeight);

@implementation AIFlexibleTableRow

//
+ (id)rowWithCells:(NSArray *)inCells representedObject:(id)inRepresentedObject
{
    return([[[self alloc] initWithCells:inCells representedObject:inRepresentedObject] autorelease]);
}

//
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

//Spanning
- (void)updateSpanningAndResizeRow:(BOOL)resize
{
    NSEnumerator	*enumerator;
    AIFlexibleTableCell	*cell;

    //Update our spansRow flag
    spansRows = NO;
    enumerator = [cellArray objectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell rowSpan] != 1) spansRows = YES;
    }
    
    //Recalculate height
    if(resize) [tableView resizeRow:self];
}
//Returns YES if this row spans into another row's cells
- (BOOL)spansRows{
    return(spansRows);
}

//Set the table view that owns this row
- (void)setTableView:(AIFlexibleTableView *)inView{
    tableView = inView;
}
- (AIFlexibleTableView *)tableView{
    return(tableView);
}

//Returns our represented object
- (id)representedObject
{
    return(representedObject);
}

//
- (NSArray *)cellArray{
    return(cellArray);
}


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

//Tests if a point is selected
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

        if([cell isKindOfClass:[AIFlexibleTableSpanCell class]]){ //If the cell is a 'span' zone
            //Set the void cell to the width of its master
	    spanCell = (AIFlexibleTableSpanCell *)cell;
            [spanCell sizeCellForWidth:[[spanCell masterCell] cellSize].width];
            inWidth -= [spanCell cellSize].width;
            
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

    //Size the span cell (if necessary) to make enough vertical space for it's master
    //NOTE: This code only works for master cells with a rowspan of 2, and with only one span per row.
    //NOTE: Code to do beyond this would be much more complicated, and is not necessary at the moment.
    //If we are the bottom of this span chain
    if(spanCell){
	AIFlexibleTableCell *masterCell = [spanCell masterCell];
	if([masterCell rowSpan] == 2){
	    //And the height of the master cell has not been satisfied by it's spans
	    if([[masterCell tableRow] height] + height < [masterCell cellSize].height){
		//Pad our height to make enough room for the master to fully draw
		height = [masterCell cellSize].height - [[masterCell tableRow] height];
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

//Factors height of the passed cell into the height of our row, correctly handling span zones and spanned cells
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
@end


