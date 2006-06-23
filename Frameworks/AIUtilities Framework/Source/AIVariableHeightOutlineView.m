//
//  AIVariableHeightOutlineView.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 11/25/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIVariableHeightOutlineView.h"
#import "AIApplicationAdditions.h"
#import "AIImageAdditions.h"
#import "AIGradient.h"

#define	DRAG_IMAGE_FRACTION	0.75

@interface AIVariableHeightOutlineView (PRIVATE)
- (void)_initVariableHeightOutlineView;

- (int)heightForRow:(int)row;
- (void)_drawRowSelectionInRect:(NSRect)rect;
- (NSImage *)dragImageForRows:(unsigned int[])buf count:(unsigned int)count tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset;
@end

@implementation AIVariableHeightOutlineView

//Adium always toggles expandable items on click.
//This could become a preference via a set method for other implementations.
//static BOOL expandOnClick = NO;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initVariableHeightOutlineView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initVariableHeightOutlineView];
	}
	return self;
}

- (void)_initVariableHeightOutlineView
{
	rowHeightCache = nil;
	rowOriginCache = nil;
	cacheSize = 2;
	entriesInCache = 0;
	totalHeight = 0;
	drawHighlightOnlyWhenMain = NO;
	drawsSelectedRowHighlight = YES;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidExpand:) name:NSOutlineViewItemDidExpandNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidCollapse:) name:NSOutlineViewItemDidCollapseNotification object:self];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

//Handle mouseDown events to toggle expandable items when they are clicked
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint	viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int		row = [self rowAtPoint:viewPoint];
	id		item = [self itemAtRow:row];

	//Expand/Collapse groups on mouse DOWN instead of mouse up (Makes it feel a ton faster)
	if ((item) &&
 	   ([self isExpandable:item]) &&
 	   (viewPoint.x < [self frameOfCellAtColumn:0 row:row].size.height)) {
		//XXX - This is kind of a hack.  We need to check < WidthOfDisclosureTriangle, and are using the fact that
		//      the disclosure width is about the same as the height of the row to fudge it. -ai

		if ([self isItemExpanded:item]) {
			[self collapseItem:item];
		} else {
			[self expandItem:item];
		}
	} else {
		[super mouseDown:theEvent];
	}

//	if ((expandOnClick) &&
//	   (item) &&
//	   ([self isExpandable:item]) &&
//	   (viewPoint.x < [self frameOfCellAtColumn:0 row:row].size.width)) {
//
//		NSEvent *nextEvent;
//		BOOL	itemIsExpanded;
//
//		//Store the current expanded state
//		itemIsExpanded = [self isItemExpanded:item];
//
//		//Wait for the next event - don't dequeue it so it will be handled as normal
//		nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
//											   untilDate:[NSDate distantFuture]
//												  inMode:NSEventTrackingRunLoopMode
//												 dequeue:NO];
//		//Handle the original event
//		[super mouseDown:theEvent];
//
//		if ([nextEvent type] == NSLeftMouseUp) {
//			//If they pressed and released, expand/collapse the item unless mouseDown: already did
//			BOOL itemIsNowExpanded = [self isItemExpanded:item];
//
//			if (itemIsNowExpanded == itemIsExpanded) {
//				if (itemIsNowExpanded) {
//					[self collapseItem:item];
//				} else {
//					[self expandItem:item];
//				}
//			}
//		}
//
//	} else {
//		[super mouseDown:theEvent];
//	}
}

//Variable row heights -------------------------------------------------------------------------------------------------
#pragma mark Variable row heights
- (NSRect)frameOfCellAtColumn:(int)column row:(int)row
{
	NSRect	columnRect = [self rectOfColumn:column];
	NSSize	intercellSpacing = [self intercellSpacing];

	[self updateRowHeightCache];
	return NSMakeRect(columnRect.origin.x + round((intercellSpacing.width)/2),
					  rowOriginCache[row],
					  columnRect.size.width - floor((intercellSpacing.width)/2),
					  rowHeightCache[row]);
}

- (NSRect)rectOfRow:(int)row
{
	[self updateRowHeightCache];
	return NSMakeRect(0, rowOriginCache[row], [self frame].size.width, rowHeightCache[row]);
}

- (int)rowAtPoint:(NSPoint)point
{
	[self updateRowHeightCache];

	if (point.y < 0 || point.y > totalHeight) return -1;

	//Find the top visible cell
	int row = 0;
	while (row < entriesInCache-1 && rowOriginCache[row+1] <= point.y) row++;
	return row;
}

