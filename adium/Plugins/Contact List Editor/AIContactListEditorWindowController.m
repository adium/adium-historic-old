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
#import "AISCLEditHeaderView.h"

#define CONTACT_LIST_EDITOR_NIB			@"ContactListEditorWindow"
#define	HANDLE_DELETE_KEY			@"Handles"
#define	PREF_GROUP_DELETE_KEY			@"Groups"
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
    owner = [inOwner retain];

    [super initWithWindowNibName:windowNibName owner:self];
    
    //Install observers
    [[[owner contactController] contactNotificationCenter] addObserver:self selector:@selector(contactListChanged:) name:Contact_ListChanged object:nil];
    [[[owner contactController] contactNotificationCenter] addObserver:self selector:@selector(contactChanged:) name:Contact_ObjectChanged object:nil];
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];

    folderImage = [[AIImageUtilities imageNamed:@"Folder" forClass:[self class]] retain];

    //Fetch the contact list
    contactList = [[[owner contactController] contactList] retain];
    editor = nil;
    editedObject = nil;
    
    return(self);
}

- (void)dealloc
{
    [owner release];
    [folderImage release];
    [contactList release];
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

    //Install our custom outline view cell
    newCell = [[[AIImageTextCell alloc] init] autorelease];    
    [[[outlineView_contactList tableColumns] objectAtIndex:0] setDataCell:newCell];
    
    //Setup the window and outline view
    [outlineView_contactList setAutoresizesOutlineColumn:NO];
    [outlineView_contactList setIndentationPerLevel:10];
    
    [outlineView_contactList setBackgroundColor:[NSColor colorWithCalibratedRed:(250.0/255.0) green:(250.0/255.0) blue:(250.0/255.0) alpha:1.0]];
    [outlineView_contactList setDrawsAlternatingRows:YES];
    [outlineView_contactList setAlternatingRowColor:[NSColor colorWithCalibratedRed:(231.0/255.0) green:(243.0/255.0) blue:(255.0/255.0) alpha:1.0]];

    [outlineView_contactList setDrawsAlternatingColumns:YES];
    [outlineView_contactList setAlternatingColumnColor:[NSColor colorWithCalibratedRed:(231.0/255.0) green:(243.0/255.0) blue:(255.0/255.0) alpha:1.0]];
    [outlineView_contactList setSecondaryAlternatingColumnColor:[NSColor colorWithCalibratedRed:(204.0/255.0) green:(230.0/255.0) blue:(255.0/255.0) alpha:1.0]];

    [self installToolbar];
    [self buildAccountColumns];
    [outlineView_contactList registerForDraggedTypes:[NSArray arrayWithObject:@"AIContactObjects"]];

    [outlineView_contactList setNeedsDisplay:YES];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    return(YES);
}

//Build the outline view's account columns
- (void)buildAccountColumns
{
    NSArray	*columns;
    NSArray	*accountArray;
    int		loop;
    int		target;

    //Remove any current columns from the editor
    target = 0;
    columns = [outlineView_contactList tableColumns];
    while([columns count] > 2/* && target < [subviewArray count]*/){
        if([[[columns objectAtIndex:target] identifier] isKindOfClass:[AIAccount class]]){
            [outlineView_contactList removeTableColumn:[columns objectAtIndex:target]];
        }else{
            target++;
        }
    }
    
    [[columns objectAtIndex:0] setWidth:MAIN_COLUMN_WIDTH];
    [[columns objectAtIndex:1] setWidth:ALIAS_COLUMN_WIDTH];

    //Add a column for each account
    accountArray = [[owner accountController] accountArray];
    for(loop = 0;loop < [accountArray count];loop++){
        AIAccount		*account = [accountArray objectAtIndex:loop];
        NSTableColumn		*newColumn = [[[NSTableColumn alloc] init] autorelease];
        AIContactListCheckbox	*checkBox = [[[AIContactListCheckbox alloc] init] autorelease];
        
        //Table column
        [checkBox setBordered:NO];
        [newColumn setWidth:SUB_COLUMN_WIDTH];
        [newColumn setIdentifier:account];
        [newColumn setDataCell:checkBox];
        [[newColumn headerCell] setStringValue:[account accountDescription]];

        [outlineView_contactList addTableColumn:newColumn];
        [outlineView_contactList moveColumn:[outlineView_contactList numberOfColumns]-1 toColumn:[outlineView_contactList numberOfColumns]-3];
    }
    
    [outlineView_contactList setAlternatingColumnRange:NSMakeRange(0,[accountArray count]) ];
    [outlineView_contactList setFirstColumnColored:([accountArray count] % 2)];
    [outlineView_contactList sizeLastColumnToFit];

    //Configure our header
    [customView_tableHeader configureForAccounts:accountArray view:outlineView_contactList];
}

//Notified when the account list changes
- (void)accountListChanged:(NSNotification *)notification
{
    //Rebuild the account columns
    [self buildAccountColumns];
}

//Notified when the contact list changes
- (void)contactListChanged:(NSNotification *)notification
{
    //Fetch the new contact list
    [contactList release]; contactList = [[[owner contactController] contactList] retain];

    //Redisplay
    [outlineView_contactList reloadData];
}

//Notified when a contact changes
- (void)contactChanged:(NSNotification *)notification
{
    //refresh the outline view
    [outlineView_contactList reloadData];
}


