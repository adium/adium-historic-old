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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIContactListEditorWindowController.h"
#import "AIAdium.h"
#import "AIContactController.h"
#import "AIAccountController.h"
#import "AIContactListCheckbox.h"
#import "AIEditorListGroup.h"
#import "AIEditorListHandle.h"
#import "AIEditorCollection.h"
#import "AIEditorAccountCollection.h"

#define CONTACT_LIST_EDITOR_NIB			@"ContactListEditorWindow"
#define	HANDLE_DELETE_KEY			@"Handles"
#define	GROUP_DELETE_KEY			@"Groups"
#define KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME	@"Contact List Editor Frame"

@interface AIContactListEditorWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)windowDidLoad;
- (void)buildAccountColumns;
- (void)accountListChanged:(NSNotification *)notification;
- (void)contactListChanged:(NSNotification *)notification;
- (void)contactChanged:(NSNotification *)notification;
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (void)removeEditor:(id)sender;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (IBAction)inspect:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)group:(id)sender;
- (IBAction)handle:(id)sender;
- (void)installToolbar;
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (void)concludeDeleteSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (AIEditorListGroup *)editorListGroupForAccount:(AIAccount *)inAccount;
- (void)generateCollectionsArray;
- (void)expandCollapseGroup:(AIEditorListGroup *)inGroup subgroups:(BOOL)subgroups outlineView:(NSOutlineView *)inView;
- (void)refreshContentOutlineView;
@end

@implementation AIContactListEditorWindowController

//Create and return a contact list editor window controller
static AIContactListEditorWindowController *sharedInstance = nil;
+ (id)contactListEditorWindowControllerWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_LIST_EDITOR_NIB owner:inOwner];
    }

    return(sharedInstance);
}

+ (void)closeSharedInstance
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    //init
    owner = [inOwner retain];
    [super initWithWindowNibName:windowNibName owner:self];
    selectedCollection = nil;
    
    //Install observers
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_StatusChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_HandlesChanged object:nil];

    //Load our images
    folderImage = [[AIImageUtilities imageNamed:@"Folder" forClass:[self class]] retain];

    return(self);
}

- (void)dealloc
{
    [owner release];
    [folderImage release];
    [toolbarItems release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    AIImageTextCell	*newCell;
    NSString		*savedFrame;
    
    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }

    //-- Setup the outline view --
    //Custom Image/Text cell
//    newCell = [[[AIImageTextCell alloc] init] autorelease];
//    [[[outlineView_contactList tableColumns] objectAtIndex:0] setDataCell:newCell];

    //Colors and alternating rows
    [outlineView_contactList setBackgroundColor:[NSColor colorWithCalibratedRed:(250.0/255.0) green:(250.0/255.0) blue:(250.0/255.0) alpha:1.0]];
    [outlineView_contactList setDrawsAlternatingRows:YES];
    [outlineView_contactList setAlternatingRowColor:[NSColor colorWithCalibratedRed:(231.0/255.0) green:(243.0/255.0) blue:(255.0/255.0) alpha:1.0]];
    [outlineView_contactList setNeedsDisplay:YES];

    //Group expand/collapse notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidExpand:) name:NSOutlineViewItemDidExpandNotification object:outlineView_contactList];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidCollapse:) name:NSOutlineViewItemDidCollapseNotification object:outlineView_contactList];

    //Other settings
    [outlineView_contactList registerForDraggedTypes:[NSArray arrayWithObject:@"AIContactObjects"]];
    [outlineView_contactList setAutoresizesOutlineColumn:NO];
    //[outlineView_contactList setIndentationPerLevel:10];


    //-- Setup the source table view --
    //Custom Image/Text cell
    newCell = [[[AIImageTextCell alloc] init] autorelease];
    [[[tableView_sourceList tableColumns] objectAtIndex:0] setDataCell:newCell];


    //Install our window toolbar and generate our collections
    [self installToolbar];
    [self generateCollectionsArray];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    return(YES);
}


// Content modified notifications
// --------------------------------------------------
//Notified when the account list changes
- (void)accountListChanged:(NSNotification *)notification
{
    //Rebuild the collections array
    [self generateCollectionsArray];
}


