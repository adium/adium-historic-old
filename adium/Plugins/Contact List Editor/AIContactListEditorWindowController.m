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
#import "AIEditorImportCollection.h"
#import "AIContactListEditorPlugin.h"
#import "AIContactListCollectionCell.h"
#import "AIEditorAllContactsCollection.h"
#import "AIEditorBlockedCollection.h"

#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define CONTACT_LIST_EDITOR_NIB			@"ContactListEditorWindow"
#define	HANDLE_DELETE_KEY			@"Handles"
#define	GROUP_DELETE_KEY			@"Groups"
#define KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME	@"Contact List Editor Frame"
#define KEY_CONTACT_EDITOR_GROUP_STATE		@"Contact Editor Group State"	//Expand/Collapse state of groups

#define CHECK_COLUMN_WIDTH			13

@interface AIContactListEditorWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner plugin:(AIContactListEditorPlugin *)inPlugin;
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
- (IBAction)import:(id)sender;
- (IBAction)toggleDrawer:(id)sender;
- (void)installToolbar;
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (void)concludeDeleteSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)concludeImportPanel:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (AIEditorListGroup *)editorListGroupForAccount:(AIAccount *)inAccount;
- (void)generateCollectionsArray;
- (void)refreshContentOutlineView;
- (void)configureForCollection:(id <AIEditorCollection>)collection;
@end

@implementation AIContactListEditorWindowController

//Create and return a contact list editor window controller
static AIContactListEditorWindowController *sharedInstance = nil;
+ (id)contactListEditorWindowControllerWithOwner:(id)inOwner plugin:(AIContactListEditorPlugin *)inPlugin
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_LIST_EDITOR_NIB owner:inOwner plugin:inPlugin];
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
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner plugin:(AIContactListEditorPlugin *)inPlugin
{
    //init
    owner = [inOwner retain];
    plugin = inPlugin;
    selectedCollection = nil;

    [super initWithWindowNibName:windowNibName owner:self];
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [owner release];
    [folderImage release];
    [toolbarItems release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    AIImageTextCell			*newCell;
    NSString				*savedFrame;
    
    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }

    //Observe frame changes to correctly size our outline view columns
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sizeContentColumnsToFit:) name:NSViewFrameDidChangeNotification object:outlineView_contactList];

    //Content view colors and alternating rows
    [outlineView_contactList setBackgroundColor:[NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0]];
    [outlineView_contactList setDrawsAlternatingRows:YES];
    [outlineView_contactList setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [outlineView_contactList setNeedsDisplay:YES];

    //Other settings
    [outlineView_contactList registerForDraggedTypes:[NSArray arrayWithObject:@"AIContactObjects"]];
    [outlineView_contactList setAutoresizesOutlineColumn:NO];

    //Source list custom Image/Text cell
    newCell = [[[AIContactListCollectionCell alloc] init] autorelease];
    [[[tableView_sourceList tableColumns] objectAtIndex:0] setDataCell:newCell];
    [scrollView_sourceList setAutoScrollToBottom:NO];
    [scrollView_sourceList setAutoHideScrollBar:YES];

    //Install our window toolbar and generate our collections
    [self installToolbar];
    [self generateCollectionsArray];

    //If the user has multiple collections, open the drawer
    if([collectionsArray count] > 1){
        [self toggleDrawer:nil];
    }
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

    [sharedInstance autorelease]; sharedInstance = nil;
    
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
//Builds the collection array
- (void)generateCollectionsArray
{
    NSEnumerator	*accountEnumerator;
    AIAccount		*account;

    //Create the array
    [collectionsArray release];
    collectionsArray = [[NSMutableArray alloc] init];

    //Add an 'all contacts' collection
    [collectionsArray addObject:[AIEditorAllContactsCollection allContactsCollectionWithOwner:owner]];
    
    //Add a collection for each account
    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        [collectionsArray addObject:[AIEditorAccountCollection editorCollectionForAccount:account]];
    }

    //Blocked collection
//    [collectionsArray addObject:[AIEditorBlockedCollection blockedCollectionWithOwner:owner]];
    
    //Add a single (empty) collection for imported contacts 
    [collectionsArray addObject:[AIEditorImportCollection editorCollection]];
    
    //Update the selected collection
    [tableView_sourceList reloadData];
    [self tableViewSelectionIsChanging:nil];
}

