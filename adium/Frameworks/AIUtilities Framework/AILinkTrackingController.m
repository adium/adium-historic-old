//
//  AILinkTracking.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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
- (BOOL)_beginCursorTrackingInRect:(NSRect)visibleRect;
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
- (BOOL)trackLinksInRect:(NSRect)visibleRect
{
    //remove any existing tooltips
    [self _setMouseOverLink:nil atPoint:NSMakePoint(0,0)];

    //Reset the cursor tracking rects
    [self _endCursorTracking];
    return([self _beginCursorTrackingInRect:visibleRect]);
}

//Called when the mouse enters the link
- (void)mouseEntered:(NSEvent *)theEvent
{
    [self _setMouseOverLink:(AIFlexibleLink *)[theEvent userData]
                    atPoint:[[theEvent window] convertBaseToScreen:[theEvent locationInWindow]]];
}

//Called when the mouse leaves the link
- (void)mouseExited:(NSEvent *)theEvent
{
    [self _setMouseOverLink:NO atPoint:NSMakePoint(0,0)];
}

//Called when the mouse moves within the link
/*- (void)mouseMoved:(NSEvent *)theEvent
{
    [self _showTooltipAtScreenPoint:[[theEvent window] convertBaseToScreen:[theEvent locationInWindow]]];
}*/

//Offset all link tracking within the view
- (void)setOffset:(NSSize)inOffset
{
    offset = inOffset;
}


//Handle a mouse down.  Returns NO if the mouse down event should continue to be processed
- (BOOL)handleMouseDown:(NSEvent *)theEvent
{
    BOOL		success = NO;
    NSPoint		mouseLoc;
    unsigned int	glyphIndex;
    unsigned int	charIndex;
    NSRectArray		linkRects = nil;

    [self _setMouseOverLink:NO atPoint:NSMakePoint(0,0)]; //Remove any tooltips

    //Find clicked char index
    mouseLoc = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
    mouseLoc.x -= offset.width;
    mouseLoc.y -= offset.height;

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
                        mouseLoc.x -= offset.width;
                        mouseLoc.y -= offset.height;

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
    oldFirstResponder = nil;
    offset = NSMakeSize(0,0);

    //
    controlView = [inControlView retain];
    textStorage = [inTextStorage retain];
    layoutManager = [inLayoutManager retain];
    textContainer = [inTextContainer retain];
    
    return(self);
}

//Begins cursor tracking, registering tracking rects for all our available links
- (BOOL)_beginCursorTrackingInRect:(NSRect)visibleRect
{
    int scanLocation = 0;
    int stringLength = [textStorage length];
    BOOL weContainLinks = NO;

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
            weContainLinks = YES;
            
            //A link may be spread across multiple rects.. if so, it's okay to treat the link as multiple, seperate links.
            for(index = 0; index < linkCount; index++){
                NSRect			linkRect = linkRects[index];
                NSRect			visibleLinkRect;
                NSTrackingRectTag	trackingTag;

                //Adjust the link to our view's coordinates
                linkRect.origin.y += offset.height;
                linkRect.origin.x += offset.width;

                visibleLinkRect = NSIntersectionRect(linkRect, visibleRect);
                if(!NSIsEmptyRect(visibleLinkRect)){ //Skip the link if it's not visible

                    //Create a flexible link instance
                    AIFlexibleLink	*link = [[[AIFlexibleLink alloc] initWithTrackingRect:linkRect url:linkURL] autorelease];
                    if(!linkArray) linkArray = [[NSMutableArray alloc] init];
                    [linkArray addObject:link];

                    //Install a tracking rect for the link (The userData of each tracking rect is the AIFlexibleLink it covers)
                    trackingTag = [controlView addTrackingRect:visibleLinkRect owner:self userData:link assumeInside:NO];
                    [link setTrackingTag:trackingTag];

                }
            }
        }

        //Move along the string (In preperation for another search)
        scanLocation = linkRange.location + linkRange.length;
    }

    return(weContainLinks);
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

        //We need to set ourself as first responder to get mouse moved events.
        //We preserve the current first responder first, and restore it when the mouse leaves our rect
        oldFirstResponder = [[controlView window] firstResponder];
        [[controlView window] makeFirstResponder:controlView];
        
//        [[controlView window] setAcceptsMouseMovedEvents:YES]; //Start generating mouse-moved events
        [[NSCursor handPointCursor] set]; //Set the link cursor
        [self _showTooltipAtScreenPoint:inPoint]; //Show the tooltip

    }else if(inHoveredLink == nil && mouseOverLink == YES){
        [[NSCursor arrowCursor] set]; //Restore the regular cursor
//        [[controlView window] setAcceptsMouseMovedEvents:NO]; //Stop generating mouse-moved events
        [self _showTooltipAtScreenPoint:NSMakePoint(0,0)]; //Hide the tooltip

        [[controlView window] makeFirstResponder:oldFirstResponder]; //Restore the original first responder

        [hoveredLink release]; hoveredLink = nil;
        [hoveredString release]; hoveredString = nil;
        mouseOverLink = NO;
    }

}

//Show the tooltip
- (void)_showTooltipAtScreenPoint:(NSPoint)inPoint
{
    if(inPoint.x != 0 && inPoint.y != 0){ //Show tooltip
        if([[controlView window] isKeyWindow]){
            [AITooltipUtilities showTooltipWithString:hoveredString onWindow:nil atPoint:inPoint];
        }

    }else{ //Hide tooltip
        [AITooltipUtilities showTooltipWithString:nil onWindow:nil atPoint:NSMakePoint(0,0)];
        
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
