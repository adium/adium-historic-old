//
//  ESContactListWindowHandlingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESContactListWindowHandlingPlugin.h"

@implementation ESContactListWindowHandlingPlugin
- (void)installPlugin
{
    preferences = [[ESContactListWindowHandlingPreferences preferencePane] retain];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST];
}

- (void)uninstallPlugin
{

}

@end
