//
//  AIFlexibleTableTextCell.m
//  Adium
//
//  Created by Adam Iser on Thu Jan 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableTextCell.h"
#import "AIFlexibleTableView.h"

#define FRACTIONAL_PADDING 1.0
#define	EDITOR_X_INSET	-6
#define	EDITOR_Y_INSET	-1

@implementation AIFlexibleTableTextCell

//Create a new cell from an attributed string
+ (AIFlexibleTableTextCell *)cellWithAttributedString:(NSAttributedString *)inString
{
    return([[[self alloc] initWithAttributedString:inString] autorelease]);
}

//Create a new cell from a regular string and properties
+ (AIFlexibleTableTextCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment background:(NSColor *)inBackColor gradient:(NSColor *)inGradientColor
{
    AIFlexibleTableTextCell	*cell;
    NSDictionary		*attributes;
    NSMutableParagraphStyle	*paragraphStyle;
    NSAttributedString		*attributedString;

    //Create a paragraph style with the correct alignment
    paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setAlignment:inAlignment];

    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:inTextColor, NSForegroundColorAttributeName, inFont, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    attributedString = [[NSAttributedString alloc] initWithString:inString attributes:attributes];

    //Build the cell
    cell = [AIFlexibleTableTextCell cellWithAttributedString:attributedString];
    if(inGradientColor){
        [cell setBackgroundGradientFrom:inBackColor to:inGradientColor];
    }else{
        [cell setBackgroundColor:inBackColor];
    }

    return(cell);
}

- (AIFlexibleTableTextCell *)initWithAttributedString:(NSAttributedString *)inString
{
    [super init];

    textStorage = nil;
    textContainer = nil;
    layoutManager = nil;

    cellSize = [inString size];
    string = [inString retain];
    frame = NSMakeRect(0,0,0,0);

    return(self);
}

- (void)dealloc
{
    [textStorage release];
    [textContainer release];
    [layoutManager release];
    [string release];

    [super dealloc];
}

//The desired size of our cell without wrapping
- (NSSize)cellSize
{
    return(NSMakeSize(cellSize.width + (leftPadding + rightPadding) + FRACTIONAL_PADDING, cellSize.height + (topPadding + bottomPadding))); //We add padding to offset any fractional character widths
}

//Dynamically resizes this cell for the desired width
- (void)sizeCellForWidth:(float)inWidth
{
    if(!textStorage){
        //Once a dynamic width is requested, we build the necessary text management instances to handle wrapping and formatting.  This avoids the overhead (memory and speed) of these classes when drawing simple, non-wrapping strings.  Once these classes are present, this cell will use them to draw and properly wrap.

        //Setup the layout manager and text container
        textStorage = [[NSTextStorage alloc] initWithAttributedString:string];
        textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1e7, 1e7)];
        layoutManager = [[NSLayoutManager alloc] init];

        [textContainer setLineFragmentPadding:0.0];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
    }

    //Reformat the text
    [textContainer setContainerSize:NSMakeSize(inWidth - (leftPadding + rightPadding)/* - FRACTIONAL_PADDING*/, 1e7)];
    glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

    //Save the new cell dimensions
    cellSize = [layoutManager usedRectForTextContainer:textContainer].size;
}

//Draw our custom content
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //Draw our string contents
    if(drawContents){
        if(!selected){
            if(layoutManager){ //Draw our string with wrapping (slower)
                [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];
            }else{
                [string drawInRect:cellFrame]; //Draw our string without wrapping (faster)
            }
        }else{
            NSMutableAttributedString *mutableString = [string mutableCopy];

            [mutableString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,[mutableString length])];

            if(layoutManager){ //Draw our string with wrapping (slower)
                NSTextStorage	*whiteTextStorage = [[NSTextStorage alloc] initWithAttributedString:mutableString];
                NSTextContainer	*whiteTextContainer = [[NSTextContainer alloc] initWithContainerSize:cellFrame.size];
                NSLayoutManager	*whiteLayoutManager = [[NSLayoutManager alloc] init];

                [whiteTextContainer setLineFragmentPadding:0.0];
                [whiteLayoutManager addTextContainer:whiteTextContainer];
                [whiteTextStorage addLayoutManager:whiteLayoutManager];

                [whiteLayoutManager drawGlyphsForGlyphRange:[whiteLayoutManager glyphRangeForTextContainer:whiteTextContainer]
                                                    atPoint:cellFrame.origin];

                [whiteTextStorage release];
                [whiteTextContainer release];
                [whiteLayoutManager release];

            }else{
                [mutableString drawInRect:cellFrame]; //Draw our string in white

            }
            [mutableString release];
        }
    }
}

//Edit this cell
- (void)editAtRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn inView:(NSView *)controlView
{
    NSRect	editorRect;
    
    //Create the editor
    editor = [[NSTextView alloc] init];
    [editor setDelegate:self];
    [editor setEditable:YES];
    [editor setSelectable:YES];
    //    [editor setTextContainerInset:[cell paddingInset]];
    //    [editor setBackgroundColor:[NSColor orangeColor]];
    [editor setFrame:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height)];
    [[editor textStorage] setAttributedString:string];
    [editor setSelectedRange:NSMakeRange(0,[[editor string] length])];
    
    editorScroll = [[NSScrollView alloc] init];
    [editorScroll setDocumentView:editor];
    [editorScroll setBorderType:NSBezelBorder];
    [editorScroll setHasVerticalScroller:NO];
    [editorScroll setHasHorizontalScroller:NO];

    editorRect = NSInsetRect([self frame], EDITOR_X_INSET, EDITOR_Y_INSET);
    editorRect.origin.x += leftPadding;
    editorRect.size.width -= leftPadding + rightPadding;
    editorRect.origin.y += topPadding;
    editorRect.size.height -= topPadding + bottomPadding;
    
    [editorScroll setFrame:editorRect];

    editedColumn = inColumn;
    editedRow = inRow;
    
    //Make it visible and key
    [controlView addSubview:editorScroll];
    [[controlView window] makeFirstResponder:editor];
}

//End editing
- (id <NSCopying>)endEditing
{
    NSAttributedString	*newValue = [[editor textStorage] retain]; //We retain this string to make sure it's not released by the editor when it closes.

    //Close the editor
    [editorScroll removeFromSuperview];
    [editorScroll release]; editorScroll = nil;
    [editor release]; editor = nil;

    return([newValue autorelease]);
}

//Resize our cell (as necessary) when our required frame changes
- (void)textDidChange:(NSNotification *)notification
{
    float textHeight = [[editor layoutManager] usedRectForTextContainer:[editor textContainer]].size.height;

    textHeight -= EDITOR_Y_INSET * 2; //We need to offset for the frame

    if([self frame].size.height != textHeight){
        [tableView setHeightOfCellAtRow:editedRow column:editedColumn to:textHeight];
        [editorScroll setFrameSize:NSMakeSize([editorScroll frame].size.width, textHeight)];
    }
}

@end








