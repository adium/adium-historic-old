//
//  AILinkTextView.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AILinkTextView.h"
#import "AILinkTrackingController.h"

@implementation AILinkTextView

- (id)initWithFrame:(NSRect)frame
{
    [super initWithFrame:frame];

    linkTrackingController = [[AILinkTrackingController linkTrackingControllerForTextView:self] retain];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:self];
    
    [[self window] resetCursorRects];

    return(self);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)mouseDown:(NSEvent*)theEvent
{
    if(![linkTrackingController handleMouseDown:theEvent withOffset:NSMakeSize(0,0)]){
        [super mouseDown:theEvent];
    }    
}

- (void)frameDidChange:(NSNotification *)notification
{
    [[self window] resetCursorRects];
}

- (void)resetCursorRects
{
    NSPoint	containerOrigin;
    NSRect	visibleRect;
    
    containerOrigin = [self textContainerOrigin];
    visibleRect = NSOffsetRect ([self visibleRect], -containerOrigin.x, -containerOrigin.y);

    [linkTrackingController trackLinksInRect:visibleRect withOffset:NSMakeSize(0,0)];
}

@end
