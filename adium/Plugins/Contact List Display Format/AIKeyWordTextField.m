/* 
Copyright (C) 2001-2002  Adam Iser
 */

#import "AIKeyWordTextField.h"

@implementation AIKeyWordTextField

/* mouseDown
 *   on a mousedown, we begin dragging our green keyword
 */
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPasteboard 	*pboard;
    NSImage		*dragImage;
    NSString		*theString = [self stringValue];
    NSSize		theStringSize = [theString sizeWithAttributes:nil];
    NSSize		ourBounds = [self bounds].size;

    NSArray 		*types = [NSArray arrayWithObject:NSTIFFPboardType];

    //---store our keyword on the pasteboard---
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:types owner:self];
    [pboard setString:theString forType:NSStringPboardType];
    
    //---create the drag image (simply the text in a green box)---
    dragImage = [[[NSImage alloc] initWithSize:ourBounds] autorelease];

        [dragImage lockFocus];
        [[NSColor colorWithCalibratedRed:0.647 green:0.741 blue:0.839 alpha:0.5] set];
        NSRectFill(NSMakeRect(0,0,ourBounds.width,ourBounds.height));
        [[NSColor blackColor] set];
        [theString drawInRect:NSMakeRect((ourBounds.width/2) - (theStringSize.width/2),0,theStringSize.width,ourBounds.height) withAttributes:nil];
    [dragImage unlockFocus];
    //---begin the drag---
    [self   dragImage:dragImage
            at:NSMakePoint(0,ourBounds.height)
            offset:NSMakeSize(0,0)
            event:theEvent
            pasteboard:pboard
            source:self
            slideBack:YES];
}

@end
