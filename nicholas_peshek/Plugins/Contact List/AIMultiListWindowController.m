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
//#import "AIStandardListWindowController.h"
//#import "AIBorderlessListWindowController.h"
//#import "AIContactListOutlineView.h"

@implementation AIMultiListWindowController

//Initialize this class and create a new Contact List.
+ (AIMultiListWindowController *)initialize:(LIST_WINDOW_STYLE)windowStyle
{
	return [[self alloc] createWindows:windowStyle];
}

//Create the initial contact list
#warning kbotc: Check here and load up the separate contact lists when you get around to creating them.
- (AIMultiListWindowController *)createWindows:(LIST_WINDOW_STYLE)windowStyle
{
	if ((self = [self init])) {
		if(!contactListArray) {
			contactListArray = [[NSMutableArray array] retain];
		}
		AIContactList	*newList = [AIContactList createWithStyle:windowStyle];
		[newList setContactListRoot:(AIListObject *)[[adium contactController] contactList]];
		
		[contactListArray addObject:newList];
		
		if(!mostRecentContactList) {
			mostRecentContactList = [contactListArray objectAtIndex:0];
		}
	}
	return self;
}

//Create the new contact list. A bit messy, but overall, it'll work. Returns a boolean saying if it worked or not.
- (BOOL)createNewSeparableContactListWithObject:(AIListObject<AIContainingObject> *)newListObject
{
	BOOL	didCreationWork = NO;
	if ([newListObject isKindOfClass:[AIListGroup class]]) {
		AIContactList	*newContactList = [AIContactList createWithStyle:WINDOW_STYLE_BORDERLESS];
		[newContactList setContactListRoot:newListObject];
		mostRecentContactList = newContactList;
		[contactListArray addObject:newContactList];
		[[newContactList listWindowController] showWindowInFront:YES];
		didCreationWork = YES;
	}
	
	return didCreationWork;
}

//Deallocate the ivars when this instance is getting sent away.
- (void)dealloc
{
	[contactListArray release];
	[mostRecentContactList release];
	
	[super dealloc];
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

- (void)showNextWindowInFront
{
	AIContactList	*tempList = [self mostRecentContactList];
	AIContactList	*listToChangeTo = [self nextContactList];
	if(tempList == listToChangeTo) {
		[[[self mostRecentContactList] listWindowController] showWindowInFront:NO];
	} else {
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
