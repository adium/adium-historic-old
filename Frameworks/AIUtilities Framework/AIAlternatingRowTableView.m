/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIAlternatingRowTableView.h"
#import "BZGenericViewCell.h"

#define	DRAG_IMAGE_FRACTION	0.75

/*
 A subclass of table view that adds:

 - Alternating row colors
 - Delete key handling
 - Better drag images
 */

@interface AIAlternatingRowTableView (PRIVATE)
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected;
- (void)_initAlternatingRowTableView;
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView;
@end


@implementation AIAlternatingRowTableView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initAlternatingRowTableView];
    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self _initAlternatingRowTableView];
    return(self);
}

- (void)_initAlternatingRowTableView
{
    drawsAlternatingRows = NO;
	acceptFirstMouse = NO;
    alternatingRowColor = [[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0] retain];
}

- (void)dealloc
{
    [alternatingRowColor release];
    
    [super dealloc];
}


//Configuring ----------------------------------------------------------------------
- (void)setDrawsAlternatingRows:(BOOL)flag
{
    drawsAlternatingRows = flag;
    [self setNeedsDisplay:YES];
}

- (void)setAlternatingRowColor:(NSColor *)color
{
    if(color != alternatingRowColor){
        [alternatingRowColor release];
        alternatingRowColor = [color retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setDataSource:(id)aSource
{
    [super setDataSource:aSource];
}

//Filter keydowns looking for the delete key (to delete the current selection)
- (void)keyDown:(NSEvent *)theEvent
{
    NSString	*charString = [theEvent charactersIgnoringModifiers];
    unichar		pressedChar = 0;

    //Get the pressed character
    if([charString length] == 1) pressedChar = [charString characterAtIndex:0];

    //Check if 'delete' was pressed
    if(pressedChar == NSDeleteFunctionKey || pressedChar == NSBackspaceCharacter || pressedChar == NSDeleteCharacter){ //Delete
        if([[self dataSource] respondsToSelector:@selector(tableViewDeleteSelectedRows:)]){
			[[self dataSource] tableViewDeleteSelectedRows:self]; //Delete the selection
		}
    }else{
        [super keyDown:theEvent]; //Pass the key event on
    }
}


// First mouse ----------------------------------------------------------------------
- (void)setAcceptsFirstMouse:(BOOL)inAcceptFirstMouse
{
	acceptFirstMouse = inAcceptFirstMouse;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return(acceptFirstMouse);
}


// Scrolling ----------------------------------------------------------------------
- (void)tile
{
    [super tile];

    [[self enclosingScrollView] setVerticalLineScroll: ([self rowHeight] + [self intercellSpacing].height) ];
}


// Drawing ----------------------------------------------------------------------
//Draw the alternating colors and grid below the "bottom" of the outlineview
- (void)drawRect:(NSRect)rect
{
    NSRect	rowRect;
    int		rowHeight;
    BOOL	coloredRow;
    int		numberOfColumns, numberOfRows;

    //Draw the rest of the outline view first
    [super drawRect:rect];

    //Setup
    numberOfRows = [self numberOfRows];
    numberOfColumns = [self numberOfColumns];
    rowHeight = [self rowHeight] + [self intercellSpacing].height;
    if(numberOfRows == 0){
        rowRect = NSMakeRect(0,0,rect.size.width,rowHeight);
        coloredRow = YES;        
    }else{
        rowRect = [self rectOfRow:numberOfRows-1];
        rowRect.origin.y += rowHeight;
        coloredRow = !(numberOfRows % 2);        
    }

    //Draw the grid
    while(rowRect.origin.y < rect.origin.y + rect.size.height){
        [self _drawRowInRect:rowRect colored:coloredRow selected:NO];

        //Move to the next row
        coloredRow = !coloredRow;
        rowRect.origin.y += rowHeight;            
    }
}

//Draw alternating colors
- (void)drawRow:(int)row clipRect:(NSRect)rect
{
    [self _drawRowInRect:[self rectOfRow:row] colored:!(row % 2) selected:[self isRowSelected:row]];

    [super drawRow:row clipRect:rect];
}

//Draw a row
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
    if(drawsAlternatingRows){ //Draw alternating rows in the outline view
        if(colored && !selected){            
			[alternatingRowColor set];
            [NSBezierPath fillRect:rect/*segmentRect*/];
        }
    }
}

- (NSColor *)_highlightColorForCell
{
	return ([NSColor clearColor]);
}

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
