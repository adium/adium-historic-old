//
//  ESContactSortConfigurationWindowController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.

#import "ESContactSortConfigurationWindowController.h"

@interface ESContactSortConfigurationWindowController (PRIVATE)
- (void)removeAllSubviews:(NSView *)view;
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
	
	NSRect  windowFrame = [[self window] frame];
	NSRect  configureViewFrame = [configureView frame];
	NSRect  view_mainFrame;
	
	[self removeAllSubviews:view_main];
	[view_main addSubview:configureView];
	
	[configureView setFrameOrigin:NSMakePoint(0,0)];
	
	view_mainFrame.size = configureViewFrame.size;
	view_mainFrame.origin = NSMakePoint(0,0);
	[view_main setFrame:configureViewFrame];
	
	[[self window] setContentSize:configureViewFrame.size];
}

//Clear a view of all subviews
- (void)removeAllSubviews:(NSView *)view
{
    NSArray			*subviewsArray = [view subviews];
    NSEnumerator	*enumerator = [subviewsArray objectEnumerator];
    NSView			*theSubview;

    while (theSubview = [enumerator nextObject])
    {
        [theSubview removeFromSuperviewWithoutNeedingDisplay];
    }
    
}

@end
