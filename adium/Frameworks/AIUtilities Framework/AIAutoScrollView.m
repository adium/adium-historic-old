//
//  AIAutoScrollView.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAutoScrollView.h"

#define AUTOSCROLL_CATCH_SIZE 	20	//The distance (in pixels) that the scrollview must be within (from the bottom) for auto-scroll to kick in.

@implementation AIAutoScrollView

- (void)setDocumentView:(NSView *)aView
{
    [super setDocumentView:aView];

    //Observe the document view's frame changes
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentFrameDidChange:) name:NSViewFrameDidChangeNotification object:aView];

    [self scrollToBottom];
    oldDocumentFrame = [aView frame];
}

//Our frame changes
- (void)setFrame:(NSRect)frameRect
{
    NSRect	documentVisibleRect = [self documentVisibleRect];
    NSRect	documentFrame = [[self documentView] frame];
    BOOL 	autoScroll;

    //Autoscroll if we're scrolled close to the bottom
    autoScroll = ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > (documentFrame.size.height - AUTOSCROLL_CATCH_SIZE));

    //Set our frame first
    [super setFrame:frameRect];

    //Then auto-scroll
    if(autoScroll) [self scrollToBottom];
}

//When our document resizes
- (void)documentFrameDidChange:(NSNotification *)notification
{
    NSRect	documentVisibleRect = [self documentVisibleRect];
    NSRect	newDocumentFrame = [[self documentView] frame];
    
    //We autoscroll if the height of the document frame changed AND (Using the old frame to calculate) we're scrolled close to the bottom.
    if((newDocumentFrame.size.height != oldDocumentFrame.size.height) && ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > (oldDocumentFrame.size.height - AUTOSCROLL_CATCH_SIZE))){
        [self scrollToBottom];
    }

    //Remember the new frame
    oldDocumentFrame = newDocumentFrame;
}

//Scroll to the bottom of our view
- (void)scrollToBottom
{
    NSClipView	*contentView = [self contentView];
    
    [contentView scrollToPoint:NSMakePoint(0, [[self documentView] frame].size.height - [self documentVisibleRect].size.height)];
    [self reflectScrolledClipView:contentView];
}

@end