// Collections table view
// --------------------------------------------------
//Builds the collection array for all accounts
- (void)generateCollectionsArray
{
    NSEnumerator	*accountEnumerator;
    AIAccount		*account;

    //Create the array
    [collectionsArray release];
    collectionsArray = [[NSMutableArray alloc] init];

    //Add a collection for all accounts
    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        [collectionsArray addObject:[AIEditorAccountCollection editorCollectionForAccount:account]];
    }

    //Update the selected collection
    [self tableViewSelectionIsChanging:nil];
}

//As the selection changes, update the outline view to reflect the selected collection
- (void)tableViewSelectionIsChanging:(NSNotification *)notification
{
    id <AIEditorCollection>	newSelection;
    
    int	selectedRow = [tableView_sourceList selectedRow];
    if(selectedRow < 0 || selectedRow >= [collectionsArray count]) selectedRow = 0; //Ensure a valid selection

    //Record the new selected collection
    newSelection = [collectionsArray objectAtIndex:selectedRow];
    if([newSelection enabled]){
        selectedCollection = newSelection;
    }
    
    [self refreshContentOutlineView]; //Refresh the outline view for the new selection
}

//Table view delegate methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([collectionsArray count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    id <AIEditorCollection>	collection = [collectionsArray objectAtIndex:row];

    return([collection name]);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    id <AIEditorCollection>	collection = [collectionsArray objectAtIndex:row];

    [cell setEnabled:[collection enabled]];
    [cell setImage:[[collectionsArray objectAtIndex:row] icon]]; //Set the correct account icon
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    id <AIEditorCollection>	collection = [collectionsArray objectAtIndex:row];

    return([collection enabled]);
}




// Handles & Groups outline view
// --------------------------------------------------
//Correctly sets the contact groups as expanded or collapsed, depending on their saved state
- (void)expandCollapseGroup:(AIEditorListGroup *)inGroup subgroups:(BOOL)subgroups outlineView:(NSOutlineView *)inView
{
    NSEnumerator	*enumerator = [inGroup objectEnumerator];
    AIEditorListObject	*object;

    if(inGroup){
        //Group
        ([inGroup isExpanded] ? [inView expandItem:inGroup] : [inView collapseItem:inGroup]);
        
        //Subgroups
        while((object = [enumerator nextObject])){
            if([object isKindOfClass:[AIEditorListGroup class]]){
                //Correctly expand/collapse the group
                ([(AIEditorListGroup *)object isExpanded] ? [inView expandItem:object] : [inView collapseItem:object]);

                //Expand/collapse any subgroups
                if(subgroups){
                    [self expandCollapseGroup:(AIEditorListGroup *)object subgroups:YES outlineView:inView];
                }
            }
        }
    }
}

//Called as groups are expended and collapsed, updates their expanded state
- (void)itemDidExpand:(NSNotification *)notification
{
    [[[notification userInfo] objectForKey:@"NSObject"] setExpanded:YES];
}
- (void)itemDidCollapse:(NSNotification *)notification
{
    [[[notification userInfo] objectForKey:@"NSObject"] setExpanded:NO];
}

//Refresh the outline view and update it's group state
- (void)refreshContentOutlineView
{
    [outlineView_contactList reloadData]; //Reload the view
    [self expandCollapseGroup:[selectedCollection list]
                    subgroups:YES
                  outlineView:outlineView_contactList]; //Correctly expand/collapse its groups
}






// Outline View ---------------------------------------------------------------------------------
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([[selectedCollection list] objectAtIndex:index]);
    }else{
        return([item objectAtIndex:index]);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[AIEditorListGroup class]]){ //Only allow expanding of groups    
        return(YES);
    }else{
        return(NO);
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
        return([[selectedCollection list] count]);
    }else{
        return([item count]);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return([item UID]);
}

