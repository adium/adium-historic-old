//
//  CBContactCountingDisplayPlugin.m
//  Adium XCode
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBContactCountingDisplayPlugin.h"

#define CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS @"ContactCountingDisplayDefaults"

@implementation CBContactCountingDisplayPlugin

- (void)installPlugin
{
 /*   //Set up preferences
    prefs = [[CBContactCountingDisplayPreferences contactCountingDisplayPreferences] retain];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST]; */

    //install our observers
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactsChanged:) name:ListObject_StatusChanged object:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    
}

- (void)contactsChanged:(NSNotification *)notification
{
    if((visibleCount || allCount) && [[notification object] isOfClass:[AIListGroup class]])
    {
        AIListGroup *group = [notification object];
        NSString *addString = nil;
        
        if(visibleCount && allCount)
            addString = [NSString stringWithFormat:@" (%i/%i)", [[group statusObjectForKey:@"VisibleObjectCount"] intValue], [[group statusObjectForKey:@"ObjectCount"] intValue]];
        else if(visibleCount)
            addString = [NSString stringWithFormat:@" (%i)", [[group statusObjectForKey:@"VisibleObjectCount"] intValue]];
        else if(allCount)
            addString = [NSString stringWithFormat:@" (%i)", [[group statusObjectForKey:@"ObjectCount"] intValue]];
        
        if(addString)
            [[group displayArrayForKey:@"Right Text"] setPrimaryObject:addString withOwner:self];
    }
}

- (void)uninstallPlugin
{
    //we are no longer an observer
    [[adium notificationCenter] removeObserver:self];
}

@end
