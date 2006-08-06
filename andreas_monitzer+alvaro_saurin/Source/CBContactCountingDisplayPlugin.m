/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "CBContactCountingDisplayPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>

#define CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS  @"ContactCountingDisplayDefaults"

#define COUNT_ONLINE_CONTACTS_TITLE				AILocalizedString(@"Show Group Online Count", nil)
#define COUNT_ALL_CONTACTS_TITLE				AILocalizedString(@"Show Group Total Count", nil)

#define PREF_GROUP_CONTACT_LIST					@"Contact List"
#define KEY_COUNT_ALL_CONTACTS					@"Count All Contacts"
#define KEY_COUNT_ONLINE_CONTACTS				@"Count Online Contacts"

#define	KEY_HIDE_CONTACT_LIST_GROUPS			@"Hide Contact List Groups"
#define	PREF_GROUP_CONTACT_LIST_DISPLAY			@"Contact List Display"

/*!
 * @class CBContactCountingDisplayPlugin
 *
 * @brief Component to handle displaying counts of contacts, both online and total, next to group names
 *
 * This componenet adds two menu items, "Count All Contacts" and "Count Online Contacts." Both default to being off.
 * When on, these options display the appropriate count for an AIListGroup's contained objects.
 */
@implementation CBContactCountingDisplayPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_LIST];
	
    //init our menu items
    menuItem_countOnlineObjects = [[NSMenuItem alloc] initWithTitle:COUNT_ONLINE_CONTACTS_TITLE 
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
    [[adium menuController] addMenuItem:menuItem_countOnlineObjects toLocation:LOC_View_Toggles];		

    menuItem_countAllObjects = [[NSMenuItem alloc] initWithTitle:COUNT_ALL_CONTACTS_TITLE
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_countAllObjects toLocation:LOC_View_Toggles];		
    
	//set up the prefs
	countAllObjects = NO;
	countOnlineObjects = NO;
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

/*!
 * @brief Preferences changed
 *
 * PREF_GROUP_CONTACT_LIST preferences changed; update our counting display as necessary.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_CONTACT_LIST]) {
		BOOL oldCountAllObjects = countAllObjects;
		BOOL oldCountOnlineObjects = countOnlineObjects;
		
		countAllObjects = [[prefDict objectForKey:KEY_COUNT_ALL_CONTACTS] boolValue];
		countOnlineObjects = [[prefDict objectForKey:KEY_COUNT_ONLINE_CONTACTS] boolValue];
		
		if ((countAllObjects && !oldCountAllObjects) || (countOnlineObjects && !oldCountOnlineObjects)) {
			//One of the displays is on, but it was off before
			
			if (!oldCountAllObjects && !oldCountOnlineObjects) {
				//Install our observer if we are now counting contacts in some form but weren't before
				//This will update all list objects.
				[[adium contactController] registerListObjectObserver:self];				
			} else {
				//Refresh all
				[[adium contactController] updateAllListObjectsForObserver:self];
			}
			
		} else if ((!countAllObjects && oldCountAllObjects) || (!countOnlineObjects && oldCountOnlineObjects)) {
			//One of the displays is off, but it was on before
			
			//Refresh all
			[[adium contactController] updateAllListObjectsForObserver:self];
			
			if (!countAllObjects && !countOnlineObjects) {
				//Remove our observer since we are now doing no counting
				[[adium contactController] unregisterListObjectObserver:self];
			}
		}
		
		if ([menuItem_countAllObjects state] != countAllObjects) {
			[menuItem_countAllObjects setState:countAllObjects];
		}
		if ([menuItem_countOnlineObjects state] != countOnlineObjects) {
			[menuItem_countOnlineObjects setState:countOnlineObjects];
		}

	} else if (([group isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]) &&
			   (!key || [key isEqualToString:KEY_HIDE_CONTACT_LIST_GROUPS])) {		
		showingGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	}
}

/*!
 * @brief Update the counts when a group changes its object count or a contact signs on or off
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{    
	NSSet		*modifiedAttributes = nil;

	//We never update for an AIAccount object
	if ([inObject isKindOfClass:[AIAccount class]]) return nil;

	/* We check against a nil inModifiedKeys so we can remove our Counting information from the display when the user
	 * toggles it off.
	 *
	 * We update for any group which isn't the root group when its contained objects count changes.
	 * We update a contact's containing group when its online state changes.
	 */	
	if ((inModifiedKeys == nil) ||
	   ((countOnlineObjects || countAllObjects) &&
		(([inObject isKindOfClass:[AIListGroup class]] && [inModifiedKeys containsObject:@"ObjectCount"] && ![[inObject UID] isEqualToString:ADIUM_ROOT_GROUP_NAME]) ||
		 ([inObject isKindOfClass:[AIListContact class]] && [inModifiedKeys containsObject:@"Online"])))) {
		
		/* Obtain the group we want to work with -- for a contact, use its parent group.
		 *
		 * Casting note: We already checked that it isn't an AIAccount. If it's an AIListContact, we get the parentGroup. Otherwise,
		 * it's an AIListGroup and we use the object itself. There is probably a way to set this method up without this convoluted casting interplay.
		 */
		AIListGroup		*targetGroup = ([inObject isKindOfClass:[AIListContact class]] ? 
										[(AIListContact *)inObject parentGroup] :
										(AIListGroup *)inObject);

		NSString		*countString = nil;
		int onlineObjects = 0, totalObjects = 0;

		//Obtain a count of online objects in this group
		if (countOnlineObjects) {
			AIListObject	*containedObject;
			NSEnumerator	*enumerator;
			
			onlineObjects = 0;
			enumerator = [[targetGroup containedObjects] objectEnumerator];
			while ((containedObject = [enumerator nextObject])) {
				if ([containedObject online]) onlineObjects++;
			}
		}
		
		//Obtain a count of all objects in this group
		if (countAllObjects) {
			totalObjects = [[targetGroup statusObjectForKey:@"ObjectCount"] intValue];
		}
	
		//Build a string to add to the right of the name which shows any information we just extracted
		if (countOnlineObjects && countAllObjects) {
			countString = [NSString stringWithFormat:AILocalizedString(@" (%i of %i)", /*comment*/ nil), onlineObjects, totalObjects];
		} else if (countAllObjects) {
			countString = [NSString stringWithFormat:@" (%i)", totalObjects];
		} else if (countOnlineObjects) {
			countString = [NSString stringWithFormat:@" (%i)", onlineObjects];
		}

		if (countString) {
			AIMutableOwnerArray *rightTextArray = [targetGroup displayArrayForKey:@"Right Text"];
			
			[rightTextArray setObject:countString withOwner:self priorityLevel:High_Priority];
			modifiedAttributes = [NSSet setWithObject:@"Right Text"];
		} else {
			AIMutableOwnerArray *rightTextArray = [targetGroup displayArrayForKey:@"Right Text" create:NO];
			
			//If there is a right text object now but there shouldn't be anymore, remove it
			if ([rightTextArray objectWithOwner:self]) {
				[rightTextArray setObject:nil withOwner:self priorityLevel:High_Priority];
				modifiedAttributes = [NSSet setWithObject:@"Right Text"];
			}
		}
	}
	
	return modifiedAttributes;
}

/*!
 * @brief User toggled one of our two menu items
 */
- (void)toggleMenuItem:(id)sender
{
    if ((sender == menuItem_countOnlineObjects) || (sender == menuItem_countAllObjects)) {
		BOOL	newState = ![sender state];
		
		//Toggle and set, which will call back on preferencesChanged: above
        [sender setState:newState];
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:newState]
											 forKey:(sender == menuItem_countAllObjects ?
													 KEY_COUNT_ALL_CONTACTS : 
													 KEY_COUNT_ONLINE_CONTACTS)
											  group:PREF_GROUP_CONTACT_LIST];
    }
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if ((menuItem == menuItem_countOnlineObjects) || (menuItem == menuItem_countAllObjects)) {
		return showingGroups;
	}
	
	return YES;
}

/*
 * Uninstall
 */
- (void)uninstallPlugin
{
    //we are no longer an observer
    [[adium notificationCenter] removeObserver:self];
    [[adium contactController] unregisterListObjectObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

@end
