//
//  ESContactSortConfigurationWindowController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.

#import "ESContactSortConfigurationWindowController.h"

@interface ESContactSortConfigurationWindowController (PRIVATE)

@end

@implementation ESContactSortConfigurationWindowController

+ (id)showSortConfigurationWindowForController:(AISortController *)controller
{
	static ESContactSortConfigurationWindowController   *sharedInstance = nil;
	
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:@"SortConfiguration"];
    }
	
	[sharedInstance configureForController:controller];
	
	[sharedInstance showWindow:nil];
	
	return sharedInstance;
}

- (void)configureForController:(AISortController *)controller
{
	//Configure the title
	[[self window] setTitle:[controller configureSortWindowTitle]];
	
	//Configure the view
	NSView  *configureView = [controller configureView];

	[[self window] setContentView:configureView];
	[[self window] setContentSize:[configureView frame].size];
}

@end
