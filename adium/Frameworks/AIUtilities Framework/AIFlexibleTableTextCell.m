//
//  AIFlexibleTableTextCell.m
//  Adium
//
//  Created by Adam Iser on Thu Jan 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableTextCell.h"
#import "AIFlexibleTableView.h"
#import "AICursorAdditions.h"
#import "AIFlexibleLink.h"
#import "AITooltipUtilities.h"

#define FRACTIONAL_PADDING 1.0
#define	EDITOR_X_INSET	-6
#define	EDITOR_Y_INSET	-1

@interface AIFlexibleTableTextCell (PRIVATE)
- (NSRange)validRangeFromIndex:(int)sourceIndex to:(int)destIndex;
- (NSTextStorage *)createTextSystemWithString:(NSAttributedString *)inString size:(NSSize)inSize container:(NSTextContainer **)outContainer layoutManager:(NSLayoutManager **)outLayoutManager;
- (void)_buildLinkArray;
- (void)_showTooltipForEvent:(NSEvent *)theEvent;
- (void)_endTrackingMouse;
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
    [super init];

    textStorage = nil;
    textContainer = nil;
    layoutManager = nil;
    linkArray = nil;

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


// Link Tracking -------------------------------------------------------------------------------
//Reset our cursor tracking rects in the view
- (BOOL)resetCursorRectsInView:(NSView *)controlView visibleRect:(NSRect)visibleRect
{
    NSEnumerator	*enumerator;
    AIFlexibleLink	*link;

    [self _endTrackingMouse]; //remove any existing tooltips
    
    //Remove all existing tracking rects
    enumerator = [linkArray objectEnumerator];
    while((link = [enumerator nextObject])){
        [controlView removeTrackingRect:[link trackingTag]];
    }

    if(visibleRect.size.width && visibleRect.size.height){
        //Rebuild our link array
        [self _buildLinkArray];
        
        //Insert a tracking rect for each link
        enumerator = [linkArray objectEnumerator];
        while((link = [enumerator nextObject])){
            NSTrackingRectTag	trackingTag;

            trackingTag = [controlView addTrackingRect:NSIntersectionRect([link trackingRect],visibleRect) owner:self userData:link assumeInside:NO];
            [link setTrackingTag:trackingTag];
        }
    }

    return(YES);
}    

//Builds an array of links within our text content
- (void)_buildLinkArray
{
    int scanLocation = 0;
    int stringLength = [string length];

    //Release the old array
    [linkArray release]; linkArray = nil;

    //Process all links
    while(scanLocation != NSNotFound && scanLocation < stringLength){
        NSRange		linkRange;
        NSString	*linkURL;

        //Search for a link
        if((linkURL = [textStorage attribute:NSLinkAttributeName atIndex:scanLocation effectiveRange:&linkRange])){
            NSRectArray		linkRects;
            int			index;
            int			linkCount;

            //Get an array of rects that define the location of this link
            linkRects = [layoutManager rectArrayForCharacterRange:linkRange
                                     withinSelectedCharacterRange:linkRange
                                                  inTextContainer:textContainer
                                                        rectCount:&linkCount];

            //A link may be spread across multiple rects.. if so, it's okay to treat the link as multiple, seperate links.
            for(index = 0; index < linkCount; index++){
                NSRect	linkRect = linkRects[index];

                //Adjust the link to our table view's coordinates
                linkRect.origin.y += [self frame].origin.y;
                linkRect.origin.x += [self frame].origin.x;

                //Create and add the link
                AIFlexibleLink	*link = [[[AIFlexibleLink alloc] initWithTrackingRect:linkRect url:linkURL] autorelease];
                if(!linkArray) linkArray = [[NSMutableArray alloc] init];
                [linkArray addObject:link];
            }
        }

        //Move along the string (In preperation for another search)
        scanLocation = linkRange.location + linkRange.length;
    }
}

//Called when the mouse enters the link
- (void)mouseEntered:(NSEvent *)theEvent
{
    hoveredLink = [(AIFlexibleLink *)[theEvent userData] retain];
    hoveredString = [[NSString stringWithFormat:@"%@", [hoveredLink url]] retain];

    //We need to set ourself as first responder to get mouse moved events.  We preserve the current first responder first, and restore it when the mouse leaves our rect
    oldFirstResponder = [[tableView window] firstResponder];
    [[tableView window] makeFirstResponder:tableView];

    [[NSCursor handPointCursor] set]; //Set the link cursor
    [tableView setAcceptsMouseMovedEvents:YES]; //Start generating mouse-moved events
    [self _showTooltipForEvent:theEvent]; //Show the tooltip
}

//Called when the mouse leaves the link
- (void)mouseExited:(NSEvent *)theEvent
{
    [self _endTrackingMouse];
}

//Stop tracking mouse events
- (void)_endTrackingMouse
{
    [[NSCursor arrowCursor] set]; //Restore the regular cursor
    [tableView setAcceptsMouseMovedEvents:NO]; //Stop generating mouse-moved events
    [self _showTooltipForEvent:nil]; //Hide the tooltip

    [[tableView window] makeFirstResponder:oldFirstResponder];

    [hoveredLink release]; hoveredLink = nil;
    [hoveredString release]; hoveredString = nil;
}

//Called when the mouse moves within the link
- (void)mouseMoved:(NSEvent *)theEvent
{
    [self _showTooltipForEvent:theEvent];
}

