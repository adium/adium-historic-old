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
#import "AIContactListEditorPlugin.h"
#import "AIMenuController.h"
#import "AINewContactWindowController.h"
#import "AINewGroupWindowController.h"
#import "AIToolbarController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>

#define ADD_CONTACT					AILocalizedString(@"Add Contact",nil)
#define ADD_CONTACT_ELLIPSIS   		[ADD_CONTACT stringByAppendingString:[NSString stringWithUTF8String:"É"]]

#define ADD_CONTACT_TO_GROUP		AILocalizedString(@"Add Contact To Group",nil)
#define ADD_CONTACT_TO_GROUP_ELLIPSIS	[ADD_CONTACT_TO_GROUP stringByAppendingString:[NSString stringWithUTF8String:"É"]]

#define ADD_GROUP   				AILocalizedString(@"Add Group",nil)
#define ADD_GROUP_ELLIPSIS			[ADD_GROUP stringByAppendingString:[NSString stringWithUTF8String:"É"]]

#define DELETE_CONTACT   			AILocalizedString(@"Delete Selection",nil)
#define DELETE_CONTACT_CONTEXT		AILocalizedString(@"Delete",nil)

#define RENAME_GROUP				AILocalizedString(@"Rename Group",nil)
#define RENAME_GROUP_ELLIPSIS		[RENAME_GROUP stringByAppendingString:[NSString stringWithUTF8String:"É"]]

#define INVITE_CONTACT				AILocalizedString(@"Invite to This Chat...",nil)

#define	ADD_CONTACT_IDENTIFIER		@"AddContact"
#define ADD_GROUP_IDENTIFIER		@"AddGroup"

@interface AIContactListEditorPlugin (PRIVATE)
- (void)deleteFromArray:(NSArray *)array;
- (void)promptForNewContactOnWindow:(NSWindow *)inWindow strangerListContact:(AIListContact *)inListContact;
@end

/*!
 * @class AIContactListEditorPlugin
 * @brief Component for managing adding and deleting contacts and groups
 */
@implementation AIContactListEditorPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    NSMenuItem		*menuItem;
	NSToolbarItem	*toolbarItem;
	
	//Add contact menu item
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT_ELLIPSIS
																	 target:self
																	 action:@selector(addContact:)
															  keyEquivalent:@"+"] autorelease];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Contact_Editing];
	
	//Add contact context menu item
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT_TO_GROUP_ELLIPSIS
																	 target:self
																	 action:@selector(addContact:)
															  keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Group_Manage];
	
	//Add contact context menu item for tabs
	menuItem_tabAddContact = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT_ELLIPSIS
																				   target:self 
																				   action:@selector(addContactFromTab:)
																			keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:menuItem_tabAddContact toLocation:Context_Contact_Stranger_TabAction];
	
	//Add group menu item
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_GROUP_ELLIPSIS
																	 target:self
																	 action:@selector(addGroup:) 
															  keyEquivalent:@"+"] autorelease];
	[menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Contact_Editing];
	
	//Delete selection menu item
    menuItem_delete = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:DELETE_CONTACT
																		   target:self
																		   action:@selector(deleteSelection:) 
																	keyEquivalent:@"\b"];
    [[adium menuController] addMenuItem:menuItem_delete toLocation:LOC_Contact_Editing];
	
	//Rename group context menu item
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:RENAME_GROUP_ELLIPSIS
																	 target:self
																	 action:@selector(renameGroup:) 
															  keyEquivalent:@""] autorelease];
    //[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Group_Manage];
	
	//Delete selection context menu item
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:DELETE_CONTACT_CONTEXT_ELLIPSIS
																	 target:self
																	 action:@selector(deleteSelectionFromTab:) 
															  keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Contact_NegativeAction];
	
	//Add Contact toolbar item
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:ADD_CONTACT_IDENTIFIER
														  label:ADD_CONTACT
												   paletteLabel:ADD_CONTACT
														toolTip:AILocalizedString(@"Add a new contact",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"AddContact" forClass:[self class]]
														 action:@selector(addContact:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];	
	
	//Add Contact toolbar item
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:ADD_GROUP_IDENTIFIER
														  label:ADD_GROUP
												   paletteLabel:ADD_GROUP
														toolTip:AILocalizedString(@"Add a new group",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"AddGroup" forClass:[self class]]
														 action:@selector(addGroup:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ContactList"];	
	
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(addContactRequest:) 
									   name:Contact_AddNewContact 
									 object:nil];
	
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
    [[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief Validate our menu items
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	//Disable 'delete selection' if nothing is selected or the contact list isn't in front
	if(menuItem == menuItem_delete){
		//return([[adium contactController] selectedListObjectInContactList] != nil);
                //Update the menu titles to reflect the selected contact
            if([[adium contactController] selectedListObjectInContactList] != nil){
                [menuItem_delete setTitle:[NSString stringWithFormat:
					AILocalizedString(@"Delete %@","%@ will be a contact's name"),
					[[[adium contactController] selectedListObjectInContactList] displayName]]];
            }else{
                [menuItem_delete setTitle:DELETE_CONTACT];
                return NO;
            }
	}else if(menuItem == menuItem_tabAddContact){
		return([[adium menuController] currentContextMenuObject] != nil);
	}
	
	return(YES);
}

/*!
 * @brief Prompt for a new contact
 */
- (IBAction)addContact:(id)sender
{
	//Get the "selected" list object (contact list or message window)
	AIListContact	*stranger = nil;
	AIListObject	*selectedObject;
	
	selectedObject = [[adium contactController] selectedListObject];	
	
	//Pass this selectedObject only if it's a listContact and a stranger
	if ([selectedObject isKindOfClass:[AIListContact class]] &&
		[(AIListContact *)selectedObject isStranger]){
		stranger = (AIListContact *)selectedObject;
	}
	
	[self promptForNewContactOnWindow:nil
				  strangerListContact:stranger];
}

/*!
 * @brief Prompt for a new contact with the current tab's name
 */
- (IBAction)addContactFromTab:(id)sender
{
	AIListObject *object = [[adium menuController] currentContextMenuObject];
	if([object isKindOfClass:[AIListContact class]]){
		[self promptForNewContactOnWindow:nil
					  strangerListContact:(AIListContact *)object];
	}
}

/*!
 * @brief Prompt for a new contact
 *
 * @param inWindow If non-nil, display the new contact prompt as a sheet on inWindow
 * @param inListContact If non-nil, autofill the new contact prompt with information from inListContact
 */
- (void)promptForNewContactOnWindow:(NSWindow *)inWindow strangerListContact:(AIListContact *)inListContact
{
	[AINewContactWindowController promptForNewContactOnWindow:inWindow
														 name:(inListContact ? [inListContact UID] : nil)
													  service:(inListContact ? [inListContact service] : nil)];
}

/*!
 * @brief Add contact request notification
 *
 * Display the add contact window.  Triggered by an incoming Contact_AddNewContact notification 
 * @param notification Notification with a userInfo containing @"UID" and @"Service" keys
 */
- (void)addContactRequest:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	if (userInfo){
		[AINewContactWindowController promptForNewContactOnWindow:nil
															 name:[userInfo objectForKey:@"UID"]
														  service:[userInfo objectForKey:@"service"]];
	}
}

