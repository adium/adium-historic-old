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
#import "AISCLViewPlugin.h"

#import "AIBorderlessListWindowController.h"
#import "AIStandardListWindowController.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIListGroup.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

#define PREF_GROUP_APPEARANCE		@"Appearance"

#define DETACHED_DEFAULT_WINDOW			@"Default Window"
#define DETACHED_WINDOWS				@"Windows"
#define DETACHED_WINDOW_GROUPS			@"Groups"
#define DETACHED_WINDOW_LOCATION		@"Location"

/*!
 * @class AISCLViewPlugin
 * @brief This component plugin is responsible for controlling the main contact list and detached contact lists window and view.
 *
 * Either an AIStandardListWindowController or AIBorderlessListWindowController, each of which is a subclass of AIListWindowController,
 * is instantiated. This window controller, with the help of the plugin, will be responsible for display of an AIListOutlineView.
 * The borderless window controller uses an AIBorderlessListOutlineView.
 *
 * In either case, the outline view itself is controlled by an instance of AIListController.
 *
 * AISCLViewPlugin's class methods also manage ListLayout and ListTheme preference sets. ListLayout sets determine the contents and layout
 * of the contact list; ListTheme sets control the colors used in the contact list.
 */
@implementation AISCLViewPlugin

- (void)installPlugin
{
	// List of windows
	contactLists = [[NSMutableArray alloc] init];
	
    [[adium interfaceController] registerContactListController:self];
	
	//Add View menu item
	menuItem_allowDetach = [[NSMenuItem alloc] initWithTitle:@"Show Detached Groups"
												 target:self
												action:@selector(consolidateContactLists:)
										  keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_allowDetach toLocation:LOC_View_Toggles];
	
	//Context submenu
	contextSubmenu = [[NSMenuItem alloc] initWithTitle:@"Attach/Detach" 
												target:self
												action:@selector(contextMenuAction:)
										 keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:contextSubmenu toLocation:Context_Group_Manage];

	//Control detached groups menu
	[[adium menuController] addMenuItem:[NSMenuItem separatorItem] toLocation:LOC_Window_Commands];
	menuItem_consolidate = [[NSMenuItem alloc] initWithTitle:@"Consolidate Detached Groups"
													  target:self
													  action:@selector(closeDetachedContactLists) 
											   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_consolidate toLocation:LOC_Window_Commands];
	menuItem_nextDetached = [[NSMenuItem alloc] initWithTitle:@"Next Detached Group"
													   target:self
													   action:@selector(nextDetachedContactList) 
												keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_nextDetached toLocation:LOC_Window_Commands];
	menuItem_previousDetached = [[NSMenuItem alloc] initWithTitle:@"Previous Detached Group"
														   target:self
														   action:@selector(previousDetachedContactList) 
													keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_previousDetached toLocation:LOC_Window_Commands];
	
	
	//Observe list closing
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListDidClose:)
									   name:Interface_ContactListDidClose
									 object:nil];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListIsEmpty:)
									   name:DetachedContactListIsEmpty
									 object:nil];
	
	//Now register our other defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_LIST_DEFAULTS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST];										  
											  
	//Observe window style changes 
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_DETACHED_GROUPS];
	
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:KEY_LIST_DETACHABLE,[NSNumber numberWithBool:YES],nil]
											forGroup:PREF_GROUP_CONTACT_LIST];
	
	//Detached state
	hasLoaded = NO;
	detachedCycle = 0;
}

