//
//  AIVariableHeightFlexibleColumnsOutlineView.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 3/16/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIVariableHeightFlexibleColumnsOutlineView.h"

#define FLIPPY_WIDTH		10
#define	FLIPPY_HEIGHT		10
#define FLIPPY_TEXT_PADDING 2

/*
 * @class AIVariableHeightFlexibleColumnsOutlineView
 * @brief AIVariableHeightOutlineView subclass which can allow columns to extend to the edge of the outline view
 *
 * The delegate of AIVariableHeightFlexibleColumnsOutlineView can specify on a per-column, per-row basis if
 * the column for that row should be allowed to extend from its origin to the right edge of the outline view -- that is,
 * be unconstrained by its column boundary.  Any subsequent columns in that row will not be drawn.
 */
@implementation AIVariableHeightFlexibleColumnsOutlineView

- (NSRect)frameOfCellAtColumn:(int)column row:(int)row
{
	if([[self delegate] respondsToSelector:@selector(outlineView:extendToEdgeColumn:ofRow:)] &&
	   [[self delegate] outlineView:self extendToEdgeColumn:column ofRow:row]){
		
		NSRect	frame = [self frame];
		NSRect	columnRect = [self rectOfColumn:column];
		NSSize	intercellSpacing = [self intercellSpacing];
		float	columnOriginX = columnRect.origin.x + round((intercellSpacing.width)/2);
		
		[self updateRowHeightCache];
		return(NSMakeRect(columnOriginX,
						  rowOriginCache[row],
						  frame.size.width - columnOriginX - floor((intercellSpacing.width)/2),
						  rowHeightCache[row]));
	}else{
		return([super frameOfCellAtColumn:column row:row]);
	}
}

#pragma mark Drawing
- (void)drawRow:(int)row clipRect:(NSRect)rect
{
	if(row >= 0 && row < [self numberOfRows]){ //Somebody keeps calling this method with row = numberOfRows, which is wrong.
		
		NSArray		*tableColumns = [self tableColumns];
		id			item = [self itemAtRow:row];
		unsigned	tableColumnIndex, count = [tableColumns count];
		
		BOOL		delegateRespondsToExtendToEdgeColumn = [[self delegate] respondsToSelector:@selector(outlineView:extendToEdgeColumn:ofRow:)];

		for(tableColumnIndex = 0 ; tableColumnIndex < count ; tableColumnIndex++){
			NSTableColumn	*tableColumn;
			NSRect			cellFrame;
			id				cell;
			BOOL			selected;
			
			tableColumn = [tableColumns objectAtIndex:tableColumnIndex];
			cell = [tableColumn dataCell];
			
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
			
			/*
			 * Draw the alternating rows.  If we draw alternating rows, the cell in the first column
			 * can optionally suppress drawing. We only do this before drawing the first column; that way,
			 * we can cover the full width of the row in one stroke.
			 */
			if([self drawsAlternatingRows] && 
			   (![cell respondsToSelector:@selector(drawGridBehindCell)] || [cell drawGridBehindCell]) &&
			   (tableColumnIndex == 0)){
				
				[self _drawRowInRect:[self rectOfRow:row]
							 colored:!(row % 2)
							selected:selected];
			}
			
			
			if(tableColumnIndex == 0){
				//Draw flippy triangle
				if([self isExpandable:item]){
					
					cellFrame.origin.x += FLIPPY_TEXT_PADDING/2;
					cellFrame.size.width -= FLIPPY_TEXT_PADDING/2;
					
					NSBezierPath	*arrowPath = [NSBezierPath bezierPath];

					NSPoint			center = NSMakePoint(cellFrame.origin.x + FLIPPY_WIDTH/2,
														 cellFrame.origin.y + (cellFrame.size.height/2.0));
					/* Remember: The view is flipped */
					if([self isItemExpanded:item]){
						//Bottom point
						[arrowPath moveToPoint:NSMakePoint(center.x, 
														   center.y + FLIPPY_HEIGHT/2)];
						//Move to top left
						[arrowPath relativeLineToPoint:NSMakePoint(-(FLIPPY_WIDTH/2), -FLIPPY_HEIGHT)];
						
						//Move to top right
						[arrowPath relativeLineToPoint:NSMakePoint(FLIPPY_WIDTH, 0)];
					}else{
						//Bottom left
						[arrowPath moveToPoint:NSMakePoint(center.x - (FLIPPY_WIDTH/2), 
														   center.y + (FLIPPY_HEIGHT/2))];
						//Move to top left
						[arrowPath relativeLineToPoint:NSMakePoint(0, -FLIPPY_HEIGHT)];
						
						//Move to middle right
						[arrowPath relativeLineToPoint:NSMakePoint(FLIPPY_WIDTH, FLIPPY_HEIGHT/2)];
					}
					
					[arrowPath closePath];
					
					if(selected){
						[[NSColor whiteColor] set];
					}else{
						[[NSColor darkGrayColor] set];
					}
					[arrowPath fill];
					
					cellFrame.origin.x += FLIPPY_WIDTH + FLIPPY_TEXT_PADDING/2;
					cellFrame.size.width -= FLIPPY_WIDTH + FLIPPY_TEXT_PADDING/2;
				}
			}
			
			//Draw the cell
			if(selected) [cell _drawHighlightWithFrame:cellFrame inView:self];
			[cell drawWithFrame:cellFrame inView:self];
	
			//Stop drawing if this column extends to the edge
			if(delegateRespondsToExtendToEdgeColumn &&
			   [[self delegate] outlineView:self extendToEdgeColumn:tableColumnIndex ofRow:row]){
				break;
			}
		}
	}
}

@end
