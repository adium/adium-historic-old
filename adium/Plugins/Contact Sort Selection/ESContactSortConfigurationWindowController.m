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

	[[self window] setContentSize:[configureView frame].size];
	[[self window] setContentView:configureView];
}

@end
