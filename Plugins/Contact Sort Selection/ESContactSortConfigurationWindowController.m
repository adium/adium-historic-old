//
//  ESContactSortConfigurationWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.

#import "ESContactSortConfigurationWindowController.h"

@interface ESContactSortConfigurationWindowController (PRIVATE)

@end

@implementation ESContactSortConfigurationWindowController

+ (id)showSortConfigurationWindowForController:(AISortController *)controller
{
	static ESContactSortConfigurationWindowController   *sharedSortConfigInstance = nil;
	
    if(!sharedSortConfigInstance){
        sharedSortConfigInstance = [[self alloc] initWithWindowNibName:@"SortConfiguration"];
		
		//Remove those buttons we don't want.  removeFromSuperview will confuse the window, so just make them invisible.
		NSButton *standardWindowButton = [[sharedSortConfigInstance window] standardWindowButton:NSWindowMiniaturizeButton];
		[standardWindowButton setFrame:NSMakeRect(0,0,0,0)];
		standardWindowButton = [[sharedSortConfigInstance window] standardWindowButton:NSWindowZoomButton];
		[standardWindowButton setFrame:NSMakeRect(0,0,0,0)];
    }
	
	[sharedSortConfigInstance configureForController:controller];
	
	[sharedSortConfigInstance showWindow:nil];
	
	return sharedSortConfigInstance;
}

- (void)configureForController:(AISortController *)controller
{
	//Configure the title
	[[self window] setTitle:[controller configureSortWindowTitle]];
	
	//Configure the view
	NSView  *configureView = [controller configureView];

	NSSize newSize = [configureView frame].size;
	
	//This will resize the view to the current window size...
	[[self window] setContentView:configureView];
	
	//...so restore the window to the size this view really wants to be
	[[self window] setContentSize:newSize];
}

@end
