//
//  MXImageTextAttachmentCell.m
//  ServiceTest
//
//  Created by Max Cantor on Thu Jun 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MXImageTextAttachmentCell.h"


@implementation MXImageTextAttachmentCell

+ (MXImageTextAttachmentCell *) cellWithPasteboard:(NSPasteboard *)pb
                                        attachment:(NSTextAttachment *)a
                                              flip:(BOOL)f {
    MXImageTextAttachmentCell *cell = [MXImageTextAttachmentCell alloc];
    [cell initWithPasteboard:pb
                  attachment:a
                        flip:f];
    return cell;
}

- (MXImageTextAttachmentCell *) initWithPasteboard:(NSPasteboard *)pb
                                        attachment:(NSTextAttachment *)a {
    attachment = a;
    image = [[NSImage alloc] initWithPasteboard:pb];
    return self;
}
- (MXImageTextAttachmentCell *) initWithPasteboard:(NSPasteboard *)pb
                                        attachment:(NSTextAttachment *)a
                                              flip:(BOOL)f {
    //NSLog(@"abbout to set attachment");
    attachment = a;
    //NSLog(@"about to alloc and init image");
    image = [[NSImage alloc] initWithPasteboard:pb];
    //NSLog(@"Flipping");
    if (f) {[image setFlipped:([image isFlipped] == NO)];}
    return self;
}
- (BOOL)wantsToTrackMouse {return NO;}
- (BOOL)trackMouse:(NSEvent *)theEvent
            inRect:(NSRect)cellFrame
            ofView:(NSView *) controlView
      untilMouseUp:(BOOL)flag {return NO;}

- (NSSize)cellSize {return [image size];}



- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {}
- (void)setAttachment:(NSTextAttachment *)a {attachment = [a retain];}
- (NSTextAttachment *)attachment {return attachment;}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    cellFrame.size.height = [image size].height;
    [image drawInRect:cellFrame fromRect:NSMakeRect(0, 0, [image size].width, [image size].height) operation:NSCompositeSourceOver fraction:1.0];
}

- (NSPoint)cellBaselineOffset {return NSMakePoint(0,0);}


    // Sophisticated cells should implement these in addition to the simpler methods, above.  The class NSTextAttachmentCell implements them to simply call the simpler methods; more complex conformers should implement the simpler methods to call these.
/*
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(unsigned)charIndex;
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(unsigned)charIndex layoutManager:(NSLayoutManager *)layoutManager;
- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(unsigned)charIndex;
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(unsigned)charIndex untilMouseUp:(BOOL)flag;
- (NSRect)cellFrameForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(unsigned)charIndex;

*/
@end
