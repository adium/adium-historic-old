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
#import "AIContactListEditorWindowController.h"
#import "AIEditorAccountCollection.h"
#import "AIEditorImportCollection.h"
#import "AIEditorAllContactsCollection.h"

@interface AIContactListEditorPlugin (PRIVATE)
- (void)_generateCollectionsArray;
- (AIEditorListHandle *)_handleNamed:(NSString *)name inGroup:(AIEditorListGroup *)group;
@end

@implementation AIContactListEditorPlugin

- (void)installPlugin
{
    NSMenuItem		*menuItem;

    //
    listEditorColumnControllerArray = [[NSMutableArray alloc] init];
    collectionsArray = nil;
    
    //Install the 'edit contact list' menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Edit Contact List�" target:self action:@selector(showContactListEditor:) keyEquivalent:@"<"] autorelease];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Adium_Preferences];

    //Edit contact list toolbar item
    NSToolbarItem   *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"EditContactList"
									   label:@"Edit Contact List"
								    paletteLabel:@"Edit Contact List"
									 toolTip:@"Edit Contact List"
									  target:self
								 settingSelector:@selector(setImage:)
								     itemContent:[AIImageUtilities imageNamed:@"AIMsettings" forClass:[self class]]
									  action:@selector(showContactListEditor:)
									    menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"General"];

    //Observe account changes
    [[adium notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
}

- (void)uninstallPlugin
{
    [[adium notificationCenter] removeObserver:self];
    [AIContactListEditorWindowController closeSharedInstance]; //Close the contact list editor
}

//Show the contact list editor window
- (IBAction)showContactListEditor:(id)sender
{
    [[AIContactListEditorWindowController contactListEditorWindowControllerForPlugin:self] showWindow:nil];
}


//Extra List Editor Columns --------------------------------------------------------------------
//Returns an array of the registered column controllers
- (NSArray *)listEditorColumnControllers
{
    //Broadcast a CONTACT_EDITOR_REGISTER_COLUMNS notification, letting all the plugins who haven't had a chance yet register their controllers
    [[adium notificationCenter] postNotificationName:CONTACT_EDITOR_REGISTER_COLUMNS object:self];

    //Now return the array of controllers
    return(listEditorColumnControllerArray);
}

//Register a column controller
- (void)registerListEditorColumnController:(id <AIListEditorColumnController>)inController
{
    //Just add it to our array
    [listEditorColumnControllerArray addObject:inController];
}


//Collection Management ------------------------------------------------------------------------------
//Returns the current array of collections
- (NSArray *)collectionsArray
{
    if(!collectionsArray) [self _generateCollectionsArray];
    
    return(collectionsArray);
}


// Importing ---------------------------------------------------------------------------------------
//Import a file
- (void)importFile:(NSString *)inPath
{
    AIEditorImportCollection *defaultCollection;

    //Create a new import collection
    defaultCollection = [AIEditorImportCollection editorCollectionWithPath:inPath];
    [collectionsArray addObject:defaultCollection];

    //Let everyone know the collection list changed
    [[adium notificationCenter] postNotificationName:Editor_CollectionArrayChanged object:nil];

    //Select the new import collection
    //    selectedCollection = [[plugin collectionsArray] objectAtIndex:index]; //select it
    //    [tableView_sourceList selectRow:index byExtendingSelection:NO]; //highlight it
}


// -----
//Notified when the account list changes
- (void)accountListChanged:(NSNotification *)notification
{
    //Flush the collections array, and notify
    [collectionsArray release]; collectionsArray = nil;
    [[adium notificationCenter] postNotificationName:Editor_CollectionArrayChanged object:nil];
}

//Builds the collection array
- (void)_generateCollectionsArray
{
    NSEnumerator	*accountEnumerator;
    AIAccount		*account;

    //Create the array
    [collectionsArray release];
    collectionsArray = [[NSMutableArray alloc] init];

    //Add an 'all contacts' collection
    [collectionsArray addObject:[AIEditorAllContactsCollection allContactsCollectionForPlugin:self]];

    //Add a collection for each available account
    accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        if([account conformsToProtocol:@protocol(AIAccount_Handles)]){
         //   if([(AIAccount <AIAccount_Handles> *)account availableHandles]){
                [collectionsArray addObject:[AIEditorAccountCollection editorCollectionForAccount:account]];
       //     }
        }
    }

    //
    [[adium notificationCenter] postNotificationName:Editor_CollectionArrayChanged object:nil];
}


@end
