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

#import "AIMultiListWindowController.h"
#import "AIContactList.h"
#import "AIListWindowController.h"
#import "AIListGroup.h"
#import "AIInterfaceController.h"
#import <AIUtilities/AIWindowAdditions.h>

#define PREF_GROUP_MULTI_CONTACT_LIST			@"Contact List Windows"

@implementation AIMultiListWindowController

//Initialize this class and create a new Contact List.
+ (AIMultiListWindowController *)initialize:(LIST_WINDOW_STYLE)windowStyle
{
	return [[[self alloc] createWindows:windowStyle] autorelease];
}

//Create the initial contact list
#warning kbotc: Check here and load up the separate contact lists when you get around to creating them.
- (AIMultiListWindowController *)createWindows:(LIST_WINDOW_STYLE)windowStyle
{
	if ((self = [self init])) {
		style = windowStyle;
		if(!contactListArray) {
			contactListArray = [[[NSMutableArray array] retain] autorelease];
		}
		
		NSArray			*loadedList = [NSArray array];
		NSMutableArray	*loadedContactLists = [[adium preferenceController] preferenceForKey:@"SavedContactLists"
																					   group:PREF_GROUP_MULTI_CONTACT_LIST];
		NSMutableArray	*listToCheckAgainst = [NSMutableArray array];
#warning kbotc: read comments
		//You really should not do this check here, and compare the total number of lists you get to the ones loaded from the contact list, and throw the remaining groups in another contact list.
		//This check may not be needed, I may toss it soon.
		if (loadedContactLists == nil) {
			NSMutableArray	*tempArray = [NSMutableArray array];
			NSMutableArray	*groups = [NSMutableArray array];
			NSEnumerator	*containedGroups = [[[[adium contactController] contactList] containedObjects] objectEnumerator];
			AIListObject	*object;
			while ((object = [containedGroups nextObject])) {
				[groups addObject:[object UID]];
			}
			
			[tempArray addObject:groups];
			loadedContactLists = tempArray;
		}
		
		NSEnumerator	*e = [loadedContactLists objectEnumerator];
		int				indexVar = 0;
		
		while ((loadedList = [e nextObject])) {
			AIListGroup		*newRootObject = [[AIListGroup alloc] initWithUID:[NSString stringWithFormat:@"%d", indexVar]];
			NSString		*UID;
			NSEnumerator	*smallList = [loadedList objectEnumerator];
			while ((UID = [smallList nextObject])) {
				AIListGroup	*newGroup = [[adium contactController] existingGroupWithUID:UID];
				
				[newRootObject addObject:newGroup];
				[listToCheckAgainst addObject:newGroup];
			}
			if(indexVar == 0)
				[self createNewSeparableContactListWithObject:(AIListGroup *)newRootObject withStyle:windowStyle];
			else
				[self createNewSeparableContactListWithObject:(AIListGroup *)newRootObject];
			
			indexVar++;
		}
		
		NSMutableArray	*fullContactList = [[[[[adium contactController] contactList] containedObjects] mutableCopy] autorelease];
		NSEnumerator	*loadedLists = [listToCheckAgainst objectEnumerator];
		
		AIListObject	*listObject;
		
		while ((listObject = [loadedLists nextObject])) {
			if([fullContactList indexOfObjectIdenticalTo:listObject] != NSNotFound) {
				[fullContactList removeObjectIdenticalTo:listObject];
			}
		}
		
		if([fullContactList count] > 0) {
			AIListGroup		*newRootObject = [[AIListGroup alloc] initWithUID:[NSString stringWithFormat:@"%d", indexVar]];
			AIListGroup		*forgottenGroup;
			NSEnumerator	*smallList = [fullContactList objectEnumerator];
			while ((forgottenGroup = [smallList nextObject])) {
				[newRootObject addObject:forgottenGroup];
			}
			[self createNewSeparableContactListWithObject:(AIListGroup *)newRootObject];
		}
		
		if(!mostRecentContactList) {
			mostRecentContactList = [contactListArray objectAtIndex:0];
		}
		
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(terminate:) 
										   name:Adium_WillTerminate
										 object:nil];
		
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(contactListAdded:) 
										   name:Contact_ListChanged
										 object:nil];
	}
	return self;
}

