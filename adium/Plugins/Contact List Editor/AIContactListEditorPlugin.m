/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIContactListEditorPlugin.h"
#import "AINewContactWindowController.h"
#import "AINewGroupWindowController.h"

#define ADD_CONTACT   				AILocalizedString(@"Add Contact...",nil)
#define ADD_CONTACT_TO_GROUP		AILocalizedString(@"Add Contact To Group...",nil)
#define ADD_GROUP   				AILocalizedString(@"Add Group...",nil)
#define DELETE_CONTACT   			AILocalizedString(@"Delete Selection",nil)
#define DELETE_CONTACT_CONTEXT		AILocalizedString(@"Delete",nil)
#define RENAME_GROUP				AILocalizedString(@"Rename Group...",nil)

@implementation AIContactListEditorPlugin

//Install
- (void)installPlugin
{
    NSMenuItem		*menuItem;
    
	//Add contact menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADD_CONTACT
										   target:self
										   action:@selector(addContact:)
									keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Contact_Editing];
	
	//Add contact context menu item
	menuItem = [[[NSMenuItem alloc] initWithTitle:ADD_CONTACT_TO_GROUP
										   target:self
										   action:@selector(addContact:)
									keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Group_Manage];

	//Add contact context menu item for tabs
	menuItem_tabAddContact = [[[NSMenuItem alloc] initWithTitle:ADD_CONTACT
														 target:self 
														 action:@selector(addContactFromTab:)
												  keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:menuItem_tabAddContact toLocation:Context_Contact_TabAction];
	
	//Add group menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADD_GROUP
										   target:self
										   action:@selector(addGroup:) 
									keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Contact_Editing];
	
	//Delete selection menu item
    menuItem_delete = [[NSMenuItem alloc] initWithTitle:DELETE_CONTACT target:self action:@selector(deleteSelection:) keyEquivalent:@"\b"];
    [[adium menuController] addMenuItem:menuItem_delete toLocation:LOC_Contact_Editing];
	
	//Rename group context menu item
	menuItem = [[[NSMenuItem alloc] initWithTitle:RENAME_GROUP target:self action:@selector(renameGroup:) keyEquivalent:@""] autorelease];
    //[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Group_Manage];

	//Delete selection context menu item
	menuItem = [[[NSMenuItem alloc] initWithTitle:DELETE_CONTACT_CONTEXT target:self action:@selector(deleteSelection:) keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Contact_Manage];
    
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(addContactRequest:) 
									   name:Contact_AddNewContact 
									 object:nil];

}

//Uninstall
- (void)uninstallPlugin
{
    [[adium notificationCenter] removeObserver:self];
}

//Validate our menu items
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	//Disable 'delete selection' if nothing is selected or the contact list isn't in front
	if(menuItem == menuItem_delete){
		return([[adium contactController] selectedListObjectInContactList] != nil);
	} else if(menuItem == menuItem_tabAddContact) {
		AIListObject	*selectedObject = [[adium menuController] contactualMenuContact];
		
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
			NSString *containingGroupUID = [[selectedObject containingGroup] UID];
			return( ([containingGroupUID isEqualToString:@"Orphans"]) ||
					([containingGroupUID isEqualToString:@"__Strangers"]) );
		}
		
	}
	
	return(YES);
}

//Prompt for a new contact
- (IBAction)addContact:(id)sender
{
	[AINewContactWindowController promptForNewContactOnWindow:nil name:nil serviceID:nil];
}

//Prompt for a new contact with the current tab's name
- (IBAction)addContactFromTab:(id)sender
{
	AIListContact *listContact = [[adium menuController] contactualMenuContact];
	[AINewContactWindowController promptForNewContactOnWindow:nil
														 name:[listContact UID] 
													serviceID:[listContact serviceID]];
}

- (void)addContactRequest:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	if (userInfo){
		[AINewContactWindowController promptForNewContactOnWindow:nil
															 name:[userInfo objectForKey:@"UID"]
														serviceID:[userInfo objectForKey:@"serviceID"]];
	}
}

//Prompt for a new group
- (IBAction)addGroup:(id)sender
{
	[AINewGroupWindowController promptForNewGroupOnWindow:nil];
}

//Delete the selection
- (IBAction)deleteSelection:(id)sender
{	
	NSArray			*array = [[adium contactController] arrayOfSelectedListObjectsInContactList];
	if(array){
		int count = [array count];
		
		NSString	*name = ((count == 1) ? [[array objectAtIndex:0] displayName] : [NSString stringWithFormat:@"%i contacts",count]);
		
		//Guard deletion with a warning prompt
		int result = NSRunAlertPanel([NSString stringWithFormat:@"Remove %@ from your list?",name],
									 @"Be careful, you cannot undo this action.",
									 @"OK",
									 @"Cancel",
									 nil);
		
		if(result == NSAlertDefaultReturn){
			[[adium contactController] removeListObjects:array];
		}
	}
}

//Called by a context menu
- (IBAction)renameGroup:(id)sender
{
//	AIListObject	*object = [[adium menuController] contactualMenuContact];
	
}

@end
