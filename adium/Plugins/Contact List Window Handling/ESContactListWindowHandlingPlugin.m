//
//  ESContactListWindowHandlingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

#import "ESContactListWindowHandlingPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS @"ContactListWindowHandlingDefaults"

@implementation ESContactListWindowHandlingPlugin
- (void)installPlugin
{
    //Setup our preferences
    preferences = [[ESContactListWindowHandlingPreferences contactListWindowHandlingPreferencesWithOwner:owner] retain];
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST];
}

- (void)uninstallPlugin
{
    
}

@end