/*- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if([item isKindOfClass:[AIEditorListGroup class]]){
        [cell setImage:folderImage];
    }else{
        [cell setImage:nil];
// temporarily off [cell setImage: [[(AIContactHandle *)item service] image]];
    }
}*/

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return(YES);
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString	*identifier = [tableColumn identifier];

    if([item isKindOfClass:[AIEditorListGroup class]]){ //GROUP
//        [[owner contactController] renameObject:item to:object];

    }else{ //HANDLE
        if([identifier compare:@"handle"] == 0){
            if([item temporary]){
                //Temporary items have not yet been added to the collection, so we can freely change its UID to the correct/new one before adding it.
                [item setUID:object];                
                [selectedCollection addObject:item];

            }else{
                [selectedCollection renameObject:item to:object];
                [item setUID:object]; //Rename the object after the collection has had a chance to rename
            }

            [[(AIEditorListHandle *)item containingGroup] sort]; //resort the containing group
            [self refreshContentOutlineView]; //Refresh

        }else if([identifier compare:@"alias"] == 0){
            // Set Alias
            // No way yet
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:[NSArray arrayWithObjects:@"AIContactObjects",nil] owner:self];

    //Build a list of all the highlighted objects
    if(dragItems) [dragItems release];
    dragItems = [items copy];

    //put it on the pasteboard
    [pboard setString:@"Private" forType:@"AIContactObjects"];

    return(YES);
}

- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];

    if([avaliableType compare:@"AIContactObjects"] == 0){
        if((item == nil ||					//(handles can be dragged to the root level
            index != -1 ||					// to anywhere in a group
            [item isKindOfClass:[AIEditorListGroup class]])	// or onto a group)
           && ([dragItems indexOfObject:item] == NSNotFound)){	//(But they cannot be dragged into themselves)

            return(NSDragOperationPrivate);

        }else{
            return(NSDragOperationNone);

        }

    }else{
        return(NSDragOperationMove);

    }
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    NSString 	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];

    if([availableType compare:@"AIContactObjects"] == 0){
        NSEnumerator		*enumerator;
        AIEditorListObject	*object;

        //Move the groups first
        enumerator = [dragItems objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isKindOfClass:[AIEditorListGroup class]]){
//                [[
//                [[owner contactController] moveObject:object toGroup:item index:index];
            }
        }

        //Then move the handles
        enumerator = [dragItems objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isKindOfClass:[AIEditorListHandle class]]){
                [selectedCollection moveObject:object toGroup:item];
                [object retain];
                [[object containingGroup] removeObject:object];
                [item addObject:object];
                [object release];
            }
        }
    }

    [dragItems release]; dragItems = nil;
    [self refreshContentOutlineView]; //Refresh

    return(YES);
}





// Toolbar actions
// ----------------------------------------
//Inspect the selected contact
- (IBAction)inspect:(id)sender
{
    AIEditorListObject	*selectedObject = [outlineView_contactList itemAtRow:[outlineView_contactList selectedRow]];

    if([selectedObject isKindOfClass:[AIEditorListHandle class]]){
        AIListContact	*contact;
        AIServiceType	*serviceType;

        //Find the contact
        serviceType = [[owner accountController] serviceTypeWithID:[(AIEditorListHandle *)selectedObject serviceID]];
        contact = [[owner contactController] contactInGroup:nil
                                                withService:serviceType
                                                        UID:[selectedObject UID]];

        //Show its info
        [[owner contactController] showInfoForContact:contact];
    }
    
}


//Filter keydowns looking for the delete key (to delete the current selection)
- (void)keyDown:(NSEvent *)theEvent
{
    NSString	*charString = [theEvent charactersIgnoringModifiers];
    unichar	pressedChar = 0;

    //Get the pressed character
    if([charString length] == 1) pressedChar = [charString characterAtIndex:0];
    
    //Check if 'delete' was pressed
    if(pressedChar == NSDeleteFunctionKey || pressedChar == 127){ //Delete
        [self delete:nil]; //Delete the selection
    }else{
        [super keyDown:theEvent]; //Pass the key event on
    }
}