//As the selection changes, update the outline view to reflect the selected collection
- (void)tableViewSelectionIsChanging:(NSNotification *)notification
{
    if(notification == nil || [notification object] == tableView_sourceList){
        int			selectedRow;

        //Ensure a valid selection
        selectedRow = [tableView_sourceList selectedRow];
        if(selectedRow < 0 || selectedRow >= [tableView_sourceList numberOfRows]) selectedRow = 0; 

        //Configure the outline view for the new selection
        selectedCollection = [collectionsArray objectAtIndex:selectedRow];
        [self configureForCollection:selectedCollection];
        
    }
}

//Configure the editor for the specified collection
- (void)configureForCollection:(id <AIEditorCollection>)collection
{
    NSEnumerator			*enumerator;
    id <AIListEditorColumnController>	columnController;
    
    //Update the window title
    [[self window] setTitle:[collection collectionDescription]];

    //Remove all extra columns (keeping only the contact UID column)
    while([outlineView_contactList numberOfColumns] > 1){
        NSTableColumn	*column = [[outlineView_contactList tableColumns] objectAtIndex:0];

        if(column == [outlineView_contactList outlineTableColumn]){
            [outlineView_contactList removeTableColumn:[[outlineView_contactList tableColumns] objectAtIndex:1]];
        }else{
            [outlineView_contactList removeTableColumn:column];
        }
    }

    //Add the ownership columns
    if([collection showOwnershipColumns] && [[[owner accountController] accountArray] count] > 1){
        NSEnumerator	*accountEnumerator;
        AIAccount	*account;
        int		numberOfAccounts = [[[owner accountController] accountArray] count];

        //Add a column for all accounts
        accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
        while((account = [accountEnumerator nextObject])){
            NSTableColumn	*tableColumn = [[[NSTableColumn alloc] initWithIdentifier:account] autorelease];

            //Create and configure the table column
            tableColumn = [[[NSTableColumn alloc] initWithIdentifier:account] autorelease];
            [tableColumn setWidth:CHECK_COLUMN_WIDTH];
            [tableColumn setMinWidth:CHECK_COLUMN_WIDTH];
            [tableColumn setMaxWidth:CHECK_COLUMN_WIDTH];
            [[tableColumn headerCell] setStringValue:[account accountDescription]];
            [tableColumn setDataCell:[[[AIContactListCheckbox alloc] init] autorelease]];

            //Add it
            [outlineView_contactList addTableColumn:tableColumn];
        }

        //Move the contact UID column back to its correct place
        [outlineView_contactList moveColumn:0 toColumn:[outlineView_contactList numberOfColumns]-1];

    }
    
    //Add the custom list editor columns
    if([collection showCustomEditorColumns]){
        enumerator = [[plugin listEditorColumnControllers] objectEnumerator];
        while((columnController = [enumerator nextObject])){
            NSTableColumn	*tableColumn = [[[NSTableColumn alloc] initWithIdentifier:columnController] autorelease];

            [tableColumn setDataCell:[[[[outlineView_contactList outlineTableColumn] dataCell] copy] autorelease]];
            [tableColumn setEditable:YES];

            [tableColumn setWidth:140];
            [tableColumn setMinWidth:40];
            [tableColumn setMaxWidth:1000];

            [outlineView_contactList addTableColumn:tableColumn];
            [[tableColumn headerCell] setStringValue:[columnController editorColumnLabel]];
        }
    }
    
    //Redraw the content outline view
    [self refreshContentOutlineView];

    //Set the columns to the correct width
    [self sizeContentColumnsToFit:nil];
    
}

