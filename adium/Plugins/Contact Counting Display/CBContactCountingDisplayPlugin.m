//
//  CBContactCountingDisplayPlugin.m
//  Adium XCode
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBContactCountingDisplayPlugin.h"
#import "CBContactCountingDisplayPreferences.h"

#define CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS @"ContactCountingDisplayDefaults"

@implementation CBContactCountingDisplayPlugin

- (void)installPlugin
{
    allCount = YES;
    visibleCount = YES;
    
	[self preferencesChanged:nil];
	
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST];
    prefs = [[CBContactCountingDisplayPreferences contactCountingDisplayPreferences] retain];

    //install our observers
    [[adium contactController] registerListObjectObserver:self];
	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST] == 0)
	{
		NSEnumerator		*enumerator;
		AIListObject		*object;
				
		allCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_ALL_CONTACTS group:PREF_GROUP_CONTACT_LIST] boolValue];
        visibleCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_VISIBLE_CONTACTS group:PREF_GROUP_CONTACT_LIST] boolValue];
        		
		enumerator = [[[adium contactController] contactList] objectEnumerator]; //We need all the groups
		
		while(object = [enumerator nextObject]){
            [[adium contactController] listObjectAttributesChanged:object modifiedKeys:[self updateListObject:object keys:nil silent:YES]];
        }
    }
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
	[prefs release];
	
    //we are no longer an observer
    [[adium notificationCenter] removeObserver:self];
    [[adium contactController] unregisterListObjectObserver:self];
}

@end
