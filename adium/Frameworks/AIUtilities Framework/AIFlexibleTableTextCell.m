/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIFlexibleTableTextCell.h"
#import "AIFlexibleTableView.h"
#import "AICursorAdditions.h"
#import "AITooltipUtilities.h"
#import "AILinkTrackingController.h"
#import "AITextAttachmentExtension.h"
#import "AIAttributedStringAdditions.h"

#define FRACTIONAL_PADDING 1.0
#define	EDITOR_X_INSET	-6
#define	EDITOR_Y_INSET	-1

@interface AIFlexibleTableTextCell (PRIVATE)
- (NSRange)validRangeFromIndex:(int)sourceIndex to:(int)destIndex;
- (NSTextStorage *)createTextSystemWithString:(NSAttributedString *)inString size:(NSSize)inSize container:(NSTextContainer **)outContainer layoutManager:(NSLayoutManager **)outLayoutManager;
- (void)_buildLinkArray;
- (void)_showTooltipForEvent:(NSEvent *)theEvent;
- (void)_endTrackingMouse;
- (BOOL)handleEmoticonClicks:(NSEvent *)theEvent withOffset:(NSSize)offset;
@end

BOOL _mouseInRects(NSPoint aPoint, NSRectArray someRects, int arraySize, BOOL flipped);
NSRectArray _copyRectArray(NSRectArray someRects, int arraySize);

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
    attributedString = [[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease];

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
    NSRange	scanRange;
    
    [super init];

    textStorage = nil;
    textContainer = nil;
    layoutManager = nil;
    linkTrackingController = nil;
    containsLinks = NO;

    cellSize = [inString size];
    string = [inString retain];
    frame = NSMakeRect(0,0,0,0);

    //Create the text system
    textStorage = [[self createTextSystemWithString:string size:NSMakeSize(1e7, 1e7) container:&textContainer layoutManager:&layoutManager] retain];
    [textContainer retain];
    [layoutManager retain];

    //Check if our string contains any links
    scanRange = NSMakeRange(0, 0);
    while(NSMaxRange(scanRange) < [textStorage length]){
        if([textStorage attribute:NSLinkAttributeName atIndex:NSMaxRange(scanRange) effectiveRange:&scanRange]){
            containsLinks = YES;
        }
    }
        
    
    return(self);
}