- (NSRange)rowsInRect:(NSRect)rect
{
	NSRange	range = NSMakeRange(0,0);
	int 	row = 0;

	[self updateRowHeightCache];

	//Find the top visible cell
	while (row < entriesInCache-1 && rowOriginCache[row+1] <= rect.origin.y) {
		range.location++;
		row++;
	}

	//Determine the number of additional visible cells
	do{
		range.length++;
	}while (row < entriesInCache && rowOriginCache[row++] <= rect.origin.y + rect.size.height);

	return range;
}


//Row height invalidation ----------------------------------------------------------------------------------------------
#pragma mark Row height invalidation
//On reload
- (void)reloadData{
	[super reloadData];
	[self resetRowHeightCache];
	//XXX - I'm assuming that our table view's frame is updated from within reloadData.  At that point in time
	//      however, we haven't yet reset our row height cache.  So the frame of our table view will be incorrect and
	//      result in an incorrect scrollbar scaling.  This is easy to solve by setting the frame to our correct
	//      dimensions manually after the reload and height calculations are complete.  This is probably not the
	//      best solution to this problem, but I am unaware of a better one at this time. -ai
	[self setFrameSize:NSMakeSize([self frame].size.width, [self totalHeight])];
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
	[self resetRowHeightCache];
}
- (void)itemDidCollapse:(NSNotification *)notification{
	[self resetRowHeightCache];
}


//Row height cache -----------------------------------------------------------------------------------------------------
#pragma mark Row height cache
//Release existing
- (void)resetRowHeightCache
{
	if (rowHeightCache) {
		free(rowHeightCache);
		rowHeightCache = nil;
	}
	if (rowOriginCache) {
		free(rowOriginCache);
		rowOriginCache = nil;
	}
	entriesInCache = 0;
}

- (void)updateRowHeightCache
{
	if (!rowHeightCache && !rowOriginCache) {
		int	numberOfRows = [self numberOfRows];

		//Expand
		while (numberOfRows > cacheSize) {
			cacheSize *= 2;
		}

		//New
		rowHeightCache = malloc(cacheSize * sizeof(int));
		rowOriginCache = malloc(cacheSize * sizeof(int));
		entriesInCache = numberOfRows;

		//
		int		origin = 0;
		int		i;
		NSSize	intercellSpacing = [self intercellSpacing];

		for (i = 0; i < entriesInCache; i++) {
			int height = [self heightForRow:i];

			rowHeightCache[i] = height;
			rowOriginCache[i] = origin;

			origin += height + intercellSpacing.height;
		}

		totalHeight = origin;
	}
}

- (id)cellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return [tableColumn dataCell];
}

- (int)heightForRow:(int)row
{
	return [[self dataSource] outlineView:self heightForItem:[self itemAtRow:row] atRow:row];
}

#pragma mark Drawing
- (void)drawAlternatingRowsInRect:(NSRect)rect
{
	/* Draw the alternating rows.  If we draw alternating rows, the cell in the first column
	 * can optionally suppress drawing.
	 */
	if ([self drawsAlternatingRows]) {
		int numberOfRows = [self numberOfRows];
		int rectNumber = 0;
		NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:0];

		NSRect *gridRects = (NSRect *)malloc(sizeof(NSRect) * numberOfRows);
		for (int row = 0; row < numberOfRows; row += 2) {
			if (row < numberOfRows) {
				id 	cell = [self cellForTableColumn:tableColumn item:[self itemAtRow:row]];
				if (![cell respondsToSelector:@selector(drawGridBehindCell)] || [cell drawGridBehindCell]) {					
					NSRect	thisRect = [self rectOfRow:row];
//					NSLog(@"This rect is %@ - %i",NSStringFromRect(thisRect),NSIntersectsRect(thisRect, rect));

					if (NSIntersectsRect(thisRect, rect)) { 
						gridRects[rectNumber++] = thisRect;
					}
				} else {
					NSLog(@"%@ said not to draw",cell);
				}
			}
		}
		
		if (rectNumber > 0) {
			[[self alternatingRowColor] set];
			NSRectFillList(gridRects, rectNumber);
		}
		free(gridRects);
	}
}