// Outline View ---------------------------------------------------------------------------------
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([contactList objectAtIndex:index]);    
    }else{
        return([item objectAtIndex:index]);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    //Only allow expanding of non-dynamic groups    
    if([item isKindOfClass:[AIContactGroup class]] && ![[item displayArrayForKey:@"Dynamic"] containsAnyIntegerValueOf:1]){
        return(YES);
    }else{
        return(NO);
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
        return([contactList count]);
    }else{
        return([item count]);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if([[tableColumn identifier] isKindOfClass:[AIAccount class]]){

        if(![item isKindOfClass:[AIContactGroup class]]){
            if([item belongsToAccount:[tableColumn identifier]]){
                return([NSNumber numberWithInt:NSOnState]);
            }else{
                return([NSNumber numberWithInt:NSOffState]);
            }
        }else{
            int	result = [item belongsToAccount:[tableColumn identifier]];

            return([NSNumber numberWithInt:result]);
        }
    }else{
        return([item UID]);
    }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if([[tableColumn identifier] isKindOfClass:[AIAccount class]]){
        AIAccount	*account = [tableColumn identifier];

        if( [account conformsToProtocol:@protocol(AIAccount_Contacts)]){
            [cell setEnabled:[(AIAccount <AIAccount_Contacts> *)account contactListEditable]];
        
        }else if([account conformsToProtocol:@protocol(AIAccount_GroupedContacts)]){
            [cell setEnabled:[(AIAccount <AIAccount_GroupedContacts> *)account contactListEditable]];

        }else{
            [cell setEnabled:NO];        

        }
        
    }else{
        if([item isKindOfClass:[AIContactGroup class]]){
            [cell setImage:folderImage];
        }else{
            [cell setImage:nil];
// temporarily off [cell setImage: [[(AIContactHandle *)item service] image]];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
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
            
        }

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


// Toolbar actions --------------------------------------------------------------------------
- (IBAction)inspect:(id)sender
{
    [[owner contactController] showInfoForContact:[outlineView_contactList itemAtRow:[outlineView_contactList selectedRow]]];
}

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

        if([object isMemberOfClass:[AIContactHandle class]]){
            numHandles++;
            [handles addObject:object];
        }else{
            if([object count] != 0){
                numGroups++;
            }
            [groups addObject:object];
        }
    }
    contextInfo = [[NSDictionary dictionaryWithObjectsAndKeys:handles, HANDLE_DELETE_KEY, groups, PREF_GROUP_DELETE_KEY, nil] retain];
  
    //confirm for mass amounts of deleting
    if(numGroups != 0 && numHandles > 1){
        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i group%@ and %i handle%@ from your list?", numGroups, (numGroups != 1) ? @"s" : @"", numHandles, (numHandles != 1) ? @"s" : @""], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Be careful, you cannot undo this action.");

    }else if(numGroups != 0){
        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i group%@ from your list?", numGroups, (numGroups != 1) ? @"s" : @""], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Any handles in %@ will be deleted.  Be careful, you cannot undo this action.", (numGroups != 1) ? @"these groups" : @"this group");

    }else if(numHandles > 1){
        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i handle%@ from your list?", numHandles, (numHandles != 1) ? @"s" : @""], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Be careful, you cannot undo this action.");
    }else{ //for single handle and empty group deletes, we don't prompt the user
        [self concludeDeleteSheet:nil returnCode:NSAlertDefaultReturn contextInfo:contextInfo];
    }

    //De-select everything
    [outlineView_contactList deselectAll:nil];
}

- (void)concludeDeleteSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSDictionary	*targetDict = contextInfo;
    NSEnumerator 	*enumerator;
    id			object;

    if(returnCode == NSAlertDefaultReturn){
        NSArray		*handles = [targetDict objectForKey:HANDLE_DELETE_KEY];
        NSArray		*groups = [targetDict objectForKey:PREF_GROUP_DELETE_KEY];
    
        //delete the selected handles first
        enumerator = [handles objectEnumerator];
        while(object = [enumerator nextObject]){
            [[owner contactController] deleteObject:object];
        }
        
        //then delete the selected groups
        enumerator = [groups objectEnumerator];
        while(object = [enumerator nextObject]){
            [[owner contactController] deleteObject:object];
        }
    }
    
    [targetDict release];
}

- (IBAction)group:(id)sender
{
    id			selectedItem;
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
    
}

- (IBAction)handle:(id)sender
{
    AIAccount		*account;
    AIContactHandle	*newHandle;
    int			newRow;
    id			selectedItem;
    id			selectedGroup;

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

    //Create the new handle
    account = [[[owner accountController] accountArray] objectAtIndex:0];
    newHandle = [[owner contactController] createHandleWithService:[[account service] handleServiceType] UID:@"screenName" inGroup:selectedGroup forAccount:nil];
    
    //Select, scroll to, and edit the new handle
    newRow = [outlineView_contactList rowForItem:newHandle];
    [outlineView_contactList selectRow:newRow byExtendingSelection:NO];
    [outlineView_contactList scrollRowToVisible:newRow];
    [self outlineView:outlineView_contactList shouldEditTableColumn:[outlineView_contactList tableColumnWithIdentifier:@"handle"] item:newHandle];
}


// Window toolbar ------------------------------------------------------------------
- (void)installToolbar
{
    //--setup our toolbar--
    NSToolbar *toolbar;

    toolbar = [[[NSToolbar alloc] initWithIdentifier:@"UserSelectionPanel"] autorelease];
    toolbarItems = [[NSMutableDictionary dictionary] retain];

    //--add the items--
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

    //--configure the toolbar--
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];

    //--install it--
    [[self window] setToolbar:toolbar];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    // You could check [theItem itemIdentifier] here and take appropriate action if you wanted to
    return YES;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Group",@"Handle",NSToolbarSeparatorItemIdentifier,@"Delete",NSToolbarFlexibleSpaceItemIdentifier,@"Inspector",nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Group",@"Handle",@"Delete",@"Inspector",NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,nil];
}

@end
