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

#define ADD_CONTACT   				AILocalizedString(@"Add Contact...",nil)
#define ADD_CONTACT_TO_GROUP		AILocalizedString(@"Add Contact To Group...",nil)
#define ADD_GROUP   				AILocalizedString(@"Add Group...",nil)
#define DELETE_CONTACT   			AILocalizedString(@"Delete Selection",nil)
#define DELETE_CONTACT_CONTEXT		AILocalizedString(@"Delete",nil)
#define RENAME_GROUP				AILocalizedString(@"Rename Group...",nil)
#define INVITE_CONTACT				AILocalizedString(@"Invite to This Chat...",nil)

#define	ADD_CONTACT_IDENTIFIER		@"AddContact"
#define ADD_GROUP_IDENTIFIER		@"AddGroup"

@interface AIContactListEditorPlugin (PRIVATE)
- (void)deleteFromArray:(NSArray *)array;
- (void)promptForNewContactOnWindow:(NSWindow *)inWindow strangerListContact:(AIListContact *)inListContact;
@end

@implementation AIContactListEditorPlugin

//Install
- (void)installPlugin
{
    NSMenuItem		*menuItem;
	NSToolbarItem	*toolbarItem;
	
	//Add contact menu item
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT
																	 target:self
																	 action:@selector(addContact:)
															  keyEquivalent:@"+"] autorelease];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Contact_Editing];
	
	//Add contact context menu item
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT_TO_GROUP
																	 target:self
																	 action:@selector(addContact:)
															  keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Group_Manage];
	
	//Add contact context menu item for tabs
	menuItem_tabAddContact = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT
																				   target:self 
																				   action:@selector(addContactFromTab:)
																			keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:menuItem_tabAddContact toLocation:Context_Contact_Stranger_TabAction];
	
	//Add group menu item
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_GROUP
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
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:RENAME_GROUP
																	 target:self
																	 action:@selector(renameGroup:) 
															  keyEquivalent:@""] autorelease];
    //[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Group_Manage];
	
	//Delete selection context menu item
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:DELETE_CONTACT_CONTEXT
																	 target:self
																	 action:@selector(deleteSelectionFromTab:) 
															  keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem toLocation:Context_Contact_NegativeAction];
	
	//Add Contact toolbar item
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:ADD_CONTACT_IDENTIFIER
														  label:AILocalizedString(@"Add Contact",nil)
												   paletteLabel:AILocalizedString(@"Add Contact",nil)
														toolTip:AILocalizedString(@"Add a new contact",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"AddContact" forClass:[self class]]
														 action:@selector(addContact:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];	
	
	//Add Contact toolbar item
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:ADD_GROUP_IDENTIFIER
														  label:AILocalizedString(@"Add Group",nil)
												   paletteLabel:AILocalizedString(@"Add Group",nil)
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
		//return([[adium contactController] selectedListObjectInContactList] != nil);
                //Update the menu titles to reflect the selected contact
            if([[adium contactController] selectedListObjectInContactList] != nil){
                [menuItem_delete setTitle:[NSString stringWithFormat:@"Delete %@",[[[adium contactController] selectedListObjectInContactList] displayName]]];
            }else{
                [menuItem_delete setTitle:@"Delete Selection"];
                return NO;
            }
	}else if(menuItem == menuItem_tabAddContact){
		return([[adium menuController] contactualMenuObject] != nil);
	}
	
	return(YES);
}

//Prompt for a new contact
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

//Prompt for a new contact with the current tab's name
- (IBAction)addContactFromTab:(id)sender
{
	AIListObject *object = [[adium menuController] contactualMenuObject];
	if([object isKindOfClass:[AIListContact class]]){
		[self promptForNewContactOnWindow:nil
					  strangerListContact:(AIListContact *)object];
	}
}

- (void)promptForNewContactOnWindow:(NSWindow *)inWindow strangerListContact:(AIListContact *)inListContact
{
	[AINewContactWindowController promptForNewContactOnWindow:inWindow
														 name:(inListContact ? [inListContact UID] : nil)
													  service:(inListContact ? [inListContact service] : nil)];
}

- (void)addContactRequest:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	if (userInfo){
		[AINewContactWindowController promptForNewContactOnWindow:nil
															 name:[userInfo objectForKey:@"UID"]
														  service:[userInfo objectForKey:@"service"]];
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
	[self deleteFromArray:array];
}

- (IBAction)deleteSelectionFromTab:(id)sender
{
	AIListObject   *object = [[adium menuController] contactualMenuObject];
	if (object){
		NSArray		*array = [NSArray arrayWithObject:object];
		[NSApp activateIgnoringOtherApps:YES];
		[self deleteFromArray:array];
	}
}

- (void)deleteFromArray:(NSArray *)array
{
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
//	AIListObject	*object = [[adium menuController] contactualMenuObject];
	
}

@end