/*!
 * @brief Prompt for a new group
 */
- (IBAction)addGroup:(id)sender
{
	[AINewGroupWindowController promptForNewGroupOnWindow:nil];
}

/*!
 * @brief Delete the list objects selected in the contact list
 */
- (IBAction)deleteSelection:(id)sender
{	
	NSArray			*array = [[adium contactController] arrayOfSelectedListObjectsInContactList];
	[self deleteFromArray:array];
}

/*!
 * @brief Delete the list object associated with the current context menu
 */
- (IBAction)deleteSelectionFromTab:(id)sender
{
	AIListObject   *currentContextMenuObject;
	if (currentContextMenuObject = [[adium menuController] currentContextMenuObject]){
		[NSApp activateIgnoringOtherApps:YES];
		[self deleteFromArray:[NSArray arrayWithObject:currentContextMenuObject]];
	}
}

/*!
 * @brief Delete an array of <tt>AIListObject</tt>s
 *
 * After a modal confirmation prompt, the objects in the array are deleted.
 *
 * @param array An <tt>NSArray</tt> of <tt>AIListObject</tt>s.
 */
- (void)deleteFromArray:(NSArray *)array
{
	if(array){
		int count = [array count];
		
		NSString	*name = ((count == 1) ?
							 [[array objectAtIndex:0] displayName] : 
							 [NSString stringWithFormat:AILocalizedString(@"%i contacts",nil),count]);
		
		//Guard deletion with a warning prompt
		int result = NSRunAlertPanel([NSString stringWithFormat:AILocalizedString(@"Remove %@ from your list?",nil),name],
									 AILocalizedString(@"Be careful. You cannot undo this action.",nil),
									 AILocalizedString(@"OK",nil),
									 AILocalizedString(@"Cancel",nil),
									 nil);

		if(result == NSAlertDefaultReturn){
			[[adium contactController] removeListObjects:array];
		}
	}	
}


//Called by a context menu
- (IBAction)renameGroup:(id)sender
{
//	AIListObject	*object = [[adium menuController] currentContextMenuObject];
	
}

@end
