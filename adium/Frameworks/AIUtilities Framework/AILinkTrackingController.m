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

#import "AILinkTrackingController.h"
#import "AIFlexibleLink.h"
#import "AICursorAdditions.h"
#import "AITooltipUtilities.h"

/*
 Add link tracking support to a view/cell.

 - Create an instance of AILinkTracking
 - Call resetCursorRectsInView:visibleRect: in response to resetCursorRects for your view
 - Call setContentString when your content changes
 */

@interface AILinkTrackingController (PRIVATE)
- (id)initForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer;
- (void)_beginCursorTrackingInRect:(NSRect)visibleRect withOffset:(NSSize)offset;
- (void)_endCursorTracking;
- (void)_setMouseOverLink:(AIFlexibleLink *)inHoveredLink atPoint:(NSPoint)inPoint;
- (void)_showTooltipAtScreenPoint:(NSPoint)inPoint;
@end

BOOL _mouseInRects(NSPoint aPoint, NSRectArray someRects, int arraySize, BOOL flipped);
NSRectArray _copyRectArray(NSRectArray someRects, int arraySize);


@implementation AILinkTrackingController

+ (id)linkTrackingControllerForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer
{
    return([[[self alloc] initForView:inControlView withTextStorage:inTextStorage layoutManager:inLayoutManager textContainer:inTextContainer] autorelease]);
}

+ (id)linkTrackingControllerForTextView:(NSTextView *)inTextView
{
    return([[[self alloc] initForView:inTextView withTextStorage:[inTextView textStorage] layoutManager:[inTextView layoutManager] textContainer:[inTextView textContainer]] autorelease]);
}

//Track links in the passed rect.  Returns YES if links exist within our text.
- (void)trackLinksInRect:(NSRect)visibleRect withOffset:(NSSize)offset
{
    //remove any existing tooltips
    [self _setMouseOverLink:nil atPoint:NSMakePoint(0,0)];

    //Reset the cursor tracking rects
    [self _endCursorTracking];
    [self _beginCursorTrackingInRect:visibleRect withOffset:offset];
}

//Called when the mouse enters the link
- (void)mouseEntered:(NSEvent *)theEvent
{
    NSWindow		*window = [theEvent window];
    AIFlexibleLink	*link = [theEvent userData];
    NSPoint		location;

    location = [link trackingRect].origin;
#warning I've had bad access here.  Somehow the links are getting dealloced?

    location = [controlView convertPoint:location toView:nil];
    location = [[theEvent window] convertBaseToScreen:location];

    //Ignore the mouse entry if our view is hidden, or our window is non-main
    if([window isMainWindow] && [controlView canDraw]){
        [self _setMouseOverLink:link
                        atPoint:location];
    }
}

//Called when the mouse leaves the link
- (void)mouseExited:(NSEvent *)theEvent
{
    [self _setMouseOverLink:NO atPoint:NSMakePoint(0,0)];
}