- (void)uninstallPlugin
{
	[contextSubmenu release];
	[contextMenuDetach release];
	[contextMenuAttach release];
	[menuItem_allowDetach release];
	[menuItem_previousDetached release];
	[menuItem_nextDetached release];
	[menuItem_consolidate release];
	
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

//Contact List Windows -------------------------------------------------------------------------------------------------
#pragma mark Contact List Window

/*!
 * @brief Creates a new window with a specified contact list
 *
 * @param contactList contaclist to be used in new contact list window
 *
 * @return Newly created contact list window controller
 */
- (id)detachContactList:(AIListGroup *)contactList 
{
	if ([contactList isKindOfClass:[AIListGroup class]]) { 
		AIListWindowController  *newContactList = [AIBorderlessListWindowController initWithContactList:contactList];
	
		[contactLists addObject:[newContactList retain]];
		[newContactList showWindowInFrontIfAllowed:YES];
		
		return newContactList;
	}
	
	return nil;
}

/*!
 * @brief Closes window specified 
 *
 * @param windowController Controller of window that will be closed (although 
 * this could be used with any contact list window controller, it should only
 * be used with detached contact lists)
 */
- (void)closeContactList:(AIListWindowController *)window
{		
	// Close contact list	
	[[window window] performClose:nil];
}

/*!
 * @brief Closes contact list based on given AIListOutlineView or AIListObject
 *
 * @param notification Notification containing either an AIListOutlineView or 
 * AIListObject object to be used to determin contact list's window. 
 */
- (void)contactListIsEmpty:(NSNotification *)notification
{
	NSEnumerator *i = [contactLists objectEnumerator];
	id object = [notification object];
	AIListWindowController *window;
	
	while ((window = [i nextObject])) {
		if (([object isKindOfClass:[AIListOutlineView class]] && [window contactListView] == object)
			||([object isKindOfClass:[AIListObject class]] && [[window listController] contactList] == object)){
			[self closeContactList:window];
			return;
		}
	}
}

//Contact List Controller ----------------------------------------------------------------------------------------------
#pragma mark Contact List Controller

/*!
 * @brief Retrieve the AIListWindowController in use
 */
- (AIListWindowController *)contactListWindowController {
	return defaultController;
}

/*!
 * @brief Brings main contact list to either front or back
 *
 * @param bringToFront Wether to bring contact list to front of back
 */
- (void)showContactListAndBringToFront:(BOOL)bringToFront
{
	// Check that main contact list has been created
    if (!defaultController) {
		[self loadPreferences];
    }
	
	[defaultController showWindowInFrontIfAllowed:bringToFront];
}

/*!
 * @brief Returns YES if the contact list is visible and in front
 */
- (BOOL)contactListIsVisibleAndMain
{
	// Check that main contact list has been created
	if (!defaultController) {
		[self loadPreferences];
    }
	
	return ([self contactListIsVisible] &&
			[[defaultController window] isMainWindow]);
}

/*!
 * @brief Returns YES if hte contact list is visible
 */
- (BOOL)contactListIsVisible
{
	return (defaultController &&
			[[defaultController window] isVisible] &&
			([defaultController windowSlidOffScreenEdgeMask] == AINoEdges));
}

/*!
 * @brief Close contact list
 */
- (void)closeContactList
{	
	[self savePreferences];

	// Close main window
    if (defaultController)
        [[defaultController window] performClose:nil];
}

/*!
 * @brief Closes all detached contact lists
 */
- (void)closeDetachedContactLists
{
	// Close all other windows
	NSEnumerator *windowEnumerator = [contactLists objectEnumerator];
	AIListWindowController *window;
	while ((window = [windowEnumerator nextObject])) {
		[self closeContactList:window];
	}
}

/*!
 * @brief Callback when the contact list closes, clear our reference to it
 */
- (void)contactListDidClose:(NSNotification *)notification
{
	AIListWindowController *window = [notification object]; 
	
	if (window == defaultController) {
		[defaultController release];
		defaultController = nil;
	} else {
		NSEnumerator *i = [[[window contactList] containedObjects] objectEnumerator];
		AIListGroup *group;
		AIListObject<AIContainingObject> *contactList;
		
		contactList = [[adium contactController] contactList];
		
		while ((group = [i nextObject])){
			[group moveGroupTo:contactList];
		}

		[[adium contactController] removeDetachedContactList:(AIListGroup *)[window contactList]];
		
		[[adium notificationCenter] postNotificationName:@"Contact_ListChanged"
												  object:contactList 
												userInfo:nil];
			
		[contactLists removeObject:window];
		
		[window release];
	}
	
}

//Navigate Through Detached Windows ------------------------------------------------------------------------------------
#pragma mark Navigate Through Detached Windows

/*!
 * @return Returns YES if contact list is allowed to be detached
 */
- (BOOL)allowDetachableContactList {
	return detachable;
}

/*!
 * @retrun Returns the number of detached contact lists
 */
- (unsigned)detachedContactListCount {
	return [contactLists count];
}

/*!
 * @brief Attempts to bring the next detached contact list to the front 
 */
- (void)nextDetachedContactList {
	if (detachedCycle>=[contactLists count] || detachedCycle<0)
		detachedCycle = 0;
	if (detachedCycle>=0 && detachedCycle<[contactLists count])
		[[contactLists objectAtIndex:detachedCycle++] showWindowInFrontIfAllowed:YES];
}

/*!
 * @brief Attempts to bring the previous detached contact list to the front 
 */
- (void)previousDetachedContactList {
	if (detachedCycle<0 || detachedCycle>=[contactLists count])
		detachedCycle = [contactLists count]-1;
	if (detachedCycle>=0 && detachedCycle<[contactLists count])
		[[contactLists objectAtIndex:detachedCycle--] showWindowInFrontIfAllowed:YES];
}

/*!
 * @brief Sets if windows are allowed to be detached. If it is disabled, all 
 * detached groups are consolidated.
 */
- (IBAction)consolidateContactLists:(id)sender{
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!detachable]
										 forKey:KEY_LIST_DETACHABLE 
										  group:PREF_DETACHED_GROUPS];
	if (!detachable) {
		[self savePreferences];
		[self closeDetachedContactLists];
		[[adium notificationCenter] postNotificationName:@"Contact_ListChanged"
												  object:[[adium contactController] contactList]
												userInfo:nil];
		[self showContactListAndBringToFront:YES];
	} else {
		hasLoaded = NO;
		[self loadPreferences];
		[[adium notificationCenter] postNotificationName:@"Contact_ListChanged"
												  object:[[adium contactController] contactList]
												userInfo:nil];
	}
}