//Adjust outline view columns
- (void)sizeContentColumnsToFit:(NSNotification)notification
{
    NSEnumerator	*enumerator;
    NSTableColumn	*column;
    int			totalWidth = [scrollView_contactList documentVisibleRect].size.width;
    int			flexColumns = 0;
    BOOL		firstColumnProcessed = NO;
    float		flexWidth;
    NSSize		spacing = [outlineView_contactList intercellSpacing];
    float		indentation = ([outlineView_contactList indentationPerLevel] * 2);

    //Factor in the width of all fixed width columns
    enumerator = [[outlineView_contactList tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        if([column minWidth] == [column maxWidth]){ //Fixed width column
            totalWidth -= ([column width] + spacing.width);
        }else{
            flexColumns++;
        }
    }

    //Compensate for the indentation in the leftmost column
    totalWidth -= indentation;
    
    //Split the remaining space
    flexWidth = totalWidth / flexColumns;
    enumerator = [[outlineView_contactList tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        if([column minWidth] != [column maxWidth]){ //Flex width column
            if(firstColumnProcessed){
                [column setWidth:(flexWidth - spacing.width)];
            }else{
                //Give the first column any extra pixels, and compensate for the indentation
                [column setWidth:((totalWidth / flexColumns) + (totalWidth % flexColumns) + (indentation) - spacing.width)];
                firstColumnProcessed = YES;
            }
        }
    }
    
}

- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSLog(@"Click");
    // check to see if this column was already the selected one and if so invert the sort function.
    // if there already was a sorted column, remove the indicator image from it.
    // set the indicator image in the newly selected column.
    // set the highlighted table column.
    // set the sort function based on what column was clicked.
    // deselect all selected rows.
    // resort the data
    // reload the data
    // reapply the selection...
}

//Refresh the outline view and update its group state
- (void)refreshContentOutlineView
{
    [outlineView_contactList reloadData]; //Reload the view
}


// Collection Table View Delegate ---------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([collectionsArray count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return(@""); //Ignored by our cell
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    id <AIEditorCollection> collection = [collectionsArray objectAtIndex:row];

    [cell setEnabled:[collection enabled]];
    [cell setImage:[collection icon]]; //Set the correct account icon
    [cell setLabel:[collection name] subLabel:[collection subLabel]];    
}


