//
//  AIMultiCellOutlineView.m
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
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
	drawHighlightOnlyWhenMain = NO;
	drawsSelectedRowHighlight = YES;
	
	backgroundImage = nil;
	backgroundFade = 1.0;
	drawsBackground = YES;
}

- (void)dealloc
{
	[contentCell release];
	[groupCell release];
	[super dealloc];
}

//Cell used for content rows
- (void)setContentCell:(id)cell{
	[contentCell release]; contentCell = [cell retain];
	contentRowHeight = [contentCell cellSize].height;
	[self setRowHeight:contentRowHeight];
	[self resetRowHeightCache];
}
- (id)contentCell{
	return(contentCell);
}

//Cell used for group rows
- (void)setGroupCell:(id)cell{
	[groupCell release]; groupCell = [cell retain];
	groupRowHeight = [groupCell cellSize].height;
	[self resetRowHeightCache];
}
- (id)groupCell{
	return(groupCell);
}

//
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint	viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int		row = [self rowAtPoint:viewPoint];
	id		item = [self itemAtRow:row];
	
	if((item) && 
	   ([self isExpandable:item]) && 
	   (viewPoint.x < [self frameOfCellAtColumn:0 row:row].size.height)){
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
		BOOL	selected = [self isRowSelected:row];
		
		[[self delegate] outlineView:self willDisplayCell:cell forTableColumn:nil item:item];
		[cell setHighlighted:selected];

		//Draw the grid
		if([self drawsAlternatingRows] && [cell drawGridBehindCell]){
			[self _drawRowInRect:NSIntersectionRect([self rectOfRow:row], rect)
						 colored:!(row % 2)
						selected:selected];			
		}
		
		//Draw the cell
		NSRect	cellFrame = [self frameOfCellAtColumn:0 row:row];
		if([self isRowSelected:row]) [cell _drawHighlightWithFrame:cellFrame inView:self];
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


//Background -----------------------------------------------------------------
//
- (void)setBackgroundImage:(NSImage *)inImage
{
	[backgroundImage release]; backgroundImage = nil;
	
	backgroundImage = [inImage retain];
	[backgroundImage setFlipped:YES];
	
	[(NSClipView *)[self superview] setCopiesOnScroll:(!backgroundImage)];
	[self setNeedsDisplay:YES];
}

- (void)setDrawsBackground:(BOOL)inDraw
{
	drawsBackground = inDraw;
}

- (void)setBackgroundFade:(float)fade
{
	backgroundFade = fade;
}

- (void)setBackgroundColor:(NSColor *)inColor
{
	[backgroundColor release];
	backgroundColor = [inColor retain];
}

- (NSColor *)backgroundColor
{
	return(backgroundColor);
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];

	[(NSClipView *)newSuperview setCopiesOnScroll:(!backgroundImage)];
}

//
- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	NSRect visRect = [[self enclosingScrollView] documentVisibleRect];
	
#warning --
	[super drawBackgroundInClipRect:clipRect];
	
	if(drawsBackground){
		//BG Color
		[backgroundColor set];
		NSRectFill(clipRect);
		
		//Image
		if(backgroundImage){
			NSSize	imageSize = [backgroundImage size];
			
			[backgroundImage drawInRect:NSMakeRect(visRect.origin.x, visRect.origin.y, imageSize.width, imageSize.height)
							   fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
							  operation:NSCompositeSourceOver
							   fraction:backgroundFade];
		}	
	}else{
		[[NSColor clearColor] set];
		NSRectFill(clipRect);
	}
}


//Custom highlight management
- (void)setDrawHighlightOnlyWhenMain:(BOOL)inFlag
{
	drawHighlightOnlyWhenMain = inFlag;	
}
- (BOOL)drawHighlightOnlyWhenMain
{
	return drawHighlightOnlyWhenMain;
}

- (void)setDrawsSelectedRowHighlight:(BOOL)inFlag
{
	drawsSelectedRowHighlight = inFlag;
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
	if(drawsSelectedRowHighlight && (!drawHighlightOnlyWhenMain || [[self window] isMainWindow])){
		//Apple wants us to do some pretty crazy stuff for selections in 10.3
		//We'll continue to use the old simpler cleaner safer easier method for 10.2
		if([NSApp isPantherOrBetter]){
			NSIndexSet *indices = [self selectedRowIndexes];
			unsigned int bufSize = [indices count];
			unsigned int *buf = malloc(bufSize * sizeof(unsigned int));
			unsigned int i;
			
			NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
			[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
			
			for(i = 0; i < bufSize; i++) {
				[self _drawRowSelectionInRect:[self rectOfRow:buf[i]]];
			}
			
			free(buf);
		}else{
			NSEnumerator	*enumerator = [self selectedRowEnumerator];
			NSNumber		*rowNumber;
			
			while(rowNumber = [enumerator nextObject]){
				[self _drawRowSelectionInRect:[self rectOfRow:[rowNumber intValue]]];
			}
		}
	}
}

- (void)_drawRowSelectionInRect:(NSRect *)rect
{
	//Draw the gradient
	AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
	[gradient drawInRect:rect];
	
	//Draw a line at the light side, to make it look a lot cleaner
	rect.size.height = 1;
	[[NSColor alternateSelectedControlColor] set];
	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
	
}

@end
