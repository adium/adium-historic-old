//
//  AIMultiCellOutlineView.m
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//

#import "AIMultiCellOutlineView.h"

@interface AIMultiCellOutlineView (PRIVATE)
- (void)_initMultiCellOutlineView;
@end

@implementation AIMultiCellOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initMultiCellOutlineView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initMultiCellOutlineView];
	}
	return self;
}

- (void)_initMultiCellOutlineView
{
	contentCell = nil;
	groupCell = nil;
	contentRowHeight = 0;
	groupRowHeight = 0;
}

- (void)dealloc
{
	[contentCell release];
	[groupCell release];

	[super dealloc];
}

//Cell used for content rows
- (void)setContentCell:(NSCell *)cell{
	if (contentCell != cell) {
		[contentCell release];
		contentCell = [cell retain];
	}
	contentRowHeight = [contentCell cellSize].height;
	[self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}
- (NSCell *)contentCell{
	return contentCell;
}

//Cell used for group rows
- (void)setGroupCell:(NSCell *)cell{
	if (groupCell != cell) {
		[groupCell release];
		groupCell = [cell retain];
	}
	groupRowHeight = [groupCell cellSize].height;
	
	[self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}
- (NSCell *)groupCell{
	return groupCell;
}
- (id)cellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return ([self isExpandable:item] ? groupCell : contentCell);
}

@end