//Context menu ---------------------------------------------------------------------------------------------------------
#pragma mark Context menu

/*!
 * @brief Detaches group if not the only group in contact list
 * 
 * @param sender Menu item selected, either to detach or attach group selected
 */
- (IBAction)contextMenuAction:(id)sender{
	AIListGroup		*group;		// Group to be moved
	AIListGroup		*destContactList;		// Possible new contact list that will be created
	AIListGroup		*origContactList;	// Contact list group was in originaly
	
	// If no group is selected then return
	if (!(group = (AIListGroup*)[[adium interfaceController] selectedListObject]))
		return;
	
	// If context menu is clicked do nothing too
	if (sender == contextSubmenu)
		return;
	
	
	origContactList = (AIListGroup *)[group containingObject];
	
	// Determine where to move selected group to
	if (sender == contextMenuDetach) {
		destContactList = [[adium contactController] createDetachedContactList];
		[[[self detachContactList:destContactList] window] setFrameTopLeftPoint:[NSEvent mouseLocation]];
	} else {
		destContactList = [contextMenuAttach objectForKey:[NSValue valueWithPointer:sender]];
	}
	
	[group moveGroupTo:destContactList];
	[[adium notificationCenter] postNotificationName:@"Contact_ListChanged"
														object:destContactList
													  userInfo:nil];
	
	// Update/remove original contact list 
	if (![origContactList containedObjectsCount]) { 
		[[adium notificationCenter] postNotificationName:DetachedContactListIsEmpty
												  object:origContactList
												userInfo:nil];
	} else {
		[[adium notificationCenter] postNotificationName:@"Contact_ListChanged"
												  object:origContactList
												userInfo:nil]; 
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	// If not the main context menu item assume its active
	if (menuItem == menuItem_nextDetached || menuItem == menuItem_previousDetached || menuItem == menuItem_consolidate)
		return ([self detachedContactListCount]!=0);
	else if (menuItem == contextSubmenu)
		return [self rebuildContextMenu];
	return YES;
}

- (BOOL)rebuildContextMenu{	
	AIListObject *listObject = [[adium interfaceController] selectedListObject];
	
	// If no item selected then we can't continue
	if(listObject == nil)
		return NO;
	
	NSMutableDictionary *attachMenu = [[NSMutableDictionary alloc] init];
	
	// Reset submenu
	if (contextSubmenuContent == nil) {
		contextSubmenuContent = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
	} else {
		while ([contextSubmenuContent numberOfItems])
			[contextSubmenuContent removeAllItems];
	}
	
	// Attach-to options
	NSEnumerator *windows = [contactLists objectEnumerator];
	AIListWindowController	*window;
	while ((window = [windows nextObject])) {
		if (![[window contactList] containsObject:listObject]) {	
			NSString *desc = [self formatContextMenu:[window contactList]]; 

			NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] 
											initWithTitle:desc
												   target:self
												   action:@selector(contextMenuAction:)
											keyEquivalent:@""];

			[attachMenu setObject:[window contactList] forKey:[NSValue valueWithPointer:item]];
			
			[contextSubmenuContent addItem:item];
			[item release];
		}
	}
	
	// Attach to main window -- if using the standard window
	NSMenuItem *toMain = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Attach to main window"
																			target:self
																			action:@selector(contextMenuAction:)
																	 keyEquivalent:@""];
	AIListObject<AIContainingObject> *mainContactList = [[adium contactController] contactList];
	[attachMenu setObject:mainContactList
				   forKey:[NSValue valueWithPointer:toMain]];
	// Change depending on window style
	if (windowStyle == AIContactListWindowStyleStandard && [contextSubmenuContent numberOfItems]) {
		[contextSubmenuContent insertItem:[NSMenuItem separatorItem] atIndex:0];
	} else {
		[toMain setTitle:[self formatContextMenu:mainContactList]];
	}
	// Disable if selected group is part of contact list
	if ([mainContactList containsObject:listObject])
		[toMain setAction:nil];
	[contextSubmenuContent insertItem:toMain atIndex:0];
	[toMain release];
	
	
	// Detach option
	if (contextMenuDetach == nil) {
		contextMenuDetach = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
				initWithTitle:@"Detach"
					   target:self
					   action:@selector(contextMenuAction:)
				keyEquivalent:@""];
	}
	[contextSubmenuContent addItem:[NSMenuItem separatorItem]];
	[contextSubmenuContent addItem:contextMenuDetach];

	// Add submenu if not yet added
	if ([contextSubmenu submenu] == nil)
		[contextSubmenu setSubmenu:contextSubmenuContent];
		
	// List of attach locations
	if (contextMenuAttach!=nil)
		[contextMenuAttach release];
	contextMenuAttach = attachMenu;
	
	// Respect if groups can detach
	if (![self allowDetachableContactList])
		return NO;
	else
		return YES;
	
}

