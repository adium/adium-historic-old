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
    allCount = YES;
    visibleCount = YES;
    
 /*   //Set up preferences
    prefs = [[CBContactCountingDisplayPreferences contactCountingDisplayPreferences] retain];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST]; */

    //install our observers
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [[adium contactController] registerListObjectObserver:self];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
    if([inObject isKindOfClass:[AIListGroup class]] && (visibleCount || allCount) && ([inModifiedKeys containsObject:@"Object Count"] || [inModifiedKeys containsObject:@"VisibleObjectCount"]))
    {
        NSString *addString = nil;
        
        if(visibleCount && allCount)
            addString = [NSString stringWithFormat:@" (%i/%i)", [[inObject statusObjectForKey:@"VisibleObjectCount"] intValue], [[inObject statusObjectForKey:@"ObjectCount"] intValue]];
        else if(visibleCount)
            addString = [NSString stringWithFormat:@" (%i)", [[inObject statusObjectForKey:@"VisibleObjectCount"] intValue]];
        else if(allCount)
            addString = [NSString stringWithFormat:@" (%i)", [[inObject statusObjectForKey:@"ObjectCount"] intValue]];
        
        if(addString)
            [[inObject displayArrayForKey:@"Right Text"] setPrimaryObject:addString withOwner:self];
    }
    
    return(nil);
}

- (void)uninstallPlugin
{
    //we are no longer an observer
    [[adium notificationCenter] removeObserver:self];
    [[adium contactController] unregisterListObjectObserver:self];
}

@end
