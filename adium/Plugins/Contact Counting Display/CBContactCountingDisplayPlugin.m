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

#define VISIBLE_COUNTING_MENU_ITEM_TITLE @"Count Visible Contacts"
#define ALL_COUNTING_MENU_ITEM_TITLE @"Count All Contacts"

@implementation CBContactCountingDisplayPlugin

- (void)installPlugin
{
    allCount = YES;
    visibleCount = YES;
    
    //set up the prefs
    [self preferencesChanged:nil];
    
    //register our prefs
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST];
    prefs = [[CBContactCountingDisplayPreferences contactCountingDisplayPreferences] retain];
    
    /*
    //init our menu items
    visibleCountingMenuItem = [[NSMenuItem alloc] initWithTitle:VISIBLE_COUNTING_MENU_ITEM_TITLE target:self action:@selector(toggleMenuItem:) keyEquivalent:@""];
    allCountingMenuItem     = [[NSMenuItem alloc] initWithTitle:ALL_COUNTING_MENU_ITEM_TITLE target:self action:@selector(toggleMenuItem:) keyEquivalent:@""];
    */
    
    //install our menu items
    /* there appears to be no way to install into the view menu at this time...*/
    /* I figure it's best to talk this over with Adam before I do anything. */
    
    //install our observers
    [[adium contactController] registerListObjectObserver:self];
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST] == 0)
    {
            allCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_ALL_CONTACTS group:PREF_GROUP_CONTACT_LIST] boolValue];
        visibleCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_VISIBLE_CONTACTS group:PREF_GROUP_CONTACT_LIST] boolValue];
            /*
            if(allCount != [allCountingMenuItem state])
            {
                [allCountingMenuItem setState:allCount];
            }
            if(visibleCount != [visibleCountingMenuItem state])
            {
                [allCountingMenuItem setState:visibleCount];
            }
            */
        //Refresh all
        [[adium contactController] updateAllListObjectsForObserver:self];
    }
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
	NSArray		*modifiedAttributes = nil;
	
	if([inObject isKindOfClass:[AIListGroup class]]){
		if(inModifiedKeys == nil || ( (visibleCount || allCount) && ([inModifiedKeys containsObject:@"ObjectCount"] || [inModifiedKeys containsObject:@"VisibleObjectCount"])))
		{
			NSString *addString = nil;
			
			if(visibleCount && allCount)
				addString = [NSString stringWithFormat:@" (%i/%i)", [[inObject statusObjectForKey:@"VisibleObjectCount"] intValue], [[inObject statusObjectForKey:@"ObjectCount"] intValue]];
			else if(visibleCount)
				addString = [NSString stringWithFormat:@" (%i)", [[inObject statusObjectForKey:@"VisibleObjectCount"] intValue]];
			else if(allCount)
				addString = [NSString stringWithFormat:@" (%i)", [[inObject statusObjectForKey:@"ObjectCount"] intValue]];
			
			[[inObject displayArrayForKey:@"Right Text"] setPrimaryObject:addString withOwner:self];
			modifiedAttributes = [NSArray arrayWithObject:@"Right Text"];
		}
	}
	
    return(modifiedAttributes);
}
/*
- (void)toggleMenuItem:(id)sender
{
    if(sender == allCountingMenuItem || sender == visibleCountingMenuItem)
    {
        [sender setState:[sender state] & NSOnState];
        [adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                            forKey:(sender == allCountingMenuItem ? KEY_COUNT_ALL_CONTACTS : KEY_COUNT_VISIBLE_CONTACTS)
                                             group:PREF_GROUP_CONTACT_LIST];
    }
}
*/
- (void)uninstallPlugin
{
    [prefs release];
        
    //we are no longer an observer
    [[adium notificationCenter] removeObserver:self];
    [[adium contactController] unregisterListObjectObserver:self];
}

@end