//Create the new contact list. A bit messy, but overall, it'll work. Returns a boolean saying if it worked or not.
- (BOOL)createNewSeparableContactListWithObject:(AIListObject<AIContainingObject> *)newListObject
{
	if(style == WINDOW_STYLE_STANDARD)
		return [self createNewSeparableContactListWithObject:newListObject withStyle:WINDOW_STYLE_BORDERLESS];
	else
		return [self createNewSeparableContactListWithObject:newListObject withStyle:style];
}

- (BOOL)createNewSeparableContactListWithObject:(AIListObject<AIContainingObject> *)newListObject withStyle:(LIST_WINDOW_STYLE)windowStyle
{
	BOOL	didCreationWork = NO;
	
	if ([newListObject isKindOfClass:[AIListGroup class]]) {
		AIContactList	*newContactList = [AIContactList createWithStyle:windowStyle];
		[newContactList setContactListRoot:newListObject];
		mostRecentContactList = newContactList;
		[contactListArray addObject:newContactList];
		[[newContactList listWindowController] setMaster:newContactList];
		[[newContactList listWindowController] showWindowInFront:YES];
		didCreationWork = YES;
	}
	
	return didCreationWork;
}

- (void)terminate:(NSNotification *)aNotification
{
	[self saveContactLists];
}

//Deallocate the ivars when this instance is getting sent away.
- (void)dealloc
{
	[self saveContactLists];
	[contactListArray release];
	[mostRecentContactList release];
	
	[super dealloc];
}

//Loop inside loop. Icky, but hopefully this will not need to be run that often.
- (void)saveContactLists
{
	NSMutableArray	*savedLists = [NSMutableArray array];
	NSEnumerator	*contactLists;
	AIContactList	*list;
	
	contactLists = [contactListArray objectEnumerator];
	
	while ((list = [contactLists nextObject])) {
		NSMutableArray	*groups = [NSMutableArray array];
		NSEnumerator	*containedGroups = [[[[list listController] contactListRoot] containedObjects] objectEnumerator];
		AIListObject	*object;
		while ((object = [containedGroups nextObject])) {
			[groups addObject:[object UID]];
		}
		[savedLists addObject:groups];
	}
	
	[[adium preferenceController] setPreference:savedLists
										 forKey:@"SavedContactLists"
										  group:PREF_GROUP_MULTI_CONTACT_LIST];
}


- (void)destroyListController:(AIContactList *)doneController
{
	[[doneController listWindowController] close:nil];
	if ([contactListArray count] > 1) {
		mostRecentContactList = [self nextContactList];
		[contactListArray removeObjectIdenticalTo:doneController];
	} else {
		[contactListArray removeObjectIdenticalTo:doneController];
		//I don't know how you got here, but hey, lets just be on the safe side and kill the list controller.
		AILog(@"Last Contact List Window Destroyed. Destroy the controller.");
#warning kbotc: Get the Notification name here. Even if this is just safety, get on it.
		//[[adium notificationCenter] postNotificationName:Interface_ContactListDidClose object:self];
	}
}

//Returns the most recently clicked on contact list (Therefore, the one that should have focus and key).
- (AIContactList *)mostRecentContactList
{
	return mostRecentContactList;
}

//A bridging method so that you can show the contact lists. May need changing later on, based on if the event to "show contact list" calls this.
- (void)showWindowInFront:(BOOL)inFront
{
//	[self selector:@selector(showWindowInFront:) withArgument:[NSNumber numberWithBool:inFront] toItem:CONTACT_LIST_WINDOW_CONTROLLER on:EVERY];
	NSEnumerator			*e = [contactListArray objectEnumerator];
	AIContactList			*contactList;
	
	while ((contactList = [e nextObject])) {
		[[contactList listWindowController] showWindowInFront:inFront];
	}
}

- (void)contactListAdded:(NSNotification *)contactChanged
{
	if((AIListGroup *)[contactChanged userInfo] == [[adium contactController] contactList] && [[contactChanged object] isKindOfClass:[AIListGroup class]]) {
		[[self mostRecentContactList] addContactListObject:[contactChanged object]];
	}
}

//Show the next window
- (void)showNextWindowInFront
{
	AIContactList	*tempList = [self mostRecentContactList];
	AIContactList	*listToChangeTo = [self nextContactList];
	if(tempList == listToChangeTo) {
		[[[self mostRecentContactList] listWindowController] showWindowInFront:NO];
	} else {
		BOOL allAreHidden = NO;
		//Check if the root object is visible, if not, ignore the window and go to the next one.
		while(![[listToChangeTo contactList] visible] && !allAreHidden) {
			mostRecentContactList = listToChangeTo;
			listToChangeTo = [self nextContactList];
			if(tempList == listToChangeTo)
				allAreHidden = YES;
		}
		[[listToChangeTo listWindowController] showWindowInFront:YES];
		mostRecentContactList = listToChangeTo;
	}
}