//Show the tooltip
- (void)_showTooltipForEvent:(NSEvent *)theEvent
{
    if(theEvent){ //Show tooltip for it
        if([[tableView window] isKeyWindow]){
            [AITooltipUtilities showTooltipWithString:hoveredString
                                            onWindow:nil
                                            atPoint:[[theEvent window] convertBaseToScreen:[theEvent locationInWindow]]];
        }
    }else{
        [AITooltipUtilities showTooltipWithString:nil onWindow:nil atPoint:NSMakePoint(0,0)];
        
    }
}


- (BOOL)mouseDown:(NSEvent *)theEvent
{
    BOOL		success = NO;
    NSPoint		mouseLoc;
    unsigned int	glyphIndex;
    unsigned int	charIndex;
    NSRectArray		linkRects = nil;

    [self _endTrackingMouse]; //Remove any tooltips
    
    //Find clicked char index
    mouseLoc = [tableView convertPoint:[theEvent locationInWindow] fromView:nil];
    mouseLoc.x -= [self frame].origin.x;
    mouseLoc.y -= [self frame].origin.y;
    
    glyphIndex = [layoutManager glyphIndexForPoint:mouseLoc inTextContainer:textContainer fractionOfDistanceThroughGlyph:nil];
    charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    
    if(charIndex >= 0 && charIndex < [textStorage length]){
        NSString	*linkString;
        NSURL		*linkURL;
        NSRange		linkRange;

        //Check if click is in valid link attributed range, and is inside the bounds of that style range, else fall back to default handler
        linkString = [textStorage attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:&linkRange];
        if(linkString == nil || [linkString length] == 0)
            return [super mouseDown:theEvent];

        //add http:// to the link string if a protocol wasn't specified
        if([linkString rangeOfString:@"://"].location == NSNotFound && [linkString rangeOfString:@"mailto:"].location == NSNotFound){
            linkURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",linkString]];
        }else{
            linkURL = [NSURL URLWithString:linkString];
        }

        //bail if a link couldn't be made
        if(linkURL){
            unsigned int	eventMask;
            NSDate		*distantFuture;
            int			linkCount;
            BOOL		done = NO;
            BOOL		inRects = NO;

            //Setup Tracking Info
            distantFuture = [NSDate distantFuture];
            eventMask = NSLeftMouseUpMask | NSRightMouseUpMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask;

            //Find region of clicked link
            linkRects = [layoutManager rectArrayForCharacterRange:linkRange
                                     withinSelectedCharacterRange:linkRange
                                                  inTextContainer:textContainer
                                                        rectCount:&linkCount];
            linkRects = _copyRectArray(linkRects, linkCount);

            //One last check to make sure we're really in the bounds of the link. Useful when the link runs up to the end of the document and a click in the blank area below still pases the style range test above.
            if(_mouseInRects(mouseLoc, linkRects, linkCount, NO)){
                //Draw ourselves as clicked and kick off tracking
                [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:linkRange];
                [tableView setNeedsDisplayInRect:[self frame]];
                
                while(!done){
                    NSPoint		mouseLoc;

                    //Get the next event and mouse location
                    theEvent = [NSApp nextEventMatchingMask:eventMask untilDate:distantFuture inMode:NSEventTrackingRunLoopMode dequeue:YES];
                    mouseLoc = [tableView convertPoint:[theEvent locationInWindow] fromView:nil];
                    mouseLoc.x -= [self frame].origin.x;
                    mouseLoc.y -= [self frame].origin.y;

                    switch([theEvent type]){
                        case NSRightMouseUp:		//Done Tracking Clickscr
                        case NSLeftMouseUp:
                            //If we were still inside the link, draw unclicked and open link
                            if(_mouseInRects(mouseLoc, linkRects, linkCount, NO)){
                                [[NSWorkspace sharedWorkspace] openURL:linkURL];
                            }
                            [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:linkRange];
                            [tableView setNeedsDisplayInRect:[self frame]];
                            done = YES;
                        break;
                        case NSLeftMouseDragged:	//Mouse Moved
                        case NSRightMouseDragged:
                            //Check if we crossed the link region edge
                            if(_mouseInRects(mouseLoc, linkRects, linkCount, NO) && inRects == NO){
                                [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:linkRange];
                                [tableView setNeedsDisplayInRect:[self frame]];
                                inRects = YES;
                            }else if(!_mouseInRects(mouseLoc, linkRects, linkCount, NO) && inRects == YES){
                                [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:linkRange];
                                [tableView setNeedsDisplayInRect:[self frame]];
                                inRects = NO;
                            }
                        break;
                        default:
                        break;
                    }
                }

                success = YES;
            }
        }
    }

    //Free our copy of the link region
    if(linkRects) free(linkRects);
    return(success);
}

//Check for the presence of a point in multiple rects
BOOL _mouseInRects(NSPoint aPoint, NSRectArray someRects, int arraySize, BOOL flipped)
{
    int	index;

    for(index = 0; index < arraySize; index++){
        if(NSMouseInRect(aPoint, someRects[index], flipped)){
            return(YES);
        }
    }

    return(NO);
}

NSRectArray _copyRectArray(NSRectArray someRects, int arraySize)
{
    NSRectArray		newArray;

    newArray = malloc(sizeof(NSRect)*arraySize);
    memcpy( newArray, someRects, sizeof(NSRect)*arraySize );
    return newArray;
}
    
@end

