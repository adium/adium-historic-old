//
//  ESContactListWindowHandlingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

#import "ESContactListWindowHandlingPlugin.h"

@implementation ESContactListWindowHandlingPlugin
- (void)installPlugin
{
    //Setup our preferences
    //preferences = [[ESContactListWindowHandlingPreferences contactListWindowHandlingPreferences] retain];
    //Our preference view
    preferences = [[ESContactListWindowHandlingPreferences preferencePane] retain];

    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST];
}

- (void)uninstallPlugin
{

}

@end
