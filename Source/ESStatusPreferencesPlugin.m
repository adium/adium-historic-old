//
//  ESStatusPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESStatusPreferencesPlugin.h"
#import "ESStatusPreferences.h"
#import "AIMenuController.h"
#import <AIUtilities/AIMenuAdditions.h>

/*
 * @class ESStatusPreferencesPlugin
 * @brief Component to install our status preferences pane
 */
@implementation ESStatusPreferencesPlugin

/*
 * @brief Install
 *
 * Install our preference pane, and add a menu item to the Status menu which opens it.
 */
- (void)installPlugin
{
	NSMenuItem *menuItem;
	
	//Install our preference view
    preferences = [[ESStatusPreferences preferencePaneForPlugin:self] retain];	
	
	//Add our menu item
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Edit Status Menu...",nil)
																	target:self
																	action:@selector(showStatusPreferences:)
															 keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_Additions];
}

/*!
 * Open the preferences to the status pane
 */
- (void)showStatusPreferences:(id)sender
{
	[[adium preferenceController] openPreferencesToCategoryWithIdentifier:@"status"];
}

@end
