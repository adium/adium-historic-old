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

//Key/Paste Forwarding ---------------------------------------------------------------------------------
//When the user attempts to type into the table view, we push the keystroke to the next responder,
//and make it key.  This isn't required, but convienent behavior since one will never want to type
//into this view.

- (void)keyDown:(NSEvent *)theEvent
{
    [self forwardSelector:@selector(keyDown:) withObject:theEvent];
}

- (void)pasteAsPlainText:(id)sender
{
    [self forwardSelector:@selector(pasteAsPlainText:) withObject:sender];
}

- (void)pasteAsRichText:(id)sender
{
    [self forwardSelector:@selector(pasteAsRichText:) withObject:sender];
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

@end
/*
@implementation ESWebHTMLView

+ (void)initialize
{
	[self poseAsClass:[WebHTMLView class]];
}

- (void)mouseMoved:(NSEvent *)event
{
	NSLog(@"Html view; mouse moved %@",event);
}

@end
*/