// Contact Outline View Delegate ---------------------------------------------------------
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
    id		identifier = [tableColumn identifier];
    id		value = nil;

    if([identifier isKindOfClass:[NSString class]]){
        value = [item UID];

    }else if([identifier isKindOfClass:[AIAccount class]]){
        //Return the correct checkbox state
        if([item isKindOfClass:[AIEditorListHandle class]]){
            if([[item ownerAccountArray] containsObject:identifier]){
                value = [NSNumber numberWithInt:1];
            }else{
                value = [NSNumber numberWithInt:0];
            }

        }else if([item isKindOfClass:[AIEditorListGroup class]]){
            NSEnumerator	*enumerator = [item objectEnumerator];
            AIEditorListHandle	*handle;
            BOOL		owned = NO;
            BOOL		notOwned = NO;

            while((handle = [enumerator nextObject])){
                if([[handle ownerAccountArray] containsObject:identifier]){
                    owned = YES;
                }else{
                    notOwned = YES;
                }

                if(owned && notOwned) break; //Abort early if we find a mix
            }
            
            if(owned && notOwned){
                value = [NSNumber numberWithInt:2];
            }else if(owned){
                value = [NSNumber numberWithInt:1];
            }else{
                value = [NSNumber numberWithInt:0];
            }
        }
        
    }else if([identifier conformsToProtocol:@protocol(AIListEditorColumnController)]){
        if([item isKindOfClass:[AIEditorListHandle class]]){
            value = [(id <AIListEditorColumnController>)identifier editorColumnStringForServiceID:[item serviceID] UID:[item UID]];
        }
    }

    return(value);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return(YES);
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier isKindOfClass:[NSString class]]){ //Handle/Group name column
        if([identifier compare:@"handle"] == 0){
            if([item temporary]){
                //Temporary items have not yet been added to the collection, so we can freely change its UID to the correct/new one before adding it.
                [item setUID:object];                
                [selectedCollection addObject:item];
                [item setTemporary:NO];

            }else{
                [selectedCollection renameObject:item to:object];
                [item setUID:object]; //Rename the object after the collection has had a chance to rename
            }

            [[(AIEditorListHandle *)item containingGroup] sort]; //resort the containing group
            [self refreshContentOutlineView]; //Refresh
        }
        
    }else if([identifier conformsToProtocol:@protocol(AIListEditorColumnController)]){ //custom column
        //Pass the new value to the column controller
        if([item isKindOfClass:[AIEditorListHandle class]]){
            [(id <AIListEditorColumnController>)identifier editorColumnSetStringValue:object forServiceID:[(AIEditorListHandle *)item serviceID] UID:[(AIEditorListHandle *)item UID]];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    NSEnumerator	*enumerator;
    AIEditorListObject	*object;
    BOOL		handles = NO, groups = NO;

    //We either drag all handles, or all groups.  A mix of the two is not allowed
    enumerator = [items objectEnumerator];
    while((object = [enumerator nextObject]) && !(handles && groups)){
        if([object isKindOfClass:[AIEditorListGroup class]]) groups = YES;
        if([object isKindOfClass:[AIEditorListHandle class]]) handles = YES;
    }

    if(!(handles && groups)){
        [pboard declareTypes:[NSArray arrayWithObjects:@"AIContactObjects",nil] owner:self];

        //Build a list of all the highlighted objects
        if(dragItems) [dragItems release];
        dragItems = [items copy];

        //put it on the pasteboard
        [pboard setString:@"Private" forType:@"AIContactObjects"];

        return(YES);
    }else{
        return(NO);
    }
}

- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];

    if([avaliableType compare:@"AIContactObjects"] == 0){
        if([[dragItems objectAtIndex:0] isKindOfClass:[AIEditorListGroup class]] &&	//Dragging a group
        (item == nil)){								//Into the root level
            return(NSDragOperationPrivate);

        }else if([[dragItems objectAtIndex:0] isKindOfClass:[AIEditorListHandle class]] &&	//Dragging a handle
                (item != nil) &&								//Inside a group
                (index != -1 || [item isKindOfClass:[AIEditorListGroup class]]) &&		//Valid position, or onto a group
                ([dragItems indexOfObject:item] == NSNotFound)){				//Not dragged into itself
            return(NSDragOperationPrivate);
            
        }else{
            return(NSDragOperationNone);

        }
    }

    return(NSDragOperationNone);
}

- (BOOL)outlineView:(NSOutlineView*)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    NSString 		*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];
    
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

    [self refreshContentOutlineView]; //Refresh

    //Select all the groups and handles
    {
        NSEnumerator		*enumerator;
        AIEditorListObject	*object;

        [outlineView deselectAll:nil];
        enumerator = [dragItems objectEnumerator];
        while((object = [enumerator nextObject])){
            int row = [outlineView rowForItem:object];

            if(row != NSNotFound) [outlineView selectRow:row byExtendingSelection:YES];
        }
    }

    [dragItems release]; dragItems = nil;
    
    return(YES);
}

- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
    NSMutableDictionary	*groupStateDict = [[preferenceDict objectForKey:KEY_CONTACT_EDITOR_GROUP_STATE] mutableCopy];

    if(!groupStateDict) groupStateDict = [[NSMutableDictionary alloc] init];

    //Save the group new state
    [groupStateDict setObject:[NSNumber numberWithBool:state]
                        forKey:[NSString stringWithFormat:@"%@.%@", [selectedCollection UID], [item UID]]];

    [[owner preferenceController] setPreference:groupStateDict forKey:KEY_CONTACT_EDITOR_GROUP_STATE group:PREF_GROUP_CONTACT_LIST];
    [groupStateDict release];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
    NSMutableDictionary	*groupStateDict = [preferenceDict objectForKey:KEY_CONTACT_EDITOR_GROUP_STATE];
    NSNumber		*expandedNum;

    //Lookup the group's saved state
    expandedNum = [groupStateDict objectForKey:[NSString stringWithFormat:@"%@.%@", [selectedCollection UID], [item UID]]];

    //Correctly expand/collapse the group
    if(!expandedNum || [expandedNum boolValue] == YES){ //Default to expanded
        return(YES);
    }else{
        return(NO);
    }
}




