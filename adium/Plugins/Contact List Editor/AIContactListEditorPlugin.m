/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIEditorAccountCollection.h"
#import "AIEditorImportCollection.h"
#import "AIEditorAllContactsCollection.h"
#import "AIEditorBlockedCollection.h"

@interface AIContactListEditorPlugin (PRIVATE)
- (void)_generateCollectionsArray;
@end

@implementation AIContactListEditorPlugin

- (void)installPlugin
{
    AIMiniToolbarItem	*toolbarItem;
    NSMenuItem		*menuItem;

    //
    listEditorColumnControllerArray = [[NSMutableArray alloc] init];
    collectionsArray = nil;
    
    //Install the 'edit contact list' menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Edit Contact List…" target:self action:@selector(showContactListEditor:) keyEquivalent:@""] autorelease];
    [[owner menuController] addMenuItem:menuItem toLocation:LOC_Adium_Preferences];

    //Register our toolbar item
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"EditContactList"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"AIMsettings" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(showContactListEditor:)];
    [toolbarItem setToolTip:@"Edit contact list"];
    [toolbarItem setPaletteLabel:@"Edit contact list"];
    [toolbarItem setEnabled:YES];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];

    //Observe account changes
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
}

- (void)uninstallPlugin
{
    [[owner notificationCenter] removeObserver:self];
    [AIContactListEditorWindowController closeSharedInstance]; //Close the contact list editor
}

//Show the contact list editor window
- (IBAction)showContactListEditor:(id)sender
{
    [[AIContactListEditorWindowController contactListEditorWindowControllerWithOwner:owner plugin:self] showWindow:nil];
}

//Returns an array of the registered column controllers
- (NSArray *)listEditorColumnControllers
{
    //Broadcast a CONTACT_EDITOR_REGISTER_COLUMNS notification, letting all the plugins who haven't had a change yet register their controllers
    [[owner notificationCenter] postNotificationName:CONTACT_EDITOR_REGISTER_COLUMNS object:self];

    //Now return the array of controllers
    return(listEditorColumnControllerArray);
}

//Register a column controller
- (void)registerListEditorColumnController:(id <AIListEditorColumnController>)inController
{
    //Just add it to our array
    [listEditorColumnControllerArray addObject:inController];
}

//Returns the current array of collections
- (NSArray *)collectionsArray
{
    if(!collectionsArray) [self _generateCollectionsArray];
    
    return(collectionsArray);
}

//Notified when the account list changes
- (void)accountListChanged:(NSNotification *)notification
{
    //Flush the collections array
    [collectionsArray release]; collectionsArray = nil;
}

//Builds the collection array
- (void)_generateCollectionsArray
{
    NSEnumerator	*accountEnumerator;
    AIAccount		*account;

    NSLog(@"generateCollectionsArray");

    //Create the array
    [collectionsArray release];
    collectionsArray = [[NSMutableArray alloc] init];

    //Add an 'all contacts' collection
    [collectionsArray addObject:[AIEditorAllContactsCollection allContactsCollectionWithOwner:owner plugin:self]];

    //Add a collection for each account
    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        [collectionsArray addObject:[AIEditorAccountCollection editorCollectionForAccount:account withOwner:owner]];
    }

    //Blocked collection
    //    [collectionsArray addObject:[AIEditorBlockedCollection blockedCollectionWithOwner:owner]];

    //Add a single (empty) collection for imported contacts
    [collectionsArray addObject:[AIEditorImportCollection editorCollection]];

    //
    [[owner notificationCenter] postNotificationName:Editor_CollectionArrayChanged object:nil];
}


@end
