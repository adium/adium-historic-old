//
//  AITextProfilesPlugin.m
//  Adium
//
//  Created by Adam Iser on Tue Jan 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITextProfilesPlugin.h"
#import "AITextProfilePreferences.h"

@implementation AITextProfilesPlugin

- (void)installPlugin
{
    //Register our defaults and install the preference view
//    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_TIME_DEFAULT_PREFERENCES forClass:[self class]] forGroup:GROUP_IDLE_TIME]; //Register our default preferences
    preferences = [[AITextProfilePreferences textProfilePreferencesWithOwner:owner] retain];

    //Observe preference changed notifications, and setup our initial values
//    [[[owner preferenceController] preferenceNotificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
//    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    //unregister, remove, ...
}

@end
