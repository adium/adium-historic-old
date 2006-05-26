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

#import "ESChatUserListController.h"
#import "AIMenuController.h"
#import "AIMessageTabViewItem.h"

@implementation ESChatUserListController

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[[self delegate] performSelector:@selector(outlineViewSelectionDidChange:)
						  withObject:notification];
}

//We don't want to change text colors based on the user's status or state
- (BOOL)shouldUseContactTextColors{
	return NO;
}

/*
 * @brief Return the contextual menu for a passed list object
 *
 * Assumption: Our delegate is an AIMessageTabViewItem (which responds to chat)
 */
- (NSMenu *)contextualMenuForListObject:(AIListObject *)listObject
{
	NSArray			*locationsArray = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:Context_Contact_GroupChatAction],		
		[NSNumber numberWithInt:Context_Contact_Manage],
		[NSNumber numberWithInt:Context_Contact_Action],
		[NSNumber numberWithInt:Context_Contact_ListAction],
		[NSNumber numberWithInt:Context_Contact_NegativeAction],
		[NSNumber numberWithInt:Context_Contact_Additions], nil];
	
    return [[adium menuController] contextualMenuWithLocations:locationsArray
												 forListObject:listObject
														inChat:[[self delegate] chat]];
}
@end