- (void)dealloc
{    
    [textStorage release];
    [textContainer release];
    [layoutManager release];
    [string release];
    [linkTrackingController release];

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
    if(drawContents && glyphRange.length != 0){
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

- (NSRange)rangeForWordAtIndex:(int)index
{
    return ([textStorage doubleClickAtIndex:index]);
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

    //return([[string safeString] attributedSubstringFromRange:selectionRange]);
    return([[textStorage attributedSubstringFromRange:selectionRange] safeString]);
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


// Link Tracking -------------------------------------------------------------------------------
- (BOOL)usesCursorRects
{
    return(containsLinks);
}

//Reset our cursor tracking rects in the view
- (void)resetCursorRectsInView:(NSView *)controlView visibleRect:(NSRect)visibleRect
{
    if(!linkTrackingController){
        //Setup our link tracking
        linkTrackingController = [[AILinkTrackingController linkTrackingControllerForView:tableView withTextStorage:textStorage layoutManager:layoutManager textContainer:textContainer] retain];
    }

    [linkTrackingController trackLinksInRect:visibleRect withOffset:NSMakeSize(-[self frame].origin.x, -[self frame].origin.y)];
}

- (BOOL)handleMouseDown:(NSEvent *)theEvent
{
    BOOL	handled = NO;
    NSSize offset = NSMakeSize(-[self frame].origin.x, -[self frame].origin.y);
             if(containsLinks){
                handled = ([linkTrackingController handleMouseDown:theEvent withOffset:NSMakeSize(-[self frame].origin.x, -[self frame].origin.y)]);
            }else{
                handled = (NO);
            }

            if (TRUE) {	// Add check for emoticons being present, if too slow
                handled = [self handleEmoticonClicks:theEvent withOffset:offset];
        }
    return handled;
}

- (BOOL)handleEmoticonClicks:(NSEvent *)theEvent withOffset:(NSSize)offset
{
    BOOL	handled = NO;
    unsigned int	glyphIndex;
    unsigned int	charIndex;
    float			glyphFraction;
    
    //Find clicked char index
    NSPoint mouseLoc = [tableView convertPoint:[theEvent locationInWindow] fromView:nil];
    mouseLoc.x += offset.width;
    mouseLoc.y += offset.height;
    
    glyphIndex = [layoutManager glyphIndexForPoint:mouseLoc inTextContainer:textContainer fractionOfDistanceThroughGlyph:&glyphFraction];
    charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    
    if(charIndex >= 0 && charIndex < [textStorage length]  && (glyphFraction != 1.0/* && glyphFraction != 0.0*/)){	// Make sure click actually landed on
                                        // the character and not past it
        // Check for emoticons to turn into text
        if ([[textStorage string] characterAtIndex:charIndex] == NSAttachmentCharacter){
            NSString	*repStr = [[textStorage attribute:NSAttachmentAttributeName atIndex:charIndex effectiveRange:nil] string];
            
            if (repStr != nil){
                NSMutableAttributedString	*repAttStr = [[NSMutableAttributedString alloc] initWithString:repStr];
                //NSAttributedString			*origStr = [[textStorage attributedSubstringFromRange:NSMakeRange(charIndex,1)] retain];
                AITextAttachmentExtension		*origSmiley = [textStorage attribute:NSAttachmentAttributeName atIndex:charIndex effectiveRange:nil];
                NSMutableDictionary				*attributes = [[textStorage attributesAtIndex:charIndex effectiveRange:nil] mutableCopy];
                
                //NSLog (@"Saving image string, whose text is %@", [origStr string]);
                
                unsigned int	tempIndex = charIndex;
                NSColor			*tempColor = nil;
                
                if (tempIndex > 0)
                    while ((tempColor = [textStorage attribute:NSForegroundColorAttributeName atIndex: --tempIndex effectiveRange:nil]) == nil && tempIndex != 0);
                else if ([textStorage length] > 1)
                    while ((tempColor = [textStorage attribute:NSForegroundColorAttributeName atIndex: ++tempIndex effectiveRange:nil]) == nil && tempIndex != ([textStorage length] - 1));
                if (tempColor)
                    [attributes		setObject:tempColor forKey:NSForegroundColorAttributeName];
                [attributes		setObject:origSmiley forKey:@"IKHiddenAttachment"];
                // Add unique ID attribute so that ranges remain distinct
                [attributes		setObject:[NSNumber numberWithInt:charIndex * mouseLoc.x] forKey:@"IKHiddenAttachmentUniq"];
                [attributes		removeObjectForKey:NSAttachmentAttributeName];
                
                [repAttStr addAttributes:attributes range:NSMakeRange(0,[repAttStr length])];
                // Add attribute holding original string with attachment
                //[repAttStr addAttribute:@"IKHiddenAttachment" value:origSmiley range:NSMakeRange(0,[repAttStr length])];
                // Add unique ID attribute so that ranges remain distinct
                //[repAttStr addAttribute:@"IKHiddenAttachmentUniq" value:[NSNumber numberWithInt:charIndex * mouseLoc.x] range:NSMakeRange(0,[repAttStr length])];
                
                // Insert string
                [textStorage replaceCharactersInRange:NSMakeRange(charIndex,1) withAttributedString:repAttStr];
                
                handled = true;
            }
            
        // Check for smily text to turn back into emoticons
        } else if ([textStorage attribute:@"IKHiddenAttachment" atIndex:charIndex effectiveRange:nil]) {
            //NSLog (@"MouseDown: Found attachment text to replace w/ attachment");
            // Find what to replace with what
            NSRange		replaceRange;
            
            NSMutableAttributedString	*repAttStr;
            //NSAttributedString	*repAttStr = [textStorage attribute:@"IKHiddenAttachment" atIndex:charIndex effectiveRange:&replaceRange];
            AITextAttachmentExtension	*repAtt = [textStorage attribute:@"IKHiddenAttachment" atIndex:charIndex effectiveRange:&replaceRange];
            
            repAttStr = [[NSMutableAttributedString attributedStringWithAttachment:repAtt] retain];
            [repAttStr addAttributes:[textStorage attributesAtIndex:charIndex effectiveRange:nil] range:NSMakeRange(0,1)];
            
            //NSLog (@"into range: XX, with 'text': %@", [repAttStr string]);
            
            // Replace text with original image
            [textStorage replaceCharactersInRange:replaceRange withAttributedString:repAttStr];
            
            handled = true;
        }
    }
    
    if (handled){
    	glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
        //[tableView setNeedsDisplay:TRUE];
        [tableView resizeCellHeight:self];
    }
    
    return(FALSE);	// Returning TRUE gets in the way of selections, making
                    // copying difficult
}

// locationForGlyphAtIndex... lineFragmentUsedRectForGlyphAtIndex?...boundingRectForGlyphRange?
//invalidateDisplayRangeForGlyphRange
@end