- (void)drawRow:(int)row clipRect:(NSRect)rect
{
	if (row >= 0 && row < [self numberOfRows]) { //Somebody keeps calling this method with row = numberOfRows, which is wrong.
		NSArray		*tableColumns = [self tableColumns];
		id			item = [self itemAtRow:row];
		unsigned	tableColumnIndex, count = [tableColumns count];

		for (tableColumnIndex = 0 ; tableColumnIndex < count ; tableColumnIndex++) {
			NSTableColumn	*tableColumn;
			NSRect			cellFrame;
			id				cell;
			BOOL			selected;

			tableColumn = [tableColumns objectAtIndex:tableColumnIndex];
			cell = [self cellForTableColumn:tableColumn item:item];

			[[self delegate] outlineView:self
						 willDisplayCell:cell
						  forTableColumn:tableColumn
									item:item];

			selected = [self isRowSelected:row];
			[cell setHighlighted:selected];

			[cell setObjectValue:[[self dataSource] outlineView:self
									  objectValueForTableColumn:tableColumn
														 byItem:item]];

			cellFrame = [self frameOfCellAtColumn:tableColumnIndex row:row];

			//Draw the cell
			if (selected) [cell _drawHighlightWithFrame:cellFrame inView:self];
			[cell drawWithFrame:cellFrame inView:self];
		}
	}
}

- (NSImage *)dragImageForRows:(unsigned int[])buf count:(unsigned int)count tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	NSRect			rowRect;
	float			yOffset;
	unsigned int	i, firstRow, row = 0, tableColumnsCount;

	firstRow = buf[0];

	//Since our cells draw outside their bounds, this drag image code will create a drag image as big as the table row
	//and then draw the cell into it at the regular size.  This way the cell can overflow its bounds as normal and not
	//spill outside the drag image.
	rowRect = [self rectOfRow:firstRow];
	image = [[[NSImage alloc] initWithSize:NSMakeSize(rowRect.size.width,
													  rowRect.size.height*count + [self intercellSpacing].height*(count-1))] autorelease];

	//Draw (Since the OLV is normally flipped, we have to be flipped when drawing)
	[image setFlipped:YES];
	[image lockFocus];

	tableColumnsCount = [tableColumns count];

	yOffset = 0;
	for (i = 0; i < count; i++) {
		id		item;
		row = buf[i];

		item = [self itemAtRow:row];

		//Draw each table column
		unsigned tableColumnIndex;
		for (tableColumnIndex = 0 ; tableColumnIndex < tableColumnsCount ; tableColumnIndex++) {

			NSTableColumn	*tableColumn = [tableColumns objectAtIndex:tableColumnIndex];
			id		cell = [self cellForTableColumn:tableColumn item:item];

			//Render the cell
			[[self delegate] outlineView:self willDisplayCell:cell forTableColumn:tableColumn item:item];
			[cell setHighlighted:NO];
			[cell setObjectValue:[[self dataSource] outlineView:self
									  objectValueForTableColumn:tableColumn
														 byItem:item]];

			//Draw the cell
			NSRect	cellFrame = [self frameOfCellAtColumn:tableColumnIndex row:row];
			[cell drawWithFrame:NSMakeRect(cellFrame.origin.x - rowRect.origin.x,yOffset,cellFrame.size.width,cellFrame.size.height)
						 inView:self];
		}

		//Offset so the next drawing goes directly below this one
		yOffset += (rowRect.size.height + [self intercellSpacing].height);
	}

	[image unlockFocus];
	[image setFlipped:NO];

	//Offset the drag image (Remember: The system centers it by default, so this is an offset from center)
	NSPoint clickLocation = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
	dragImageOffset->x = (rowRect.size.width / 2.0) - clickLocation.x;


	return [image imageByFadingToFraction:DRAG_IMAGE_FRACTION];

}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	unsigned int	bufSize = [dragRows count];
	unsigned int	*buf = malloc(bufSize * sizeof(unsigned int));

	NSRange range = NSMakeRange([dragRows firstIndex], ([dragRows lastIndex]-[dragRows firstIndex]) + 1);
	[dragRows getIndexes:buf maxCount:bufSize inIndexRange:&range];

	image = [self dragImageForRows:buf count:bufSize tableColumns:tableColumns event:dragEvent offset:dragImageOffset];

	free(buf);

	return image;
}

//Our default drag image will be cropped incorrectly, so we need a custom one here
- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	unsigned int	i, bufSize = [dragRows count];
	unsigned int	*buf = malloc(bufSize * sizeof(unsigned int));

	for (i = 0; i < bufSize; i++) {
		buf[i] = [[dragRows objectAtIndex:0] unsignedIntValue];
	}

	image = [self dragImageForRows:buf count:bufSize tableColumns:nil event:dragEvent offset:dragImageOffset];

	free(buf);

	return image;
}


- (int)totalHeight
{
	[self updateRowHeightCache];
	return totalHeight;
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
	if (drawsSelectedRowHighlight && (!drawHighlightOnlyWhenMain || [[self window] isMainWindow])) {
		[super highlightSelectionInClipRect:clipRect];
	} else {
		[self drawAlternatingRowsInRect:clipRect];
	}
}

@end
