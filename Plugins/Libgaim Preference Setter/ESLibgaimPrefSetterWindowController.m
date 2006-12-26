//
//  ESLibgaimPrefSetterWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ESLibgaimPrefSetterWindowController.h"
#import <AdiumLibgaim/CBGaimAccount.h>

@implementation ESLibgaimPrefSetterWindowController

static ESLibgaimPrefSetterWindowController *sharedWindowController = nil;
+ (void)initialize
{
	NSLog(@"ESLibgaimPrefSetterWindowController");
}
+ (void)show
{
	//Create the window
	if (!sharedWindowController) {
		sharedWindowController = [[self alloc] initWithWindowNibName:@"LibgaimPrefSetter"];
	}
	
	//Load the window
	[sharedWindowController window];
	[[sharedWindowController window] makeKeyAndOrderFront:nil];
}

- (IBAction)setPref:(id)sender
{
	switch ([[popUp_type selectedItem] tag]) {
		case ESLibgaimPrefBool:
			gaim_prefs_set_bool([[textField_pref stringValue] UTF8String], ([[textField_value stringValue] intValue] > 0));
			break;
		case ESLibgaimPrefInt:
			gaim_prefs_set_int([[textField_pref stringValue] UTF8String], [[textField_value stringValue] intValue]);
			break;
		case ESLibgaimPrefString:
			gaim_prefs_set_string([[textField_pref stringValue] UTF8String], [[textField_value stringValue] UTF8String]);
	}
	AILog(@"Set %s to %s"[[textField_pref stringValue] UTF8String], [[textField_value stringValue] UTF8String]);
}

@end
