//
//  ESWebDynamicScrollBarsView.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.
//

#import "ESWebView.h"

@interface ESWebView (PRIVATE)
- (void)forwardSelector:(SEL)selector withObject:(id)object;
@end

@implementation ESWebView

+ (void)initialize
{
    //Anything you can do, I can do better...
    [self poseAsClass:[WebView class]];
}

//Key/Paste Forwarding ---------------------------------------------------------------------------------
//When the user attempts to type into the table view, we push the keystroke to the next responder,
//and make it key.  This isn't required, but convienent behavior since one will never want to type
//into this view.

- (BOOL)acceptsFirstResponder
{
	NSLog(@"AcceptsFirst?");
	return YES;
}

- (BOOL)becomeFirstResponder
{
	NSLog(@"BecomeFirst?");
	[super performSelector:@selector(becomeFirstResopnder)];
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSLog(@"keydown! %@",theEvent);
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
	BOOL performed = [super tryToPerform:selector with:object]; //Pass it this key event
	NSLog(@"performed? %i",performed);
//    if(forwardsKeyEvents){
        id	responder = [self nextResponder];
        
        //Make the next responder key (When walking the responder chain, we want to skip ScrollViews and ClipViews).
        while(responder && ([responder isKindOfClass:[NSClipView class]] || [responder isKindOfClass:[NSScrollView class]])){
            responder = [responder nextResponder];
        }
        
        if(responder){
            [[self window] makeFirstResponder:responder]; //Make it first responder
            [[self nextResponder] tryToPerform:selector with:object]; //Pass it this key event
        }
/*        
    }else{
        [super tryToPerform:selector with:object]; //Pass it this key event
    }
*/
}


@end
