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

#import "AILinkTextView.h"
#import "AILinkTrackingController.h"

/*
    A text view that supports link tracking and clicking
 */

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

//If we're being removed from the window, we need to remove our tracking rects
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if(newWindow == nil){ //pass an empty visible rect to end any tracking
        [linkTrackingController trackLinksInRect:NSMakeRect(0,0,0,0) withOffset:NSMakeSize(0,0)];
    }
}

@end