//Handle a mouse down.  Returns NO if the mouse down event should continue to be processed
- (BOOL)handleMouseDown:(NSEvent *)theEvent withOffset:(NSSize)offset
{
    BOOL		success = NO;
    NSPoint		mouseLoc;
    unsigned int	glyphIndex;
    unsigned int	charIndex;
    NSRectArray		linkRects = nil;

    [self _setMouseOverLink:NO atPoint:NSMakePoint(0,0)]; //Remove any tooltips

    //Find clicked char index
    mouseLoc = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
    mouseLoc.x += offset.width;
    mouseLoc.y += offset.height;

    glyphIndex = [layoutManager glyphIndexForPoint:mouseLoc inTextContainer:textContainer fractionOfDistanceThroughGlyph:nil];
    charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

    if(charIndex >= 0 && charIndex < [textStorage length]){
        NSString	*linkString;
        NSURL		*linkURL;
        NSRange		linkRange;

        //Check if click is in valid link attributed range, and is inside the bounds of that style range, else fall back to default handler
        linkString = [textStorage attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:&linkRange];
        if(linkString != nil && [linkString length] != 0){
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
                    [controlView setNeedsDisplay:YES];

                    while(!done){
                        NSPoint		mouseLoc;

                        //Get the next event and mouse location
                        theEvent = [NSApp nextEventMatchingMask:eventMask untilDate:distantFuture inMode:NSEventTrackingRunLoopMode dequeue:YES];
                        mouseLoc = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
                        mouseLoc.x += offset.width;
                        mouseLoc.y += offset.height;

                        switch([theEvent type]){
                            case NSRightMouseUp:		//Done Tracking Clickscr
                            case NSLeftMouseUp:
                                //If we were still inside the link, draw unclicked and open link
                                if(_mouseInRects(mouseLoc, linkRects, linkCount, NO)){
                                    [[NSWorkspace sharedWorkspace] openURL:linkURL];
                                }
                                [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:linkRange];
                                [controlView setNeedsDisplay:YES];
                                done = YES;
                                break;
                            case NSLeftMouseDragged:	//Mouse Moved
                            case NSRightMouseDragged:
                                //Check if we crossed the link region edge
                                if(_mouseInRects(mouseLoc, linkRects, linkCount, NO) && inRects == NO){
                                    [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:linkRange];
                                    [controlView setNeedsDisplay:YES];
                                    inRects = YES;
                                }else if(!_mouseInRects(mouseLoc, linkRects, linkCount, NO) && inRects == YES){
                                    [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:linkRange];
                                    [controlView setNeedsDisplay:YES];
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
    }

    //Free our copy of the link region
    if(linkRects) free(linkRects);
    return(success);
}



//Private ---------------------------------------------------------------------------------
//init
- (id)initForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer
{
    //
    [super init];
    linkArray = nil;
    mouseOverLink = NO;
    hoveredLink = nil;
    hoveredString = nil;

    //
    controlView = [inControlView retain];
    textStorage = [inTextStorage retain];
    layoutManager = [inLayoutManager retain];
    textContainer = [inTextContainer retain];
    
    return(self);
}

//Begins cursor tracking, registering tracking rects for all our available links
- (void)_beginCursorTrackingInRect:(NSRect)visibleRect withOffset:(NSSize)offset
{
    NSRect	visibleContainerRect;
    NSRange	visibleGlyphRange, visibleCharRange;
    NSRange 	scanRange;

    //Get the range of visible characters
    visibleContainerRect = visibleRect;
    visibleContainerRect.origin.x += offset.width;
    visibleContainerRect.origin.y += offset.height;
    visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:visibleContainerRect inTextContainer:textContainer];
    visibleCharRange = [layoutManager characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:NULL];

    //Process all links
    scanRange = NSMakeRange(visibleCharRange.location, 0);
    while(NSMaxRange(scanRange) < NSMaxRange(visibleCharRange)){
        NSString	*linkURL;

        //Get the link
        linkURL = [textStorage attribute:NSLinkAttributeName
                                 atIndex:NSMaxRange(scanRange)
                          effectiveRange:&scanRange];
        if(linkURL){
            NSRectArray		linkRects;
            int			index;
            int			linkCount;

            //Get an array of rects that define the location of this link
            linkRects = [layoutManager rectArrayForCharacterRange:scanRange
                                     withinSelectedCharacterRange:NSMakeRange(NSNotFound, 0)
                                                  inTextContainer:textContainer
                                                        rectCount:&linkCount];
            for(index = 0; index < linkCount; index++){
                NSRect			linkRect;
                NSRect			visibleLinkRect;
                AIFlexibleLink		*link;
                NSTrackingRectTag	trackingTag;

                //Get the link rect
                linkRect = linkRects[index];

                //Adjust the link rect back to our view's coordinates
                linkRect.origin.x -= offset.width;
                linkRect.origin.y -= offset.height;
                visibleLinkRect = NSIntersectionRect(linkRect, visibleRect);
                
                //Create a flexible link instance
                link = [[[AIFlexibleLink alloc] initWithTrackingRect:linkRect url:linkURL] autorelease];
                if(!linkArray) linkArray = [[NSMutableArray alloc] init];
                [linkArray addObject:link];

                //Install a tracking rect for the link (The userData of each tracking rect is the AIFlexibleLink it covers)
                trackingTag = [controlView addTrackingRect:visibleLinkRect owner:self userData:link assumeInside:NO];
                [link setTrackingTag:trackingTag];
            }
        }
    }
}

//Stops cursor tracking, removing all cursor rects
- (void)_endCursorTracking
{
    NSEnumerator	*enumerator;
    AIFlexibleLink	*link;

    //Remove all existing tracking rects
    enumerator = [linkArray objectEnumerator];
    while((link = [enumerator nextObject])){
        [controlView removeTrackingRect:[link trackingTag]];
    }

    //Flush the link array
    [linkArray release]; linkArray = nil;
}

//Configure the mouse for being over a link or not
- (void)_setMouseOverLink:(AIFlexibleLink *)inHoveredLink atPoint:(NSPoint)inPoint
{
    if(inHoveredLink != nil && mouseOverLink == NO){
        //Keep track of the hovered link/string
        [hoveredLink release]; hoveredLink = [inHoveredLink retain];
        [hoveredString release]; hoveredString = [[NSString stringWithFormat:@"%@", [hoveredLink url]] retain];
        mouseOverLink = YES;

        [[NSCursor handPointCursor] set]; //Set link cursor

//        inPoint.y += [inHoveredLink trackingRect].size.height + 3; //Offset the tooltip down a bit
//        inPoint.x -= 9; //And to the left a bit
        [AITooltipUtilities showTooltipWithString:hoveredString onWindow:nil atPoint:inPoint orientation:TooltipAbove]; //Show tooltip

    }else if(inHoveredLink == nil && mouseOverLink == YES){
        [[NSCursor arrowCursor] set]; //Restore the regular cursor
        [AITooltipUtilities showTooltipWithString:nil onWindow:nil atPoint:NSMakePoint(0,0) orientation:TooltipAbove]; //Hide the tooltip

        [hoveredLink release]; hoveredLink = nil;
        [hoveredString release]; hoveredString = nil;
        mouseOverLink = NO;
    }

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