// Toolbar actions
// ----------------------------------------
//Toggle the collection drawer
- (IBAction)toggleDrawer:(id)sender
{
    [drawer_sourceList toggle:nil];
}

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
    AIEditorListGroup	*newGroup;
    int			newRow;

    //Create the new group
    newGroup = [[AIEditorListGroup alloc] initWithUID:@"New Group" temporary:YES];
    [[selectedCollection list] addObject:newGroup];
    [self refreshContentOutlineView];

    //Select, scroll to, and edit the new group
    newRow = [outlineView_contactList rowForItem:newGroup];
    [outlineView_contactList selectRow:newRow byExtendingSelection:NO];
    [outlineView_contactList scrollRowToVisible:newRow];
    if([self outlineView:outlineView_contactList shouldEditTableColumn:[outlineView_contactList tableColumnWithIdentifier:@"handle"] item:newGroup]){
        [outlineView_contactList editColumn:[outlineView_contactList indexOfTableColumnWithIdentifier:@"handle"] row:newRow withEvent:nil select:YES];
    }
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

//Import contacts from a .blt file
- (IBAction)import:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel 
            beginSheetForDirectory:[[NSString stringWithString:@"~/Documents/"] stringByExpandingTildeInPath]
            file:nil
            types:[NSArray arrayWithObject:@"blt"]
            modalForWindow:[self window]
            modalDelegate:self
            didEndSelector:@selector(concludeImportPanel:returnCode:contextInfo:)
            contextInfo:nil];
}

//Finish up the importing panel
- (void)concludeImportPanel:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSEnumerator *enumerator = [collectionsArray objectEnumerator];
    id anObject;
    int index = 0;
    AIEditorImportCollection *defaultCollection = [AIEditorImportCollection editorCollection];
        
    if(returnCode == NSOKButton)
    {
        while (anObject = [enumerator nextObject])
        {
            if([anObject isMemberOfClass:[AIEditorImportCollection class]])
            {
                if([[anObject name] isEqual:[defaultCollection name]])//if it's empty..
                {
                    [collectionsArray replaceObjectAtIndex:index 
                        withObject:[AIEditorImportCollection editorCollectionWithPath:
                            [[panel filenames] objectAtIndex:0]]];
                            //...replace it
                }
                else //it's been added to already
                {
                    [anObject importAndAppendContactsFromPath:[[panel filenames] objectAtIndex:0]];
                    //so append 
                }
                //we want to do these things regardless
                selectedCollection = [collectionsArray objectAtIndex:index]; //select it
                [tableView_sourceList selectRow:index byExtendingSelection:NO]; //highlight it
                
                break; //and get out!
            }
            else //otherwise
                ++index; //move on
        }
        [self refreshContentOutlineView]; //refresh
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
                                    withIdentifier:@"Import"
                                             label:@"Import"
                                      paletteLabel:@"Import"
                                           toolTip:@"Load buddies from a .blt file"
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"addHandle" forClass:[self class]]
                                            action:@selector(import:)
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

    [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:@"ToggleDrawer"
                                             label:@"ToggleDrawer"
                                      paletteLabel:@"ToggleDrawer"
                                           toolTip:@"ToggleDrawer"
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"AccountLarge" forClass:[self class]]
                                            action:@selector(toggleDrawer:)
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
    return [NSArray arrayWithObjects:@"Group",@"Handle",NSToolbarSeparatorItemIdentifier,@"Delete",@"Import",NSToolbarFlexibleSpaceItemIdentifier,@"Inspector",nil];
}

//Return a list of allowed toolbar items
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Group",@"Handle",@"Delete",@"Import",@"Inspector",@"ToggleDrawer",NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,nil];
}

@end

