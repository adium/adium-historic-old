//
//  AIEmoticonPackPreviewTableView.m
//  Adium
//
//  Created by Evan Schoenberg on 1/30/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIEmoticonPackPreviewTableView.h"

#define	DRAG_IMAGE_FRACTION	0.75

/*!
 * @class AIEmoticonPackPreviewTableView
 * @brief Table view subclass for the emoticon pack preview
 *
 * This AIAlternatingRowTableView subclass draws images for BZGenericViewCell-using columns.  It only draws the image
 * for the first column so is not suitable for general use.
 */
@implementation AIEmoticonPackPreviewTableView

- (NSImage *)dragImageForRows:(unsigned int[])buf count:(unsigned int)count tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	NSTableColumn	*tableColumn;
	NSRect			rowRect;
	float			yOffset;
	unsigned int	i, firstRow, row;
	
	firstRow = buf[0];
	
	//Since our cells draw outside their bounds, this drag image code will create a drag image as big as the table row
	//and then draw the cell into it at the regular size.  This way the cell can overflow its bounds as normal and not
	//spill outside the drag image.
	rowRect = [self rectOfRow:firstRow];
	image = [[[NSImage alloc] initWithSize:NSMakeSize(rowRect.size.width,
													  rowRect.size.height*count + [self intercellSpacing].height*(count-1))] autorelease];
	
	//Draw
	[image lockFocus];
	
	yOffset = 0;
	tableColumn = [[self tableColumns] objectAtIndex:0];
	for(i = 0; i < count; i++){
		
		row = buf[i];
		id		cell = [tableColumn dataCellForRow:row];
		
		//Render the cell
		if([[self delegate] respondsToSelector:@selector(tableView:willDisplayCell:forTableColumn:row:)]){
			[[self delegate] tableView:self willDisplayCell:cell forTableColumn:nil row:row];
		}
		if([[self dataSource] respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)]){
			[cell setObjectValue:[[self dataSource] tableView:self objectValueForTableColumn:nil row:row]];
		}
		
		[cell setHighlighted:NO];
		
		//Draw the cell
		NSRect	cellFrame = [self frameOfCellAtColumn:0 row:row];
		NSRect	targetFrame = NSMakeRect(cellFrame.origin.x - rowRect.origin.x,yOffset,cellFrame.size.width,cellFrame.size.height);
		
		//Cute little hack so we can do drag images when using BZGenericViewCell to put views into tables
		if([cell isKindOfClass:[BZGenericViewCell class]]){
			[(BZGenericViewCell *)cell drawEmbeddedViewWithFrame:targetFrame
														  inView:self];
		}else{
			[cell drawWithFrame:targetFrame
						 inView:self];
		}
		
		//Offset so the next drawing goes directly below this one
		yOffset += (rowRect.size.height + [self intercellSpacing].height);
	}
	
	[image unlockFocus];
	
	//Offset the drag image (Remember: The system centers it by default, so this is an offset from center)
	NSPoint clickLocation = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
	dragImageOffset->x = (rowRect.size.width / 2.0) - clickLocation.x;
	
	return([image imageByFadingToFraction:DRAG_IMAGE_FRACTION]);
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
	
	return(image);
}

//Our default drag image will be cropped incorrectly, so we need a custom one here
- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	unsigned int	i, bufSize = [dragRows count];
	unsigned int	*buf = malloc(bufSize * sizeof(unsigned int));
	
	for(i = 0; i < bufSize; i++){
		buf[i] = [[dragRows objectAtIndex:0] unsignedIntValue];
	}
	
	image = [self dragImageForRows:buf count:bufSize tableColumns:nil event:dragEvent offset:dragImageOffset]; 
	
	free(buf);
	
	return(image);
}

@end
