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
- (AIEditorListHandle *)_handleNamed:(NSString *)name inGroup:(AIEditorListGroup *)group;
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
    //Flush the collections array, and notify
    [collectionsArray release]; collectionsArray = nil;
    [[owner notificationCenter] postNotificationName:Editor_CollectionArrayChanged object:nil];
}

//Find a handle
- (AIEditorListHandle *)handleNamed:(NSString *)targetHandleName onCollection:(id <AIEditorCollection>)collection
{
    return([self _handleNamed:targetHandleName inGroup:[collection list]]);
}

- (AIEditorListHandle *)_handleNamed:(NSString *)name inGroup:(AIEditorListGroup *)group
{
    NSEnumerator	*enumerator;
    AIEditorListObject	*object;

    //Find the correct group on the new collection
    enumerator = [group objectEnumerator];
    while(object = [enumerator nextObject]){
        if([object isKindOfClass:[AIEditorListHandle class]]){ //Compare the handle names
            if([name compare:[object UID]] == 0){
                return((AIEditorListHandle *)object);
            }

        }else if([object isKindOfClass:[AIEditorListGroup class]]){ //Scan the subgroup
            if((object = [self _handleNamed:name inGroup:(AIEditorListGroup *)object])){
                return((AIEditorListHandle *)object);
            }
        }
    }

    return(nil);
}

//Find a group
- (AIEditorListGroup *)groupNamed:(NSString *)targetGroupName onCollection:(id <AIEditorCollection>)collection
{
    NSEnumerator	*enumerator;
    AIEditorListGroup	*group;

    //Find the correct group on the new collection
    enumerator = [[collection list] objectEnumerator];
    while(group = [enumerator nextObject]){
        if([[group UID] compare:targetGroupName] == 0){
            return(group);
        }
    }

    return(nil);
}

//List Manipulation (sends out notifications)
//Create a handle
- (AIEditorListHandle *)createHandleNamed:(NSString *)inName inGroup:(AIEditorListGroup *)group onCollection:(id <AIEditorCollection>)collection temporary:(BOOL)temporary
{
    NSString		*serviceID = [collection serviceID];
    AIServiceType	*serviceType;
    AIEditorListHandle	*handle;
    NSString		*name;

    //Filter the UID
    serviceType = [[owner accountController] serviceTypeWithID:serviceID];
    name = (serviceType ? [serviceType filterUID:inName] : inName);

    //Make sure a handle with this UID doesn't already exist on the collection
    if(handle = [collection handleWithUID:name serviceID:serviceID]){
        //Move the existing handle to the new location, and return it
        [self moveObject:handle fromCollection:collection toGroup:group collection:collection];
        
    }else{
        //Create a new handle
        if(temporary){
            handle = [[AIEditorListHandle alloc] initWithServiceID:serviceID UID:name temporary:YES];
            [group addObject:handle]; //We don't add the handle to the collection, since it's only temporary

        }else{
            handle = [[AIEditorListHandle alloc] initWithServiceID:serviceID UID:name temporary:NO]; //Create the handle
            [group addObject:handle];	//Add it to the list
            [collection addObject:handle];	//Let the collection add it

            //Post an object added notification
            [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:collection userInfo:[NSDictionary dictionaryWithObject:handle forKey:@"Object"]];
        }
    }

    return(handle);
}

//Create a group
- (AIEditorListGroup *)createGroupNamed:(NSString *)name onCollection:(id <AIEditorCollection>)collection temporary:(BOOL)temporary
{
    AIEditorListGroup	*group;

    //Make sure a group with this UID doesn't already exist on the collection
    if(group = [collection groupWithUID:name]){
        //Return the existing group

    }else{
        if(temporary){
            group = [[AIEditorListGroup alloc] initWithUID:name temporary:YES];
            [[collection list] addObject:group]; //We don't add the group to the collection, since it's only temporary
    
        }else{
            group = [[AIEditorListGroup alloc] initWithUID:name temporary:NO]; 	//Create the group
            [[collection list] addObject:group];					//Add it to the list
            [collection addObject:group];						//Let the collection add it
    
            //Post an object added notification
            [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:collection userInfo:[NSDictionary dictionaryWithObject:group forKey:@"Object"]];
        }
    }
        
    return(group);
}

