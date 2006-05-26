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
	[self setRowHeight:contentRowHeight];
	[self resetRowHeightCache];
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
	[self resetRowHeightCache];
}
- (NSCell *)groupCell{
	return groupCell;
}

- (id)cellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return ([self isExpandable:item] ? groupCell : contentCell);
}

- (int)heightForRow:(int)row
{
	return ([self isExpandable:[self itemAtRow:row]] ? groupRowHeight : contentRowHeight);
}

@end
