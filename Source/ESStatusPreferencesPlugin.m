//
//  ESStatusPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESStatusPreferencesPlugin.h"
#import "ESStatusPreferences.h"

@implementation ESStatusPreferencesPlugin

- (void)installPlugin
{
	//Install our preference view
    preferences = [[ESStatusPreferences preferencePaneForPlugin:self] retain];	
	
}

@end
