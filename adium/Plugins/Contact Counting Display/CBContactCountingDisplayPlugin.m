//
//  CBContactCountingDisplayPlugin.m
//  Adium
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//

#import "CBContactCountingDisplayPlugin.h"
#import "CBContactCountingDisplayPreferences.h"

#define CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS  @"ContactCountingDisplayDefaults"

#define VISIBLE_COUNTING_MENU_ITEM_TITLE		@"Count Visible Contacts"
#define ALL_COUNTING_MENU_ITEM_TITLE			@"Count All Contacts"

@implementation CBContactCountingDisplayPlugin

- (void)installPlugin
{
	
    //register our prefs
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_LIST];

    //init our menu items
    visibleCountingMenuItem = [[NSMenuItem alloc] initWithTitle:VISIBLE_COUNTING_MENU_ITEM_TITLE 
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
    [[adium menuController] addMenuItem:visibleCountingMenuItem toLocation:LOC_View_Unnamed_C];		

    allCountingMenuItem     = [[NSMenuItem alloc] initWithTitle:ALL_COUNTING_MENU_ITEM_TITLE
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
	[[adium menuController] addMenuItem:allCountingMenuItem toLocation:LOC_View_Unnamed_C];		
    
	//set up the prefs
    [self preferencesChanged:nil];
	
    //install our observers
    [[adium contactController] registerListObjectObserver:self];
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST] == 0) {
            allCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_ALL_CONTACTS 
																 group:PREF_GROUP_CONTACT_LIST] boolValue];
        visibleCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_VISIBLE_CONTACTS
																 group:PREF_GROUP_CONTACT_LIST] boolValue];

		if(allCount != [allCountingMenuItem state]) {
			[allCountingMenuItem setState:allCount];
		}
		if(visibleCount != [visibleCountingMenuItem state]) {
			[visibleCountingMenuItem setState:visibleCount];
		}
		
		if (notification) {
			//Refresh all
			[[adium contactController] updateAllListObjectsForObserver:self];
		}
    }
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
	NSArray		*modifiedAttributes = nil;
	
	if([inObject isKindOfClass:[AIListGroup class]]){
		if(inModifiedKeys == nil || 
		   ( (visibleCount || allCount) && ([inModifiedKeys containsObject:@"ObjectCount"] || 
											[inModifiedKeys containsObject:@"VisibleObjectCount"]))) {
			NSString *addString = nil;
			
			if(visibleCount && allCount)
				addString = [NSString stringWithFormat:@" (%i/%i)", [[inObject statusObjectForKey:@"VisibleObjectCount"] intValue], [[inObject statusObjectForKey:@"ObjectCount"] intValue]];
			else if(visibleCount)
				addString = [NSString stringWithFormat:@" (%i)", [[inObject statusObjectForKey:@"VisibleObjectCount"] intValue]];
			else if(allCount)
				addString = [NSString stringWithFormat:@" (%i)", [[inObject statusObjectForKey:@"ObjectCount"] intValue]];
			
			[[inObject displayArrayForKey:@"Right Text"] setObject:addString withOwner:self priorityLevel:High_Priority];
			modifiedAttributes = [NSArray arrayWithObject:@"Right Text"];
		}
	}
	
    return(modifiedAttributes);
}

- (void)toggleMenuItem:(id)sender
{
    if(sender == allCountingMenuItem || sender == visibleCountingMenuItem)
    {
        [sender setState:![sender state]];
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:(sender == allCountingMenuItem ? KEY_COUNT_ALL_CONTACTS : KEY_COUNT_VISIBLE_CONTACTS)
											  group:PREF_GROUP_CONTACT_LIST];
    }
}

- (void)uninstallPlugin
{
    //we are no longer an observer
    [[adium notificationCenter] removeObserver:self];
    [[adium contactController] unregisterListObjectObserver:self];
}

@end
