//
//  AIAlternatingRowTableView.m
//  Adium
//
//  Created by Adam Iser on Sat Feb 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAlternatingRowTableView.h"


@interface AIAlternatingRowTableView (PRIVATE)
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected;
- (void)_init;
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView;
@end


@implementation AIAlternatingRowTableView

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
    
    [super dealloc];
}

- (void)_init
{
    drawsAlternatingRows = NO;
    alternatingRowColor = nil;
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


// Delete key ---------------------------------------------------------------------
- (void)setDataSource:(id)aSource
{
    [super setDataSource:aSource];

    _dataSourceDeleteRow = [aSource respondsToSelector:@selector(tableView:deleteRow:)];
}

//Filter keydowns looking for the delete key (to delete the current selection)
- (void)keyDown:(NSEvent *)theEvent
{
    NSString	*charString = [theEvent charactersIgnoringModifiers];
    unichar	pressedChar = 0;

    //Get the pressed character
    if([charString length] == 1) pressedChar = [charString characterAtIndex:0];

    //Check if 'delete' was pressed
    if(pressedChar == NSDeleteFunctionKey || pressedChar == 127){ //Delete
        [[self dataSource] tableViewDeleteSelectedRows:self]; //Delete the selection
    }else{
        [super keyDown:theEvent]; //Pass the key event on
    }
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
    [self _drawRowInRect:[self rectOfRow:row] colored:(!(row % 2) && row != [self selectedRow]) selected:(row == [self selectedRow])];

    [super drawRow:row clipRect:rect];
}

//Draw a row
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
    if(drawsAlternatingRows){ //Draw alternating rows in the outline view
        NSRect		segmentRect = rect;

        if(colored && !selected){            
            segmentRect.origin.x = 0;
            segmentRect.size.width = [self frame].size.width;
            
            [alternatingRowColor set];
            [NSBezierPath fillRect:segmentRect];
        }
    }
}

@end
