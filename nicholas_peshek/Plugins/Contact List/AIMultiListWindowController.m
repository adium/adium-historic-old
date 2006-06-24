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
#import "AIListWindowController.h"
#import "AIStandardListWindowController.h"
#import "AIBorderlessListWindowController.h"

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
		if(!windowControllerArray) {
			windowControllerArray = [[NSMutableArray array] retain];
		}
		
		if (windowStyle == WINDOW_STYLE_STANDARD) {
			[windowControllerArray addObject:[AIStandardListWindowController listWindowControllerWithContactList:nil]];
		} else {
			[windowControllerArray addObject:[AIBorderlessListWindowController listWindowControllerWithContactList:nil]];
		}
		
		if(!mostRecentContactList) {
			mostRecentContactList = [[windowControllerArray objectAtIndex:0] retain];
		}
	}
	return self;
}

//Deallocate the ivars when this instance is getting sent away.
- (void)dealloc
{
	[windowControllerArray release];
	[mostRecentContactList release];
	
	[super dealloc];
}

//Create the new contact list. A bit messy, but overall, it'll work. Returns a boolean saying if it worked or not.
- (BOOL)createNewSeparableContactListWithObject:(AIListObject<AIContainingObject> *)newListObject
{
	BOOL					didCreationWork = NO;
	
	if ([newListObject isKindOfClass:[AIListGroup class]]) {
		AIListWindowController	*newContactList = [AIBorderlessListWindowController listWindowControllerWithContactList:newListObject];
		mostRecentContactList = newContactList;
		[windowControllerArray addObject:newContactList];
		[self showWindowInFront:YES];
		didCreationWork = YES;
	}
	return didCreationWork;
}

//Returns the most recently clicked on contact list (Therefore, the one that should have focus and key).
- (AIListWindowController *)mostRecentContactList
{
	return mostRecentContactList;
}

//A bridging method so that you can show the contact lists. May need changing later on, based on if the event to "show contact list" calls this.
- (void)showWindowInFront:(BOOL)inFront
{
	NSEnumerator			*e = [windowControllerArray objectEnumerator];
	AIListWindowController	*windowController;
	
	while ((windowController = [e nextObject])) {
		[windowController showWindowInFront:inFront];
	}
}

//A bridging method so that you can see if the key contact list has focus and such.
- (NSWindow *)window
{
	return [[self mostRecentContactList] window];
}

//A bridging method to close all the contact lists right off the bat. Could be rwardy.
- (void)performClose
{
	NSEnumerator			*enumer = [windowControllerArray objectEnumerator];
	AIListWindowController	*windowController;
	
	while ((windowController = [enumer nextObject])) {
		[[windowController window] performClose:nil];
	}
}

//A beidging method so that you can see if the key contact list is off screen.
- (AIRectEdgeMask)windowSlidOffScreenEdgeMask
{
	return [[self mostRecentContactList] windowSlidOffScreenEdgeMask];
}
@end
