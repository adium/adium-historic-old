//
//  AIFlexibleTableCell.m
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AIFlexibleTableCell.h"

@interface AIFlexibleTableCell (PRIVATE)
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (id)init;
- (void)dealloc;
@end

@implementation AIFlexibleTableCell

//init
- (id)init
{
    [super init];

    backgroundColor = nil;
    gradientColor = nil;
    dividerColor = nil;
    drawContents = YES;

    leftPadding = 0;
    rightPadding = 0;
    topPadding = 0;
    leftPadding = 0;

    selected = NO;

    return(self);
}

//dealloc
- (void)dealloc
{
    [backgroundColor release];
    [gradientColor release];
    [dividerColor release];

    [super dealloc];
}


//Configure ----------------------------------------------------------------------
- (void)setBackgroundColor:(NSColor *)inColor
{
    if(backgroundColor != inColor){
        [backgroundColor release]; backgroundColor = nil;
        backgroundColor = [inColor retain];
    }
    [gradientColor release]; gradientColor = nil;
}

- (void)setBackgroundGradientFrom:(NSColor *)inColorA to:(NSColor *)inColorB
{
    if(backgroundColor != inColorA){
        [backgroundColor release]; backgroundColor = nil;
        backgroundColor = [inColorA retain];
    }
    if(gradientColor != inColorB){
        [gradientColor release]; gradientColor = nil;
        gradientColor = [inColorB retain];
    }
}

- (void)setDrawContents:(BOOL)inValue
{
    drawContents = inValue;
}

- (void)setDividerColor:(NSColor *)inColor
{
    if(inColor != dividerColor){
        [dividerColor release]; dividerColor = nil;
        dividerColor = [inColor retain];
    }
}

- (void)setPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom
{
    leftPadding = inLeft;
    rightPadding = inRight;
    topPadding = inTop;
    bottomPadding = inBottom;
}

- (void)setSelected:(BOOL)inSelected
{
    selected = inSelected;
}

- (void)setTableView:(AIFlexibleTableView *)inView
{
    tableView = inView;
}



//Access ------------------------------------------------------------------------------
- (NSSize)paddingInset
{
    return(NSMakeSize(leftPadding, topPadding));
}

- (void)editAtRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn inView:(NSView *)controlView
{
    
}


//Editing ------------------------------------------------------------------------------
- (id <NSCopying>)endEditing
{
    return(nil);
}

//Cursor Tracking ----------------------------------------------------------------------
- (BOOL)usesCursorRects
{
    return(NO);
}

- (BOOL)resetCursorRectsInView:(NSView *)controlView visibleRect:(NSRect)visibleRect
{
    return(NO);
}

//Handle a mouse down
- (BOOL)handleMouseDown:(NSEvent *)theEvent
{
    return(NO);
}



//Selecting ----------------------------------------------------------------------------
//Returns a character index within this cell for the specified point
- (int)characterIndexAtPoint:(NSPoint)point
{
    return(0); //Return 0 since we don't contain text
}

//Sets this cell's selection to the proposed index
- (BOOL)selectFrom:(int)sourceIndex to:(int)destIndex
{
    //Return NO - passing the selection to the next view
    return(NO);
}

//
- (NSAttributedString *)stringFromIndex:(int)sourceIndex to:(int)destIndex
{
    return(nil);
}


//Sizing ------------------------------------------------------------------------------
//Returns the size required to display this cell without wrapping
- (NSSize)cellSize
{
    return(NSMakeSize(0,0));
}

//Dynamically resizes this cell for the desired width
- (void)sizeCellForWidth:(float)inWidth
{
}


// Drawing -------------------------------------------------------------------------------
//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{    
    //Draw the background
    if(!selected){
        if(!gradientColor){ //Plain background
            [backgroundColor set];
            [NSBezierPath fillRect:cellFrame];

        }else{ //Gradient background
            [AIGradient drawGradientInRect:cellFrame from:backgroundColor to:gradientColor];

        }
    }else{
        if([[tableView window] isKeyWindow] && [[tableView window] firstResponder] == tableView){
            [[NSColor alternateSelectedControlColor] set];
        }else{
            [[NSColor secondarySelectedControlColor] set];
        }

        [NSBezierPath fillRect:cellFrame];
    }

    //Draw our divider line (offset 0.5 for an aliased line)
    if(dividerColor){
        [dividerColor set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + 0.5)
                                  toPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + 0.5)];
    }

    //Draw Contents
    cellFrame.origin.x += leftPadding;
    cellFrame.size.width -= leftPadding + rightPadding;
    cellFrame.origin.y += topPadding;
    cellFrame.size.height -= topPadding + bottomPadding;
    [self drawContentsWithFrame:cellFrame inView:controlView];
}

//Draw our contents
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{

}

//Set and retrieve our frame
- (void)setFrame:(NSRect)inFrame
{
    frame = inFrame;
}
- (NSRect)frame{
    return(frame);
}


@end