//Delete the selection
- (IBAction)delete:(id)sender
{
    NSDictionary	*contextInfo;
    NSMutableArray	*handles;
    NSMutableArray 	*groups;
    NSEnumerator 	*enumerator;
    NSNumber		*row;
    int			numGroups = 0, numHandles = 0;

    //build a list of targeted handles and groups
    handles = [NSMutableArray array];
    groups = [NSMutableArray array];
    enumerator = [outlineView_contactList selectedRowEnumerator];
    while(row = [enumerator nextObject]){
        id object = [outlineView_contactList itemAtRow:[row intValue]];

        if([object isMemberOfClass:[AIEditorListHandle class]]){
            numHandles++;
            [handles addObject:object];
        }else{
            if([object count] != 0){
                numGroups++;
            }
            [groups addObject:object];
        }
    }
    contextInfo = [[NSDictionary dictionaryWithObjectsAndKeys:handles, HANDLE_DELETE_KEY, groups, GROUP_DELETE_KEY, nil] retain];
  
    //confirm for mass amounts of deleting
    if(numGroups != 0 && numHandles > 1){
        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i group%@ and %i contact%@ from %@'s list?", numGroups, (numGroups != 1) ? @"s" : @"", numHandles, (numHandles != 1) ? @"s" : @"", [selectedCollection name]], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Be careful, you cannot undo this action.");

    }else if(numGroups != 0){
        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i group%@ from %@'s list?", numGroups, (numGroups != 1) ? @"s" : @"", [selectedCollection name]], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Any handles in %@ will be deleted.  Be careful, you cannot undo this action.", (numGroups != 1) ? @"these groups" : @"this group");

    }else if(numHandles > 1){
        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i contact%@ from %@'s list?", numHandles, (numHandles != 1) ? @"s" : @"", [selectedCollection name]], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Be careful, you cannot undo this action.");
    }else{ //for single handle and empty group deletes, we don't prompt the user
        [self concludeDeleteSheet:nil returnCode:NSAlertDefaultReturn contextInfo:contextInfo];
    }

    //De-select everything
    [outlineView_contactList deselectAll:nil];
}

- (void)concludeDeleteSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSDictionary	*targetDict = contextInfo;
    
    if(returnCode == NSAlertDefaultReturn){
        NSEnumerator		*enumerator;
        AIEditorListObject	*object;

        //Delete all the handles
        enumerator = [[targetDict objectForKey:HANDLE_DELETE_KEY] objectEnumerator];
        while((object = [enumerator nextObject])){
            if(![object temporary]){ //Since temp objects aren't yet in the collecting, we skip this call
                [selectedCollection deleteObject:object];
            }
            [[object containingGroup] removeObject:object];
        }

        //Delete all the groups
        enumerator = [[targetDict objectForKey:GROUP_DELETE_KEY] objectEnumerator];
        while((object = [enumerator nextObject])){
            if(![object temporary]){ //Since temp objects aren't yet in the collecting, we skip this call
                [selectedCollection deleteObject:object];
            }
            [[object containingGroup] removeObject:object];
        }
    }
    
    [targetDict release];
    [self refreshContentOutlineView]; //Refresh
}

//Create a new group
- (IBAction)group:(id)sender
{
/*    id			selectedItem;
    id			selectedGroup;
    AIContactGroup	*newGroup;
    int			newRow;

    //Get the currently selected group
    selectedItem = [outlineView_contactList itemAtRow:[outlineView_contactList selectedRow]];
    if(selectedItem == nil){
        selectedGroup = [[owner contactController] contactList];
    }else if([selectedItem isKindOfClass:[AIContactHandle class]]){
        selectedGroup = [selectedItem containingGroup];
    }else{
        selectedGroup = selectedItem;
        [outlineView_contactList expandItem:selectedGroup]; //make sure the group is expanded
    }

    //Force-end any contact list editing
    [self removeEditor:nil];

    //Create the new group
    newGroup = [[owner contactController] createGroupNamed:@"Group" inGroup:selectedGroup];
    
    //Select, scroll to, and edit the new group
    newRow = [outlineView_contactList rowForItem:newGroup];
    [outlineView_contactList selectRow:newRow byExtendingSelection:NO];
    [outlineView_contactList scrollRowToVisible:newRow];
    [self outlineView:outlineView_contactList shouldEditTableColumn:[outlineView_contactList tableColumnWithIdentifier:@"handle"] item:newGroup];
    */
}

