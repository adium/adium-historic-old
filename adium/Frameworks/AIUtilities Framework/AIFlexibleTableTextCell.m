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

@interface AIFlexibleTableTextCell (PRIVATE)
- (NSRange)validRangeFromIndex:(int)sourceIndex to:(int)destIndex;
- (NSTextStorage *)createTextSystemWithString:(NSAttributedString *)inString size:(NSSize)inSize container:(NSTextContainer **)outContainer layoutManager:(NSLayoutManager **)outLayoutManager;
@end

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

    //Create the text system
    textStorage = [[self createTextSystemWithString:string size:NSMakeSize(1e7, 1e7) container:&textContainer layoutManager:&layoutManager] retain];
    [textContainer retain];
    [layoutManager retain];

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
    //Reformat the text
    [textContainer setContainerSize:NSMakeSize(inWidth - (leftPadding + rightPadding), 1e7)];
    glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

    //Save the new cell dimensions
    cellSize = [layoutManager usedRectForTextContainer:textContainer].size;
}

//Draw our custom content
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //Draw our string contents
    if(drawContents){
        //Correctly size the text container
        if(!NSEqualSizes([textContainer containerSize], cellFrame.size)){
            [textContainer setContainerSize:cellFrame.size];
            glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
        }

        //Draw
        if(!selected || ![[tableView window] isKeyWindow] || [[tableView window] firstResponder] != tableView){
            [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:cellFrame.origin];
            [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];

        }else{
            //Temporarily color the text white
            [layoutManager addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor alternateSelectedControlTextColor], NSForegroundColorAttributeName, nil] forCharacterRange:NSMakeRange(0,[textStorage length])];

            [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:cellFrame.origin];
            [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];

            //Remove the white
            [layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0,[textStorage length])];

        }
    }
}


//Editing ---------------------------------------------------------------------------------
//Edit this cell
- (void)editAtRow:(int)inRow column:(AIFlexibleTableColumn *)inColumn inView:(NSView *)controlView
{
    NSRect	editorRect;
    
    //Create the editor
    editor = [[NSTextView alloc] init];
    [editor setDelegate:self];
    [editor setEditable:YES];
    [editor setSelectable:YES];
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

//Selection ---------------------------------------------------------------------------------
//Return the character index under the specified point
- (int)characterIndexAtPoint:(NSPoint)point
{
    int 	glyphIndex;
    float	fraction;

    //Factor in view padding
    point.x -= [self paddingInset].width;
    point.y -= [self paddingInset].height;

    //Get the character index
    glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer fractionOfDistanceThroughGlyph:&fraction];
    if(fraction > 0.5){
        glyphIndex += 1;
    }

    return([layoutManager characterIndexForGlyphAtIndex:glyphIndex]);
}

//Change this cell's selection
- (BOOL)selectFrom:(int)sourceIndex to:(int)destIndex
{
    NSRange	selectionRange = [self validRangeFromIndex:sourceIndex to:destIndex];

    //Remove any existing coloring
    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0,[textStorage length])];

    //Convert those coordinates to the nearest glyph index
    [layoutManager addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor selectedTextBackgroundColor], NSBackgroundColorAttributeName, nil] forCharacterRange:selectionRange];

    return(NO);    
}

//Returns a portion of the string represented by this cell
- (NSAttributedString *)stringFromIndex:(int)sourceIndex to:(int)destIndex
{
    NSRange	selectionRange = [self validRangeFromIndex:sourceIndex to:destIndex];

    return([string attributedSubstringFromRange:selectionRange]);
}



// Private -------------
//Converts the specified source/dest index to a valid NSRange
- (NSRange)validRangeFromIndex:(int)sourceIndex to:(int)destIndex
{
    NSRange	range;

    //The range must go from left to right
    if(sourceIndex < destIndex){
        range = NSMakeRange(sourceIndex, destIndex - sourceIndex);
    }else{
        range = NSMakeRange(destIndex, sourceIndex - destIndex);
    }

    //The range cannot start before our string
    if(range.location < 0){
        range.location = 0;
    }

    //The range cannot end beyond the end of our string
    if(range.location + range.length > [textStorage length]){
        range.length = [textStorage length] - range.location;
    }

    return(range);
}

//Create a text system
- (NSTextStorage *)createTextSystemWithString:(NSAttributedString *)inString size:(NSSize)inSize container:(NSTextContainer **)outContainer layoutManager:(NSLayoutManager **)outLayoutManager
{
    NSTextStorage	*aTextStorage;
    NSLayoutManager	*aLayoutManager;
    NSTextContainer	*aContainer;

    //Create
    aTextStorage = [[NSTextStorage alloc] initWithAttributedString:inString];
    aContainer = [[NSTextContainer alloc] initWithContainerSize:inSize];
    aLayoutManager = [[NSLayoutManager alloc] init];

    //Setup
    [aContainer setLineFragmentPadding:0.0];
    [aLayoutManager addTextContainer:[aContainer autorelease]];
    [aTextStorage addLayoutManager:[aLayoutManager autorelease]];

    //Return
    if(outContainer) *outContainer = aContainer;
    if(outLayoutManager) *outLayoutManager = aLayoutManager;
    return([aTextStorage autorelease]);
}

@end




