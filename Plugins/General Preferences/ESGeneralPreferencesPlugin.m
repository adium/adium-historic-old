//
//  ESGeneralPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESGeneralPreferencesPlugin.h"
#import "ESGeneralPreferences.h"

@implementation ESGeneralPreferencesPlugin
- (void)installPlugin
{
	//Install our preference view
    preferences = [[ESGeneralPreferences preferencePaneForPlugin:self] retain];	
}

@end