//Create a new group
- (IBAction)handle:(id)sender
{
    AIEditorListHandle	*newHandle;
    int			newRow;
    AIEditorListObject	*selectedItem;
    AIEditorListGroup	*selectedGroup;

    //Get the currently selected group
    selectedItem = [outlineView_contactList itemAtRow:[outlineView_contactList selectedRow]];
    if(selectedItem == nil){
        selectedGroup = [selectedCollection list];
    }else if([selectedItem isKindOfClass:[AIEditorListHandle class]]){
        selectedGroup = [selectedItem containingGroup];
    }else{
        selectedGroup = (AIEditorListGroup *)selectedItem;
        [outlineView_contactList expandItem:selectedGroup]; //make sure the group is expanded
    }

    //Create the new handle
#warning have the collection return a service type
    newHandle = [[AIEditorListHandle alloc] initWithServiceID:@"TEMP" UID:@"New Contact" temporary:YES];
    [selectedGroup addObject:newHandle];
    [self refreshContentOutlineView];        

    //Select, scroll to, and edit the new handle
    newRow = [outlineView_contactList rowForItem:newHandle];
    [outlineView_contactList scrollRowToVisible:newRow];
    [outlineView_contactList selectRow:newRow byExtendingSelection:NO];
    if([self outlineView:outlineView_contactList shouldEditTableColumn:[outlineView_contactList tableColumnWithIdentifier:@"handle"] item:newHandle]){
        [outlineView_contactList editColumn:[outlineView_contactList indexOfTableColumnWithIdentifier:@"handle"] row:newRow withEvent:nil select:YES];
    }
}




// Window toolbar
// --------------------------------------------------
- (void)installToolbar
{
    NSToolbar *toolbar;

    //Setup the toolbar
    toolbar = [[[NSToolbar alloc] initWithIdentifier:@"UserSelectionPanel"] autorelease];
    toolbarItems = [[NSMutableDictionary dictionary] retain];

    //Add the items
    [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:@"Group"
                                             label:@"Group"
                                      paletteLabel:@"Group"
                                           toolTip:@"Create a new group"
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"addGroup" forClass:[self class]]
                                            action:@selector(group:)
                                              menu:NULL];

    [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:@"Handle"
                                             label:@"Handle"
                                      paletteLabel:@"Handle"
                                           toolTip:@"Add a handle to your contact list"
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"addHandle" forClass:[self class]]
                                            action:@selector(handle:)
                                              menu:NULL];

    [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:@"Delete"
                                             label:@"Delete"
                                      paletteLabel:@"Delete"
                                           toolTip:@"Remove an item from your contact list"
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"remove" forClass:[self class]]
                                            action:@selector(delete:)
                                              menu:NULL];

    [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:@"Inspector"
                                             label:@"Inspector"
                                      paletteLabel:@"Inspector"
                                           toolTip:@"Inspector"
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"inspect" forClass:[self class]]
                                            action:@selector(inspect:)
                                              menu:NULL];

    //Configure the toolbar
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];

    //Install it
    [[self window] setToolbar:toolbar];
}

//Validate a toolbar item
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if(([[theItem itemIdentifier] compare:@"Delete"] == 0) || ([[theItem itemIdentifier] compare:@"Inspector"] == 0)){
        if([outlineView_contactList selectedRow] != -1 && [[self window] firstResponder] == outlineView_contactList){
            return(YES);
        }else{
            return(NO);
        }
    }else if(([[theItem itemIdentifier] compare:@"Group"] == 0) || ([[theItem itemIdentifier] compare:@"Handle"] == 0)){
        if(selectedCollection){
            return(YES);
        }else{
            return(NO);
        }
    }

    return(YES);
}

//Return the requested toolbar item
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

//Return the default toolbar set
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Group",@"Handle",NSToolbarSeparatorItemIdentifier,@"Delete",NSToolbarFlexibleSpaceItemIdentifier,@"Inspector",nil];
}

//Return a list of allowed toolbar items
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Group",@"Handle",@"Delete",@"Inspector",NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,nil];
}

@end





