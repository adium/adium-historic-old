//
//  ESWebView.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.
//

#import "ESWebView.h"

@interface ESWebView (PRIVATE)
- (void)forwardSelector:(SEL)selector withObject:(id)object;
@end

@implementation ESWebView

//Font Family ----------------------------------------------------------------------------------------------------------
#pragma mark Font Family
- (void)setFontFamily:(NSString *)familyName
{
	[[self preferences] setStandardFontFamily:familyName];
	[[self preferences] setFixedFontFamily:familyName];
	[[self preferences] setSerifFontFamily:familyName];
	[[self preferences] setSansSerifFontFamily:familyName];
}

- (NSString *)fontFamily
{
	return [[self preferences] standardFontFamily];
}


//Key/Paste Forwarding ---------------------------------------------------------------------------------
#pragma mark Key/Paste Forwarding
//When the user attempts to type into the table view, we push the keystroke to the next responder,
//and make it key.  This isn't required, but convienent behavior since one will never want to type
//into this view.
- (void)keyDown:(NSEvent *)theEvent
{
    [self forwardSelector:@selector(keyDown:) withObject:theEvent];
}

- (void)forwardSelector:(SEL)selector withObject:(id)object
{
	id	responder = [self nextResponder];
	
	//When walking the responder chain, we want to skip ScrollViews and ClipViews.
	while(responder && ([responder isKindOfClass:[NSClipView class]] || [responder isKindOfClass:[NSScrollView class]])){
		responder = [responder nextResponder];
	}
	
	if(responder){
		[[self window] makeFirstResponder:responder]; //Make it first responder
		[responder tryToPerform:selector with:object]; //Pass it this key event
	}
}


//Accepting Drags ------------------------------------------------------------------------------------------------------
#pragma mark Accepting Drags
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	//we should do magic things here, catch the text, images, files or URLs being dragged and act accordingly.
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	
}

@end