//Rename an object (correctly sets temporary objects as permanent)
- (BOOL)renameObject:(AIEditorListObject *)object onCollection:(id <AIEditorCollection>)collection to:(NSString *)inName
{
    NSString		*serviceID = [collection serviceID];
    AIServiceType	*serviceType = [[owner accountController] serviceTypeWithID:serviceID];
    NSString		*name = (serviceType ? [serviceType filterUID:inName] : inName); //Filter the new name
    BOOL		success = YES;
    
    if([[object UID] compare:name] != 0){ //Ignore the rename if the name hasn't changed
        if([object isKindOfClass:[AIEditorListHandle class]]){ //Rename of a handle
            if([object temporary]){ //Temporary Handle
                AIEditorListGroup	*group = [object containingGroup];

                //If the handle was temporary, we just delete it and create a new (non temporary) one with the correct name
                [self deleteObject:object fromCollection:collection];
                [self createHandleNamed:inName inGroup:group onCollection:collection temporary:NO];

            }else{ //Regular Handle
                AIEditorListHandle	*handle;
                
                //Make sure a handle with the new UID doesn't already exist on the collection
                if(handle = [collection handleWithUID:name serviceID:serviceID]){
                    [self deleteObject:handle fromCollection:collection]; //Remove the existing handle
                }

                //Rename the handle
                [collection renameObject:object to:name];
                [object setUID:name];

                //Post a renamed notification
                [[owner notificationCenter] postNotificationName:Editor_RenamedObjectOnCollection object:collection userInfo:[NSDictionary dictionaryWithObject:object forKey:@"Object"]];
                
            }
            
        }else if([object isKindOfClass:[AIEditorListGroup class]]){ //Rename of a Group
            if([object temporary]){ //Temporary Group
                //If the group was temporary, we just delete it and create a new (non temporary) one with the correct name
                [self deleteObject:object fromCollection:collection];
                [self createGroupNamed:inName onCollection:collection temporary:NO];

            }else{ //Regular group
                AIEditorListGroup	*group;
                
                //Make sure a group with the new UID doesn't already exist on the collection
                if(group = [collection groupWithUID:inName]){
                    //Warn user and reject
                    NSRunAlertPanel(@"Invalid Name", [NSString stringWithFormat:@"A group named \"%@\" already exists.",name] , nil, nil, nil);
                    success = NO;

                }else{
                    //Rename the group
                    [collection renameObject:object to:inName];
                    [object setUID:inName];

                    //Post a renamed notification
                    [[owner notificationCenter] postNotificationName:Editor_RenamedObjectOnCollection object:collection userInfo:[NSDictionary dictionaryWithObject:object forKey:@"Object"]];
                }
            }
        }
    }

    [[object containingGroup] sort]; //resort the containing editor group
    return(success);
}

//Move an object
- (void)moveObject:(AIEditorListObject *)object fromCollection:(id <AIEditorCollection>)sourceCollection toGroup:(AIEditorListGroup *)destGroup collection:(id <AIEditorCollection>)destCollection
{
    [object retain]; //Temporarily hold onto the object

#warning avoid duplicates

    if(sourceCollection == destCollection){
        if([object containingGroup] != destGroup){
            if(![object temporary]){
                //Allow the collection to move the object
                [sourceCollection moveObject:object toGroup:destGroup];
            }

            //Swap it from one group to the other
            [[object containingGroup] removeObject:object];
            [[owner notificationCenter] postNotificationName:Editor_RemovedObjectFromCollection object:sourceCollection userInfo:[NSDictionary dictionaryWithObject:object forKey:@"Object"]];
    
            [destGroup addObject:object];
            [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:destCollection userInfo:[NSDictionary dictionaryWithObject:object forKey:@"Object"]];
        }
            
    }else{
        //Remove from the source collection
        [sourceCollection deleteObject:object];
        [[object containingGroup] removeObject:object];
        [[owner notificationCenter] postNotificationName:Editor_RemovedObjectFromCollection object:sourceCollection userInfo:[NSDictionary dictionaryWithObject:object forKey:@"Object"]];

        //Add to the destination collection
        [destGroup addObject:object];
        [destCollection addObject:object];
        [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:destCollection userInfo:[NSDictionary dictionaryWithObject:object forKey:@"Object"]];
    }

    [object release];
}

//Delete an object
- (void)deleteObject:(AIEditorListObject *)object fromCollection:(id <AIEditorCollection>)collection
{
    [object retain]; //Hold onto the object until we're done with it

    if(![object temporary]){ //Since temp objects aren't yet in the collection, we skip this call
        [collection deleteObject:object];
    }
    [[object containingGroup] removeObject:object];

    [[owner notificationCenter] postNotificationName:Editor_RemovedObjectFromCollection object:collection userInfo:[NSDictionary dictionaryWithObject:object forKey:@"Object"]];

    [object release];
}

//Import a file
- (void)importFile:(NSString *)inPath
{
    AIEditorImportCollection *defaultCollection;

    //Create a new import collection
    defaultCollection = [AIEditorImportCollection editorCollectionWithPath:inPath];
    [collectionsArray addObject:defaultCollection];

    //Let everyone know the collection list changed
    [[owner notificationCenter] postNotificationName:Editor_CollectionArrayChanged object:nil];

    //Select the new import collection
//    selectedCollection = [[plugin collectionsArray] objectAtIndex:index]; //select it
//    [tableView_sourceList selectRow:index byExtendingSelection:NO]; //highlight it
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
    [collectionsArray addObject:[AIEditorAllContactsCollection allContactsCollectionWithOwner:owner plugin:self]];

    //Add a collection for each account
    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        [collectionsArray addObject:[AIEditorAccountCollection editorCollectionForAccount:account withOwner:owner]];
    }

    //Blocked collection
    //    [collectionsArray addObject:[AIEditorBlockedCollection blockedCollectionWithOwner:owner]];

    //Add a single (empty) collection for imported contacts
//    [collectionsArray addObject:[AIEditorImportCollection editorCollection]];

    //
    [[owner notificationCenter] postNotificationName:Editor_CollectionArrayChanged object:nil];
}


@end