- (NSString *)formatContextMenu:(AIListObject<AIContainingObject> *)contactList {
	NSString *description = [self formatContextMenu:contactList showEmpty:NO];
	if (description == nil)
		return [self formatContextMenu:contactList showEmpty:YES];
	return description;
}

- (NSString *)formatContextMenu:(AIListObject<AIContainingObject> *)contactList showEmpty:(BOOL)empty {
	NSArray *groups = [contactList containedObjects];
	NSString *desc = @"";
	
	unsigned count=0;
	for (unsigned i=0;count<3 && i<[groups count]; i++) {
		if ([[groups objectAtIndex:i] visible] || empty) {
			if (count)
				desc = [desc stringByAppendingFormat:@", %@",[[groups objectAtIndex:i] UID]];
			else 
				desc = [desc stringByAppendingFormat:@"Attach to %@",[[groups objectAtIndex:i] UID]];
			count++;
		}
	}
	if (count>2 && [groups count]>3)
		desc = [desc stringByAppendingString:@"..."];
	
	if (!count) 
		return  nil;
	return desc;
	
}

//Themes and Layouts --------------------------------------------------------------------------------------------------
#pragma mark Contact List Controller
//Apply any theme/layout changes
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{	
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		if (firstTime || !key || [key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE]) {
			int	newWindowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
			
			if (newWindowStyle != windowStyle) {
				windowStyle = newWindowStyle;
				
				//If a contact list is visible and the window style has changed, update for the new window style
				if (defaultController) {
					//XXX - Evan: I really do not like this at all.  What to do?
					//We can't close and reopen the contact list from within a preferencesChanged call, as the
					//contact list itself is a preferences observer and will modify the array for its group as it
					//closes... and you can't modify an array while enuemrating it, which the preferencesController is
					//currently doing.  This isn't pretty, but it's the most efficient fix I could come up with.
					//It has the obnoxious side effect of the contact list changing its view prefs and THEN closing and
					//reopening with the right windowStyle.
					[self performSelector:@selector(closeAndReopencontactList)
							   withObject:nil
							   afterDelay:0.00001];
				}
			}
		}
	} else if ([group isEqualToString:PREF_DETACHED_GROUPS]) {
		detachable = [[prefDict objectForKey:KEY_LIST_DETACHABLE] boolValue];
		[menuItem_allowDetach setState:detachable];
	}
}

