/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
    A subclass of outline view that adds an alternating grid, and forces scrolling to intervals of the lineScroll

    Use setDrawsGrid and setGridColor to configure the drawing of a faint grid
    
    Use setDrawsAlternatingRows and setAlternatingRowColor to configure the horizontal stripes
    
    Use setDrawsAlternatingColumns, setAlternatingColumnColor, and setSecondaryAlternatingColumnColor to configure the vertical stripes
    
*/

#import "AIAlternatingRowOutlineView.h"

@interface AIAlternatingRowOutlineView (PRIVATE)
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected;
- (void)_init;
@end

@implementation AIAlternatingRowOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];

    [self _init];

    return(self);
}

- (id)init
{
    [super init];

    [self _init];

    return(self);
}

- (void)dealloc
{
    [alternatingRowColor release];
    [alternatingColumnColor release];
    [secondaryAlternatingColumnColor release];
    
    [super dealloc];
}

- (void)_init
{
    drawsAlternatingRows = NO;
    alternatingRowColor = nil;

    drawsAlternatingColumns = NO;
    alternatingColumnColor = nil;
    secondaryAlternatingColumnColor = nil;
    
    firstColumnColored = NO;
    
    alternatingColumnRange = NSMakeRange(0,0);
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

- (void)setDrawsAlternatingColumns:(BOOL)flag
{
    drawsAlternatingColumns = flag;
    [self setNeedsDisplay:YES];
}

- (void)setAlternatingColumnColor:(NSColor *)color{
    if(color != alternatingColumnColor){
        [alternatingColumnColor release];
        alternatingColumnColor = [color retain];
        [self setNeedsDisplay:YES];
    }
}
- (NSColor *)alternatingColumnColor{
    return(alternatingColumnColor);
}

- (void)setAlternatingColumnRange:(NSRange)range{
    alternatingColumnRange = range;
    [self setNeedsDisplay:YES];
}

- (void)setFirstColumnColored:(BOOL)colored{
    firstColumnColored = colored;
    [self setNeedsDisplay:YES];
}
- (BOOL)firstColumnColored{
    return(firstColumnColored);
}

- (void)setSecondaryAlternatingColumnColor:(NSColor *)color{
    if(color != secondaryAlternatingColumnColor){
        [secondaryAlternatingColumnColor release];
        secondaryAlternatingColumnColor = [color retain];
        [self setNeedsDisplay:YES];
    }
}
- (NSColor *)secondaryAlternatingColumnColor{
    return(secondaryAlternatingColumnColor);
}

// Scrolling ----------------------------------------------------------------------
- (void)tile
{
    [super tile];

    [[self enclosingScrollView] setVerticalLineScroll: ([self rowHeight] + [self intercellSpacing].height) ];
}

//#warning scroll restriction code.. disabled for now... ? 
/*- (NSRect)adjustScroll:(NSRect)proposedVisibleRect
{
    int		lineScroll = [[self enclosingScrollView] verticalLineScroll];
    float	desiredLocation = proposedVisibleRect.origin.y;
    int 	trueVal = desiredLocation;
    float	ratio;
    int		height;
    
    height = ([self frame].size.height - [[self enclosingScrollView] documentVisibleRect].size.height);
    
    if(height != 0){
        ratio = (float)height / (float)(height + ( height % lineScroll) );

        desiredLocation += (desiredLocation * (1.0 - ratio));
//        NSLog(@"%0.2f  (%i/%i)  (%i -> %i)",ratio,(int)height,(int)(height + ( height % lineScroll)), (int)trueVal, (int)desiredLocation);
    
        //Offset by 1/2 the line scroll (To avoid cutting off the bottom line)
        desiredLocation += (lineScroll / 2);
    
        //Move the location to an interval of the line scroll
        proposedVisibleRect.origin.y = (int)(desiredLocation - ((int)desiredLocation % lineScroll));

        NSLog(@"%0.2f  (%i/%i) %i -> %i -> %i",ratio,(int)height,(int)(height + ( height % lineScroll)), (int)trueVal, (int)(trueVal * (1.0 - ratio)), (int)proposedVisibleRect.origin.y);
    
}
    return(proposedVisibleRect);
}*/

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
    [self _drawRowInRect:[self rectOfRow:row] colored:(!(row % 2) && ![self isRowSelected:row]) selected:(row == [self selectedRow])];

    [super drawRow:row clipRect:rect];
}

//Draw a row
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
    if(drawsAlternatingColumns){ //Draw alternating columns (and rows) in the outline view
        int		column;
        int		numberOfColumns = [self numberOfColumns];
        NSRange		range;
        
        //Get the range of columns to color
        range = alternatingColumnRange;
        if(alternatingColumnRange.length == 0){
            range = NSMakeRange(0,numberOfColumns);
        }

        //Move across the columns one at a time, drawing their background color
        for(column = 0; column < numberOfColumns; column++){
            NSRect	segmentRect = NSIntersectionRect( rect, [self rectOfColumn:column]);

            //Draw the row background
            if(!selected){
                if( (NSLocationInRange(column,range)) && ((firstColumnColored && !(column % 2)) || (!firstColumnColored && (column % 2))) ){
                    if(!colored){
                        [alternatingColumnColor set];
                        [NSBezierPath fillRect:segmentRect];
                    }else{
                        [secondaryAlternatingColumnColor set];
                        [NSBezierPath fillRect:segmentRect];
                    }
                }else if(drawsAlternatingRows && colored){
                    [alternatingRowColor set];
                    [NSBezierPath fillRect:segmentRect];
                }
            }
        }
        
    }else if(drawsAlternatingRows){ //Draw alternating rows in the outline view
        //Draw the row background
        if(colored && !selected){
            NSRect	segmentRect = rect;

            segmentRect.origin.x = 0;
            segmentRect.size.width = [self frame].size.width;

            [alternatingRowColor set];
            [NSBezierPath fillRect:segmentRect];
        }

    }
}



@end
