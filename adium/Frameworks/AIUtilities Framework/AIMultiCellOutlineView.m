//
//  AIMultiCellOutlineView.m
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIMultiCellOutlineView.h"

@interface AIMultiCellOutlineView (PRIVATE)
- (void)resetRowHeightCache;
- (void)updateRowHeightCache;
@end

@implementation AIMultiCellOutlineView

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

- (void)_init
{
	[super _init];
	rowHeightCache = nil;
	rowOriginCache = nil;
	cacheSize = 2;
	entriesInCache = 0;
	contentRowHeight = 0;
	groupRowHeight = 0;
	totalHeight = 0;
}

- (void)dealloc
{
	[contentCell release];
	[groupCell release];
	[super dealloc];
}

- (void)setContentCell:(id)cell{
	[contentCell release]; contentCell = [cell retain];
	contentRowHeight = [contentCell cellSize].height;
	[self setRowHeight:contentRowHeight];
	[self resetRowHeightCache];
}

- (void)setGroupCell:(id)cell{
	[groupCell release]; groupCell = [cell retain];
	groupRowHeight = [groupCell cellSize].height;
	[self resetRowHeightCache];
}
#warning hmm
- (id)groupCell{
	return(groupCell);
}

//
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint	viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int		row = [self rowAtPoint:viewPoint];
	id		item = [self itemAtRow:row];
	
	if([self isExpandable:item] && viewPoint.x < [self frameOfCellAtColumn:0 row:row].size.height){
		if([self isItemExpanded:item]){
			[self collapseItem:item];
		}else{
			[self expandItem:item];
		}
	}else{
		[super mouseDown:theEvent];
	}
}


//Variable row heights -------------------------------------------------------------------------------------------------
#pragma mark Variable row heights
- (NSRect)frameOfCellAtColumn:(int)column row:(int)row
{
	[self updateRowHeightCache];
	return(NSMakeRect(0, rowOriginCache[row], [self frame].size.width, rowHeightCache[row]));
}

- (NSRect)rectOfRow:(int)row
{
	[self updateRowHeightCache];
	return(NSMakeRect(0, rowOriginCache[row], [self frame].size.width, rowHeightCache[row]));
}

- (int)rowAtPoint:(NSPoint)point
{
	[self updateRowHeightCache];
	
	if(point.y < 0 || point.y > totalHeight) return(-1);
		
	//Find the top visible cell
	int row = 0;
	while(row < entriesInCache-1 && rowOriginCache[row+1] <= point.y) row++;
	return(row);
}

- (NSRange)rowsInRect:(NSRect)rect
{
	NSRange	range = NSMakeRange(0,0);
	int 	row = 0;
	
	[self updateRowHeightCache];
	
	//Find the top visible cell
	while(row < entriesInCache-1 && rowOriginCache[row+1] <= rect.origin.y){
		range.location++;
		row++;
	}
	
	//Determine the number of additional visible cells
	do{
		range.length++;
	}while(row < entriesInCache && rowOriginCache[row++] <= rect.origin.y + rect.size.height);
	
	return(range);
}

- (void)drawRow:(int)row clipRect:(NSRect)rect
{
	id		item = [self itemAtRow:row];
	id		cell = ([self isExpandable:item] ? groupCell : contentCell);
	
	if(row >= 0 && row < [self numberOfRows]){ //Somebody keeps calling this method with row = numberOfRows, which is wrong.
		[[self delegate] outlineView:self willDisplayCell:cell forTableColumn:nil item:item];

		//Draw the grid
		if([self drawsAlternatingRows] && [cell drawGridBehindCell]){
			[self _drawRowInRect:NSIntersectionRect([self rectOfRow:row], rect)
						 colored:(!(row % 2) && ![self isRowSelected:row])
						selected:(row == [self selectedRow])];			
		}
		
		//Draw the cell
		NSRect	cellFrame = [self frameOfCellAtColumn:0 row:row];
		if([[self selectedRowIndexes] containsIndex:row]) [cell _drawHighlightWithFrame:cellFrame inView:self];
		[cell drawWithFrame:cellFrame inView:self];
	}
}

- (int)totalHeight
{
	[self updateRowHeightCache];
	return(totalHeight);
}


//Row height invalidation ----------------------------------------------------------------------------------------------
#pragma mark Row height invalidation
//On reload
- (void)reloadData{
	[super reloadData];
	[self resetRowHeightCache];
}

//On delegate / datasource change
- (void)setDataSource:(id)aSource{
	[super setDataSource:aSource];
	[self resetRowHeightCache];
}
- (void)setDelegate:(id)delegate{
	[super setDelegate:delegate];
	[self resetRowHeightCache];
}

//On expand/collapse
- (void)itemDidExpand:(NSNotification *)notification{
	[super itemDidExpand:notification];
	[self resetRowHeightCache];
}
- (void)itemDidCollapse:(NSNotification *)notification{
 	[super itemDidCollapse:notification];
	[self resetRowHeightCache];
}


//Row height cache -----------------------------------------------------------------------------------------------------
#pragma mark Row height cache
//Release existing
- (void)resetRowHeightCache
{
	if(rowHeightCache){
		free(rowHeightCache);
		rowHeightCache = nil;
	}
	if(rowOriginCache){
		free(rowOriginCache);
		rowOriginCache = nil;
	}
	entriesInCache = 0;
}

- (void)updateRowHeightCache
{
	if(!rowHeightCache && !rowOriginCache){
		int	numberOfRows = [self numberOfRows];

		//Expand
		while(numberOfRows > cacheSize){
			cacheSize *= 2;
		}
		
		//New
		rowHeightCache = malloc(cacheSize * sizeof(int));
		rowOriginCache = malloc(cacheSize * sizeof(int));
		entriesInCache = numberOfRows;
		
		//
		int origin = 0;
		int i;
		
		for(i = 0; i < entriesInCache; i++){
			int height = ([self isExpandable:[self itemAtRow:i]] ? groupRowHeight : contentRowHeight);
			
			rowHeightCache[i] = height;
			rowOriginCache[i] = origin;
			
			origin += height;
		}
		
		totalHeight = origin;
	}
}

@end