/*!
 * @brief Closes main contact list and reopens it
 *
 * Useful for updating settings and data of the main contact list
 */
- (void)closeAndReopencontactList
{
	[self savePreferences];
	hasLoaded = NO;
	[self loadPreferences];
}

// Preferences --------------------------------------------------------------------------------------------------------
#pragma mark Preferences
/*!
 * @brief Saves location of contact list and information about the detached groups
 */
- (void)savePreferences
{	
	// Save default contact list location
	[[adium preferenceController] setPreference:[[defaultController window] stringWithSavedFrame] 
										 forKey:DETACHED_DEFAULT_WINDOW
										  group:PREF_DETACHED_GROUPS];
	
	NSMutableArray *windows = [[NSMutableArray alloc] init];
	NSEnumerator *i = [contactLists objectEnumerator];
	AIListWindowController *currWindow;
	while ((currWindow = [i nextObject])) {
		NSMutableDictionary *win = [[NSMutableDictionary alloc] init];
		
		[win setObject:[[currWindow contactList] containedObjectIDs] 
				forKey:DETACHED_WINDOW_GROUPS];
		[win setObject:[[currWindow window] stringWithSavedFrame] 
				forKey:DETACHED_WINDOW_LOCATION];
		
		[windows addObject:win];
		
		[self closeContactList:currWindow];
	}
	
	[[adium preferenceController] setPreference:[NSArray arrayWithArray:windows]
										 forKey:DETACHED_WINDOWS
										  group:PREF_DETACHED_GROUPS];
}

/*!
 * @brief Loads main contact list window if not already loaded and if this 
 * is the first time that that we are loading the contact list we detached
 * groups and place them in the correct location
 */
- (void)loadPreferences
{
	if (!defaultController && windowStyle == AIContactListWindowStyleStandard) {
		defaultController = [[AIStandardListWindowController listWindowController] retain];
	} else if (!defaultController) {
		defaultController = [[AIBorderlessListWindowController listWindowController] retain];
	}
	
	if (!hasLoaded && detachable) {
		[self setWindowLocation:defaultController 
							 at:[[[adium preferenceController] preferencesForGroup:PREF_DETACHED_GROUPS] objectForKey:DETACHED_DEFAULT_WINDOW]];
		
		NSArray *windows = [[[adium preferenceController] preferencesForGroup:PREF_DETACHED_GROUPS] objectForKey:DETACHED_WINDOWS];
		NSEnumerator *window = [windows objectEnumerator];
		NSDictionary *data;
		
		while ((data = [window nextObject])) {
			[self loadWindowPreferences:data];
		}
		
		hasLoaded = YES;
	}

}

/*!
 * @brief Loads detached window based on saved preferences
 */
- (void)loadWindowPreferences:(NSDictionary *)windowPreferences
{
	AIListGroup							*contactList = nil;
	NSString							*ID;
	NSArray								*groups = [windowPreferences objectForKey:DETACHED_WINDOW_GROUPS];
	NSEnumerator						*i = [groups objectEnumerator];
	AIListGroup							*group; 
	

	if (![groups count])
		return;
	
	contactList = [[adium contactController] createDetachedContactList];
	
	while ((ID = [i nextObject])) {
		group = [[adium contactController] groupWithUID:ID];
		[group moveGroupTo:contactList];
	}
	AIListWindowController *window = [self detachContactList:contactList];
	
	[self setWindowLocation:window 
						 at:[windowPreferences objectForKey:DETACHED_WINDOW_LOCATION]];
	
}

/*!
 * @brief Sets window's top left corner position based on saved string
 *
 * @param window Window to be repositioned
 * @param location String containing new window location
 */
- (void)setWindowLocation:(AIListWindowController *)window at:(NSString *)location
{
	NSRect loc = NSRectFromString(location);
	loc.origin.y+=loc.size.height;
	[[window window] setFrameTopLeftPoint:loc.origin];	
}

@end

