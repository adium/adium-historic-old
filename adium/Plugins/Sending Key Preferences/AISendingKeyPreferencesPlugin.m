//
//  AISendingKeyPreferencesPlugin.m
//  Adium
//
//  Created by Adam Iser on Sat Mar 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AISendingKeyPreferencesPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AISendingKeyPreferences.h"

#define SENDING_KEY_DEFAULT_PREFS	@"SendingKeyDefaults"

@interface AISendingKeyPreferencesPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AISendingKeyPreferencesPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SENDING_KEY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_GENERAL];

    [self preferencesChanged:nil];

    //Our preference view
    preferences = [[AISendingKeyPreferences sendingKeyPreferencesWithOwner:owner] retain];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

}

- (void)uninstallPlugin
{

}

- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){

    }
}

@end






