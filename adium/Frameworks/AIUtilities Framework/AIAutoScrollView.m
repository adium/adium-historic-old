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

#import "AIAutoScrollView.h"

#define AUTOSCROLL_CATCH_SIZE 	20	//The distance (in pixels) that the scrollview must be within (from the bottom) for auto-scroll to kick in.

@implementation AIAutoScrollView

/*
 A subclass of NSScrollView that:

    - Automatically scrolls to bottom on new content
    - Automatically hides & shows the vertical scroller depending on content height
 */


//Auto Scrolling ---------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];

    [super dealloc];
}

- (void)setAutoScrollToBottom:(BOOL)inValue
{
    autoScrollToBottom = inValue;

    [self setDocumentView:[self documentView]];
    [self setFrame:[self frame]];
}

- (void)setDocumentView:(NSView *)aView
{
    [super setDocumentView:aView];

    //Observe the document view's frame changes
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];

    if(autoScrollToBottom){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentFrameDidChange:) name:NSViewFrameDidChangeNotification object:aView];

        [self scrollToBottom];
    }

    oldDocumentFrame = [aView frame];
}

//Our frame changes
- (void)setFrame:(NSRect)frameRect
{
    BOOL 	autoScroll = NO;

    if(autoScrollToBottom){
        NSRect	documentVisibleRect = [self documentVisibleRect];
        NSRect	documentFrame = [[self documentView] frame];

        //Autoscroll if we're scrolled close to the bottom
        autoScroll = ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > (documentFrame.size.height - AUTOSCROLL_CATCH_SIZE));
    }

    //Set our frame first
    [super setFrame:frameRect];

    //Then auto-scroll
    if(autoScroll) [self scrollToBottom];
}

//When our document resizes
- (void)documentFrameDidChange:(NSNotification *)notification
{
    if(autoScrollToBottom){
        NSRect	documentVisibleRect = [self documentVisibleRect];
        NSRect	newDocumentFrame = [[self documentView] frame];
        
        //We autoscroll if the height of the document frame changed AND (Using the old frame to calculate) we're scrolled close to the bottom.
        if((newDocumentFrame.size.height != oldDocumentFrame.size.height) && ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > (oldDocumentFrame.size.height - AUTOSCROLL_CATCH_SIZE))){
            [self scrollToBottom];
        }
    
        //Remember the new frame
        oldDocumentFrame = newDocumentFrame;
    }
}

//Called as the view resizes or scrolls
- (void)reflectScrolledClipView:(NSClipView *)cView;
{
    [super reflectScrolledClipView:cView];

    //Set our correct scrollbar visibility
    if(autoHideScrollBar){
        [self setCorrectScrollbarVisibility];
    }
}

//Scroll to the bottom of our view
- (void)scrollToBottom
{
    NSClipView	*contentView = [self contentView];
    
    [contentView scrollToPoint:NSMakePoint(0, [[self documentView] frame].size.height - [self documentVisibleRect].size.height)];
    [self reflectScrolledClipView:contentView];
}


//Automatic scrollbar hiding ---------------------------------------------------------------
- (void)setAutoHideScrollBar:(BOOL)inValue
{
    autoHideScrollBar = inValue;
    
    [self setCorrectScrollbarVisibility];
}

//Hides or shows the scrollbar as necessary
- (void)setCorrectScrollbarVisibility
{
    int	visibleHeight = [self documentVisibleRect].size.height;
    int	totalHeight = [[self documentView] frame].size.height;

    //Hide or show scrollbar
    if(totalHeight > visibleHeight){
        if(![self hasVerticalScroller]) [self setHasVerticalScroller:YES];
    }else{
        if([self hasVerticalScroller]) [self setHasVerticalScroller:NO];
    }
}

@end


