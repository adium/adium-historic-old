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
#define	PREF_GROUP_CONTACT_LIST_DISPLAY                 @"Contact List Display"
#define KEY_SHOW_OFFLINE_CONTACTS                       @"Show Offline Contacts"

@implementation CBContactCountingDisplayPlugin

- (void)installPlugin
{
    //register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_LIST];

    //init our menu items
    visibleCountingMenuItem = [[NSMenuItem alloc] initWithTitle:VISIBLE_COUNTING_MENU_ITEM_TITLE 
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
    [[adium menuController] addMenuItem:visibleCountingMenuItem toLocation:LOC_View_Unnamed_C];		

    allCountingMenuItem = [[NSMenuItem alloc] initWithTitle:ALL_COUNTING_MENU_ITEM_TITLE
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
	[[adium menuController] addMenuItem:allCountingMenuItem toLocation:LOC_View_Unnamed_C];		
    
	//set up the prefs
	allCount = NO;
	visibleCount = NO;
	showOffline = NO;
	
    [self preferencesChanged:nil];
	
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil ||
	   [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST] ||
	   [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]) {

		BOOL newAllCount;
		BOOL newVisibleCount;
		BOOL newShowOffline;
		
		newAllCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_ALL_CONTACTS 
                                                                     group:PREF_GROUP_CONTACT_LIST] boolValue];
        newVisibleCount = [[[adium preferenceController] preferenceForKey:KEY_COUNT_VISIBLE_CONTACTS
                                                                     group:PREF_GROUP_CONTACT_LIST] boolValue];
        newShowOffline =  [[[adium preferenceController] preferenceForKey:KEY_SHOW_OFFLINE_CONTACTS
                                                                     group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];
		if ((newAllCount && !allCount) || (newVisibleCount && !visibleCount)){
			if (!allCount && !visibleCount){
				//Install our observer if we are now counting contacts in some form but weren't before
				[[adium contactController] registerListObjectObserver:self];
			}
			
			allCount = newAllCount;
			visibleCount = newVisibleCount;
			showOffline = newShowOffline;
			
			//Refresh all
			[[adium contactController] updateAllListObjectsForObserver:self];
			
		}else if ((!newAllCount && allCount) || (!newVisibleCount && visibleCount)){
			allCount = newAllCount;
			visibleCount = newVisibleCount;
			showOffline = newShowOffline;
			
			//Refresh all
			[[adium contactController] updateAllListObjectsForObserver:self];
			
			if (!allCount && !visibleCount){
				//Remove our observer since we are now doing no counting
				[[adium contactController] unregisterListObjectObserver:self];
			}
			
		}else if (newShowOffline != showOffline){
			//The state of showing offline contacts changed; this is a special case, so update our list objects
			showOffline = newShowOffline;
			
			//Refresh all
			[[adium contactController] updateAllListObjectsForObserver:self];
		}
		
		
		if(allCount != [allCountingMenuItem state]) {
			[allCountingMenuItem setState:allCount];
		}
		if(visibleCount != [visibleCountingMenuItem state]) {
			[visibleCountingMenuItem setState:visibleCount];
		}
    }
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
	NSArray		*modifiedAttributes = nil;
	
	if([inObject isKindOfClass:[AIListGroup class]] &&
	   (inModifiedKeys == nil || 
		((visibleCount || allCount) && 
		 [inModifiedKeys containsObject:@"ObjectCount"] || [inModifiedKeys containsObject:@"VisibleObjectCount"]))) {
		
		NSString	*addString = nil;
		NSNumber	*objectCountNumber = nil;
		NSNumber	*visibleObjectCountNumber = nil;
		
		if(showOffline && (visibleCount || allCount)){ 
			// If we are showing offline contacts, just show the object count since it will always be the same as the visible object count
			objectCountNumber = [inObject statusObjectForKey:@"ObjectCount"];
			if (!objectCountNumber) objectCountNumber = [NSNumber numberWithInt:0];
			
		} else {
			if(visibleCount) visibleObjectCountNumber = [inObject statusObjectForKey:@"VisibleObjectCount"];
			if (allCount) objectCountNumber = [inObject statusObjectForKey:@"ObjectCount"];
		}
		
		//Build a string to add to the right of the name which shows any information we just extracted
		if (objectCountNumber && visibleObjectCountNumber){
			addString = [NSString stringWithFormat:@" (%i/%i)", [visibleObjectCountNumber intValue], [objectCountNumber intValue]];
		}else if(objectCountNumber){
			addString = [NSString stringWithFormat:@" (%i)", [objectCountNumber intValue]];
		}else if(visibleObjectCountNumber){
			addString = [NSString stringWithFormat:@" (%i)", [visibleObjectCountNumber intValue]];
		}
		
		if (addString){
			AIMutableOwnerArray *rightTextArray = [inObject displayArrayForKey:@"Right Text"];
			
			[rightTextArray setObject:addString withOwner:self priorityLevel:High_Priority];
			modifiedAttributes = [NSArray arrayWithObject:@"Right Text"];
		}else{
			AIMutableOwnerArray *rightTextArray = [inObject displayArrayForKey:@"Right Text" create:NO];
			
			//If there is a right text object now but there shouldn't be anymore, remove it
			if ([rightTextArray objectWithOwner:self]){
				[rightTextArray setObject:nil withOwner:self priorityLevel:High_Priority];
				modifiedAttributes = [NSArray arrayWithObject:@"Right Text"];
			}
		}
	}
	
	return(modifiedAttributes);
}

- (void)toggleMenuItem:(id)sender
{
    if(sender == allCountingMenuItem || sender == visibleCountingMenuItem) {
		BOOL	shouldEnable = ![sender state];
		
		//Toggle and set
        [sender setState:shouldEnable];
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:shouldEnable]
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
