//
//  AIModularPane.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 18 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIModularPane.h"


@implementation AIModularPane

//Return a new modular pane
+ (AIModularPane *)modularPane
{
    return([[[self alloc] init] autorelease]);
}

//Return a new modular pane, passing plugin
+ (AIModularPane *)modularPaneForPlugin:(id)inPlugin
{
    return([[[self alloc] initForPlugin:inPlugin] autorelease]);
}

//Init, passing plugin
- (id)initForPlugin:(id)inPlugin
{
    plugin = inPlugin;
    return([self init]);
}

//Init
- (id)init
{
    [super init];
    view = nil;
    return(self);
}

//Compare to another category view (for sorting on the preference window)
- (NSComparisonResult)compare:(AIModularPane *)inPane
{
    return([[self label] caseInsensitiveCompare:[inPane label]]);
}

//Returns our view
- (NSView *)view
{
    if(!view){
        //Load and configure our view
        [NSBundle loadNibNamed:[self nibName] owner:self];
        [self viewDidLoad];
		if([self resizable]) [view setAutoresizingMask:(NSViewMaxYMargin)];
    }
    
    return(view);
}

//Close our view
- (void)closeView
{
	if(view){
		[self viewWillClose];
		[view release]; view = nil;
	}
}


//For subclasses -------------------------------------------------------------------------------
//Pane label
- (NSString *)label
{
	return(@"");
}

//Nib to load
- (NSString *)nibName
{
    return(@"");    
}

//Configure the preference view
- (void)viewDidLoad
{
    
}

//Preference view is closing
- (void)viewWillClose
{
    
}

//Apply a changed controls
- (IBAction)changePreference:(id)sender
{
    [self configureControlDimming];
}

//Configure control dimming
- (void)configureControlDimming
{
    
}

//Resizable
- (void)resizable
{
	return(NO);
}



@end
