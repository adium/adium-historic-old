//
//  AIBorderlessListWindowController.m
//  Adium
//
//  Created by Adam Iser on Mon Jul 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIBorderlessListWindowController.h"

@interface AIBorderlessListWindowController (PRIVATE)
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification;
@end

@implementation AIBorderlessListWindowController

//Init
- (id)init
{
	[super init];
	
	//Unlike a normal window, the system doesn't assist us in keeping the borderless contact list on a visible screen
	//So we'll observe screen changes and ensure that the contact list stays on a valid screen
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(centerWindowOnMainScreenIfNeeded:) 
															   name:NSApplicationDidChangeScreenParametersNotification 
															 object:nil];

	return(self);
}

//Borderless nib
- (NSString *)nibName
{
    return(@"ContactListWindowTransparent");    
}

//Ensure we're on the main screen on load
- (void)windowDidLoad
{
	[super windowDidLoad];
	[self centerWindowOnMainScreenIfNeeded:nil];
}	

//If our window is no longer on a screen, move it to the main screen and center
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification
{
	if(![[self window] screen]){
		[[self window] setFrameOrigin:[[NSScreen mainScreen] frame].origin];
		[[self window] center];
	}
}

@end