- (BOOL)isVisible
{
	NSEnumerator			*e = [contactListArray objectEnumerator];
	AIContactList			*contactList;
	BOOL					returnVal = NO;
	
	while ((contactList = [e nextObject])) {
		if([[[contactList listWindowController] window] isVisible])
			returnVal = YES;
	}
	
	return returnVal;
}

- (void)setStyle:(LIST_WINDOW_STYLE)windowStyle
{
	if(windowStyle != style) {
		style = windowStyle;
	}
}

- (BOOL)isMainWindow
{
	NSEnumerator			*e = [contactListArray objectEnumerator];
	AIContactList			*contactList;
	BOOL					returnVal = NO;
	
	while ((contactList = [e nextObject])) {
		if([[[contactList listWindowController] window] isMainWindow])
			returnVal = YES;
	}
	
	return returnVal;
}

- (BOOL)isNotSlidOffScreen
{
	NSEnumerator			*e = [contactListArray objectEnumerator];
	AIContactList			*contactList;
	BOOL					returnVal = NO;
	
	while ((contactList = [e nextObject])) {
		if([[contactList listWindowController] windowSlidOffScreenEdgeMask] == AINoEdges)
			returnVal = YES;
	}
	
	return returnVal;
}

//A bridging method so that you can see if the key contact list has focus and such.
- (NSWindow *)window
{
	return [[[self mostRecentContactList] listWindowController] window];
}

//A bridging method to close all the contact lists right off the bat. Could be rwardy.
- (void)performClose
{
	[self selector:@selector(performClose:) withArgument:nil toItem:CONTACT_LIST_WINDOW on:EVERY];
}

//A bridging method so that you can see if the key contact list is off screen.
- (AIRectEdgeMask)windowSlidOffScreenEdgeMask
{
	return [[[self mostRecentContactList] listWindowController] windowSlidOffScreenEdgeMask];
}

- (AIContactList *)nextContactList
{
	AIContactList	*nextList;
	unsigned		mostRecentContactListIndex = [contactListArray indexOfObject:mostRecentContactList];
	
	//Check if there is another contact list to switch to
	if (([contactListArray count] > 1)) {
		//Check if the current focused contact list is the last object if the array, and if it is, set the focus to the first list.
		if (mostRecentContactListIndex == ([contactListArray count] - 1)) {
			nextList = [contactListArray objectAtIndex:0];
		} else {
			nextList = [contactListArray objectAtIndex:(mostRecentContactListIndex + 1)];
		}
	} else {
		nextList = mostRecentContactList;
	}
	
	return nextList;
}

- (AIContactList *)contactListWithContact:(AIListObject *)object
{
	NSEnumerator			*e = [contactListArray objectEnumerator];
	AIContactList			*contactList;
	AIContactList			*returnVal = nil;
	
	while ((contactList = [e nextObject])) {
		AIListGroup	*listObject;
		
		NSEnumerator	*contactEnumerator = [[[[[contactList contactList] containedObjects] copy] autorelease] objectEnumerator];
		
		while ((listObject = (AIListGroup *)[contactEnumerator nextObject])) {
			if([listObject containsObject:object] || [listObject isEqual:object])
				returnVal = contactList;
		}
	}
	return returnVal;
}

- (void)selector:(SEL)aSelector withArgument:(id)argument toItem:(CONTACT_LIST_ITEM)item on:(LISTS)lists
{
	switch(lists)
	{
		case EVERY: {
			NSEnumerator	*enumer = [contactListArray objectEnumerator];
			AIContactList	*contactList;
			
			while ((contactList = [enumer nextObject])) {
				[contactList selector:aSelector withArgument:argument toItem:item];
			}
			break;
		} 
		case FRONT: {
			[mostRecentContactList selector:aSelector withArgument:argument toItem:item];
			break;
		}
		case NONFRONT: {
			NSEnumerator	*enumer = [contactListArray objectEnumerator];
			AIContactList	*contactList;
			
			while ((contactList = [enumer nextObject])) {
				if (![contactList isEqual:mostRecentContactList])
					[contactList selector:aSelector withArgument:argument toItem:item];
			}
			break;
		}
		default: break;
	}
}
@end
