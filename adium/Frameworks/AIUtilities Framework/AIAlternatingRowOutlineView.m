/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*
 A subclass of outline view that adds:

 - Alternating rows
 - Delete key filtering
 - Expand / Collapse state control
 - A vertical column grid
 - Fixes a reload data crash

 */

#import "AIAlternatingRowOutlineView.h"

@interface AIAlternatingRowOutlineView (PRIVATE)
- (void)_init;
- (void)outlineViewDeleteSelectedRows:(NSTableView *)tableView;
- (void)_drawGridInClipRect:(NSRect)rect;
- (BOOL)_restoreSelectionFromSavedSelection;
- (void)_saveCurrentSelection;
@end

@implementation AIAlternatingRowOutlineView

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

- (void)dealloc
{
    [alternatingRowColor release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)_init
{
	[super _init];
	
    drawsAlternatingRows = NO;
	hidesSelectionWhenNotMain = NO;
    alternatingRowColor = [[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0] retain];
    isOnPantherOrBetter = [NSApp isOnPantherOrBetter];
}

// Configuring ----------------------------------------------------------------------
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


// Drawing ----------------------------------------------------------------------
//Draw the alternating colors and grid below the "bottom" of the outlineview
- (void)drawRect:(NSRect)rect
{
	//Draw the rest of the outline view first
	[super drawRect:rect];
	
    if(drawsAlternatingRows){
		NSRect	rowRect;
		int		rowHeight;
		BOOL	coloredRow;
		int		numberOfColumns, numberOfRows;
		//Setup
		numberOfRows = [self numberOfRows];
		numberOfColumns = [self numberOfColumns];
		rowHeight = [self rowHeight] + [self intercellSpacing].height;
		if(numberOfRows == 0){
			rowRect = NSMakeRect(0,0,rect.size.width,rowHeight);
			coloredRow = YES;        
		}else{
			rowRect = NSMakeRect(0, NSMaxY([self rectOfRow:numberOfRows-1]) + rowHeight, rect.size.width, rowHeight);
			coloredRow = (numberOfRows % 2);        
		}
		
		//Draw the grid
		while(rowRect.origin.y < rect.origin.y + rect.size.height){
			[self _drawRowInRect:rowRect colored:coloredRow selected:NO];
			
			//Move to the next row
			coloredRow = !coloredRow;
			rowRect.origin.y += rowHeight;            
		}
		
		if([self drawsGrid]){
			[self _drawGridInClipRect:rect];
		}
	}
}

//Draw alternating colors
- (void)drawRow:(int)row clipRect:(NSRect)rect
{
    if(drawsAlternatingRows){
		[self _drawRowInRect:[self rectOfRow:row] colored:(!(row % 2) && ![self isRowSelected:row]) selected:(row == [self selectedRow])];
	}
	
    [super drawRow:row clipRect:rect];
}

//Draw a row
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
	NSRect	segmentRect = rect;
	
	if(colored && !selected){
		segmentRect.origin.x = 0;
		segmentRect.size.width = [self frame].size.width;
		
		//Whipe any existing color
		[[NSColor clearColor] set];
		NSRectFill(segmentRect); //fillRect: doesn't work here... must behave differently w/ alpha
		
		//Draw our grid color
		[alternatingRowColor set];
		[NSBezierPath fillRect:segmentRect];
	}
}

- (void)drawGridInClipRect:(NSRect)rect
{
    if(drawsAlternatingRows){
		//We do our grid drawing later
	}else{
		[super drawGridInClipRect:rect];
	}
}

- (void)_drawGridInClipRect:(NSRect)rect
{
    NSEnumerator	*enumerator;
    NSTableColumn	*column;
    float		xPos = 0.5;
    int			intercellWidth = [self intercellSpacing].width;
    
    [[self gridColor] set];
    [NSBezierPath setDefaultLineWidth:1.0];

    enumerator = [[self tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        xPos += [column width] + intercellWidth;

        [NSBezierPath strokeLineFromPoint:NSMakePoint(xPos, rect.origin.y)
                                  toPoint:NSMakePoint(xPos, rect.origin.y + rect.size.height)];
    }
}



@end
