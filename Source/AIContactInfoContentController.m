//
//  AIContactInfoContentController.m
//  Adium
//
//  Created by Elliott Harris on 1/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AIContactInfoContentController.h"

@interface AIContactInfoContentController (PRIVATE)
-(void)addInspectorView:(NSView *)aView animate:(BOOL)doAnimate;
-(void)animateRemovingRect:(NSRect)aRect inView:(NSView *)aView;
-(void)animateViewIn:(NSView *)aView;
-(void)animateViewOut:(NSView *)aView;
@end


@implementation AIContactInfoContentController

-(void)addInspectorView:(NSView *)aView animate:(BOOL)doAnimate
{
	if(currentView == aView)
		return;
	
	else if(currentView) {
		[self animateViewOut:currentView];
		[currentView removeFromSuperview];
	}
	
	NSRect viewBounds = [aView bounds];
	NSRect contentBounds = [panelContent bounds];
	NSRect inspectorFrame = [infoInspector frame];

	viewBounds.size.height = ((inspectorFrame.size.height - contentBounds.size.height) + viewBounds.size.height);
	viewBounds.origin.x = inspectorFrame.origin.x;
	viewBounds.origin.y = inspectorFrame.origin.y + (inspectorFrame.size.height - viewBounds.size.height);
	
	[infoInspector setFrame:viewBounds display:YES animate:doAnimate];

	[panelContent setFrame:[aView bounds]];
	[panelContent addSubview:aView];
	currentView = aView;
	[self animateViewIn:currentView];
}

-(void)animateRemovingRect:(NSRect)aRect inView:(NSView *)aView
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
	[animationDict setObject:[NSValue valueWithRect:aRect] forKey:NSViewAnimationEndFrameKey];
	[animationDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
	
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}
	

-(void)animateViewIn:(NSView *)aView
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	//Set View for animation
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
	
	//Set View to resize to passed frame size during animation.
	NSRect zeroView = [aView frame];
	[animationDict setObject:[NSValue valueWithRect:zeroView] forKey:NSViewAnimationStartFrameKey];
	
	//Set View to fade in.
	[animationDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
	
	//Create the animation
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}

-(void)animateViewOut:(NSView *)aView
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:3];
	
	//Set View for animation
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
	
	//Set View to resize to 0 during animation.
	NSRect zeroView = [aView frame];
	[animationDict setObject:[NSValue valueWithRect:zeroView] forKey:NSViewAnimationEndFrameKey];
	
	//Set View to fade out.
	[animationDict setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
	
	//Create the animation
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}
@end