/*- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    int		row, column;
    NSRect	cellFrame;
    NSWindow	*window;

    if(![[tableColumn identifier] isKindOfClass:[AIAccount class]]){ //Double click on checkboxes is ignored
        window = [outlineView window];

        //Get the cell's dimensions
        row = [outlineView rowForItem:item];
        column = [[outlineView tableColumns] indexOfObject:tableColumn];
        cellFrame = [outlineView frameOfCellAtColumn:column row:row];

        cellFrame.origin.x += 14;
        cellFrame.size.width -= 14;

        cellFrame.origin.y -= 2;
        cellFrame.size.height += 4;

        //Close an existing editor
        [self removeEditor:nil];

        //Position and display the editor
        if(editor == nil){
            //Create it for the first time
            editor = [[NSTextField alloc] init];
            [editor setDelegate:self];
            [editor setTarget:self];
            [editor setAction:@selector(removeEditor:)];
            [editor setBezeled:YES];
            [editor setEditable:YES];
            [editor setFont:[NSFont labelFontOfSize:11]];
            [editor setSelectable:YES];
        }
        [editor setFrame:cellFrame];
        [editor setStringValue:[self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item]];
        [editor selectText:nil];
        [outlineView addSubview:editor];
        [window makeFirstResponder:editor];
        editedObject = item;
        editedColumn = tableColumn;
    }

    return(NO);
}

//Removes the field editor from view
- (void)removeEditor:(id)sender
{
    if(editedObject != nil){
        [self outlineView:outlineView_contactList setObjectValue:[editor stringValue] forTableColumn:editedColumn byItem:editedObject];

        [editor removeFromSuperview];
        editedObject = nil;
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    [self removeEditor:nil];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    AIAccount		*account = [tableColumn identifier];

    if([item isKindOfClass:[AIContactGroup class]]){ //GROUP
        if([account isKindOfClass:[AIAccount class]]){ //ACCOUNT
            if([object boolValue]){ //Add every handle in the group
                int	loop;

                for(loop = 0;loop < [item count];loop++){
                    AIContactHandle	*handle = [item objectAtIndex:loop];

                    if(![handle belongsToAccount:account]){
                        [[owner contactController] addAccount:account toObject:handle];
                    }
                }

            }else{ //Remove every handle in the group
                int	loop;

                for(loop = 0;loop < [item count];loop++){
                    AIContactHandle	*handle = [item objectAtIndex:loop];

                    if([handle belongsToAccount:account]){
                        [[owner contactController] removeAccount:account fromObject:handle];
                    }
                }

            }
        }else{ //NAME
            [[owner contactController] renameObject:item to:object];

            //        }

    }else{ //HANDLE
        if([account isKindOfClass:[AIAccount class]]){ //ACCOUNT
            if([object boolValue]){ //Adding to list
                [[owner contactController] addAccount:account toObject:item];

            }else{ //Removing from list
                [[owner contactController] removeAccount:account fromObject:item];

            }
        }else{ //NAME
               //ikrieg start
            NSArray	*columns;
            columns = [outlineView_contactList tableColumns];
            if ([columns objectAtIndex:([columns count] - 1)] == tableColumn)
            {	// Set Alias
              // No way yet
            }
            else
            {//ikrieg end
                [[owner contactController] renameObject:item to:object];
            }//ikrieg's brace
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:[NSArray arrayWithObjects:@"AIContactObjects",nil] owner:self];

    //Build a list of all the highlighted objects
    if(dragItems) [dragItems release];
    dragItems = [items copy];

    //put it on the pasteboard
    [pboard setString:@"Private" forType:@"AIContactObjects"];

    return(YES);
}

- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];

    if([avaliableType compare:@"AIContactObjects"] == 0){
        if((item == nil ||					//(handles can be dragged to the root level
            index != -1 ||					// to anywhere in a group
            [item isKindOfClass:[AIContactGroup class]])	// or onto a group)
           && ([dragItems indexOfObject:item] == NSNotFound)){	//(But they cannot be dragged into themselves)

            return(NSDragOperationPrivate);

        }else{
            return(NSDragOperationNone);

        }
    }else{
        return(NSDragOperationMove);

    }
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    NSString 	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];

    if([availableType compare:@"AIContactObjects"] == 0){
        NSEnumerator	*enumerator;
        AIContactObject	*object;

        //Move the groups first
        enumerator = [dragItems objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isKindOfClass:[AIContactGroup class]]){
                [[owner contactController] moveObject:object toGroup:item index:index];
            }
        }

        //Then move the handles
        enumerator = [dragItems objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isKindOfClass:[AIContactHandle class]]){
                [[owner contactController] moveObject:object toGroup:item index:index];
            }
        }
    }

    [dragItems release]; dragItems = nil;
    return(YES);
}
*/
