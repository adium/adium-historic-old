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

#import "AIContactListEditorWindowController.h"
#import "AIContactListCheckbox.h"
#import "AIEditorListGroup.h"
#import "AIEditorListHandle.h"
#import "AIEditorCollection.h"
#import "AIContactListEditorPlugin.h"
#import "AIEditorImportCollection.h"
#import "AIListEditorCell.h"
#import "AIBrowser.h"
#import "AINewContactWindowController.h"

#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define CONTACT_LIST_EDITOR_NIB			@"ContactListEditorWindow"
#define	HANDLE_DELETE_KEY			@"Handles"
#define	GROUP_DELETE_KEY			@"Groups"
#define KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME	@"Contact List Editor Frame"
#define KEY_CONTACT_EDITOR_GROUP_STATE		@"Contact Editor Group State"	//Expand/Collapse state of groups

#define CHECK_COLUMN_WIDTH			13
#define INDEX_COLUMN_WIDTH			24
#define INDEX_COLUMN_IDENTIFIER			@"index"

@interface AIContactListEditorWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(AIContactListEditorPlugin *)inPlugin;
//- (int)_collectionsRequestingOwnership;
//- (void)_sizeContentColumnsToFit:(NSNotification *)notification;
- (void)installToolbar;
//- (IBAction)toggleDrawer:(id)sender;
//- (void)configureForCollection:(AIEditorCollection *)collection;
//- (IBAction)delete:(id)sender;
//- (void)concludeDeleteSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
//- (int)allHandlesInGroup:(AIEditorListGroup *)group belongToCollection:(AIEditorCollection *)collection;
//- (int)selectedIndexAndGroup:(AIEditorListGroup **)group;
//- (void)scrollToAndEditObject:(id)object column:(NSTableColumn *)column;
//- (void)collectionArrayChanged:(NSNotification *)notification;
//- (void)_configureContactListView;
//- (void)endEditing;
//- (void)_configureSourceView;
//- (void)_reflectHighlightedColumn:(NSTableColumn *)tableColumn;
@end

@implementation AIContactListEditorWindowController

//Create and return a contact list editor window controller
static AIContactListEditorWindowController *sharedInstance = nil;
+ (id)contactListEditorWindowControllerForPlugin:(AIContactListEditorPlugin *)inPlugin
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_LIST_EDITOR_NIB plugin:inPlugin];
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
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(AIContactListEditorPlugin *)inPlugin
{
    //init
    plugin = inPlugin;
//    selectedCollection = nil;
//    selectedColumn = nil;
    [super initWithWindowNibName:windowNibName];
	
	
	NSEnumerator				*enumerator;
	id <AIServiceController>	service;
	
	//get our service images
	serviceImageDict = [[NSMutableDictionary alloc] init];
	enumerator = [[[adium accountController] availableServices] objectEnumerator];
	while(service = [enumerator nextObject]){
		AIServiceType	*serviceType = [service handleServiceType];
		NSImage			*image = [serviceType image];
		
		if(image){
			[serviceImageDict setObject:image forKey:[serviceType identifier]];
		}
	}
	
	groupImage = [[AIImageUtilities imageNamed:@"Folder" forClass:[self class]] retain];
	
    
    return(self);
}

- (void)dealloc
{
//    [toolbarItems release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    //Make the browser user our custom browser cell.
//    [browser_contactList setCellClass:[AIListEditorCell class]];
	
    //Tell the browser to send us messages when it is clicked.
	[browser_contactList setDataSource:self];
//    [browser_contactList setTarget: self];
//    [browser_contactList setAction: @selector(browserSingleClick:)];
//    [browser_contactList setDoubleAction: @selector(browserDoubleClick:)];
	
	//Observe list changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListChanged:)
									   name:Contact_ListChanged
									 object:nil];
	
	
	
	//    NSString				*savedFrame;
//
//    //Restore the window position
//    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME];
//    if(savedFrame){
//        [[self window] setFrameFromString:savedFrame];
//    }else{
//        [[self window] center];
//    }
//
//    [button_import setTitle:@"Import"];
//    
//    //Observe Collection changes
//    [[adium notificationCenter] addObserver:self selector:@selector(collectionStatusChanged:) name:Editor_CollectionStatusChanged object:nil];
//    [[adium notificationCenter] addObserver:self selector:@selector(collectionArrayChanged:) name:Editor_CollectionArrayChanged object:nil];
//    [[adium notificationCenter] addObserver:self selector:@selector(collectionContentChanged:) name:Editor_CollectionContentChanged object:nil];
//
//    //Configure our views
//    [self _configureContactListView];
//    [self _configureSourceView];
//    
//    //Install our window toolbar and generate our collections
    [self installToolbar];
//    [self collectionArrayChanged:nil];
}

- (void)contactListChanged:(NSNotification *)notification
{	
	[browser_contactList reloadData];	
}




//
//- (void)_configureContactListView
//{
//    //Observe frame changes to correctly size our outline view columns
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sizeContentColumnsToFit:) name:NSViewFrameDidChangeNotification object:outlineView_contactList];
//    [outlineView_contactList setAutoresizesOutlineColumn:NO];
//
//    //Content view colors and alternating rows
//    [outlineView_contactList setBackgroundColor:[NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0]];
//    [outlineView_contactList setDrawsAlternatingRows:YES];
//    [outlineView_contactList setNeedsDisplay:YES];
//    [outlineView_contactList setDrawsGrid:YES];
//    [outlineView_contactList setGridColor:[NSColor colorWithCalibratedRed:(217.0/255.0) green:(217.0/255.0) blue:(217.0/255.0) alpha:0.7]];
//
//    //
//    [button_newHandle setImage:[AIImageUtilities imageNamed:@"addHandle" forClass:[self class]]];
//    [button_newGroup setImage:[AIImageUtilities imageNamed:@"addGroup" forClass:[self class]]];
//    [button_newHandle setTitle:@""];
//    [button_newGroup setTitle:@""];
//    
//    //Listen to contact dragging
//    [outlineView_contactList registerForDraggedTypes:[NSArray arrayWithObject:@"AIContactObjects"]];
//
//    //Create and configure our index column
//    indexColumn = [[NSTableColumn alloc] initWithIdentifier:INDEX_COLUMN_IDENTIFIER];
//    [indexColumn setDataCell:[[[[outlineView_contactList outlineTableColumn] dataCell] copy] autorelease]];
//    [[indexColumn dataCell] setAlignment:NSRightTextAlignment];
//    [[indexColumn headerCell] setStringValue:@""];
//    [indexColumn setWidth:INDEX_COLUMN_WIDTH];
//    [indexColumn setMinWidth:INDEX_COLUMN_WIDTH];
//    [indexColumn setMaxWidth:INDEX_COLUMN_WIDTH];
//
//}
//
//- (void)_configureSourceView
//{
//    AIImageTextCell			*newCell;
//
//    //Setup the custom image/text cell
//    newCell = [[[AIImageTextCell alloc] init] autorelease];
//    [[[tableView_sourceList tableColumns] objectAtIndex:0] setDataCell:newCell];
//
//    //Configure the scrollview/scrollbar hiding
//    [scrollView_sourceList setAutoScrollToBottom:NO];
//    [scrollView_sourceList setAutoHideScrollBar:YES];
//
//    //Listen to contact dragging
//    [tableView_sourceList registerForDraggedTypes:[NSArray arrayWithObject:@"AIContactObjects"]];
//    
//}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

////Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [[adium notificationCenter] removeObserver:self];
//
//    //Save the window position
//    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
//                                         forKey:KEY_CONTACT_LIST_EDITOR_WINDOW_FRAME
//                                          group:PREF_GROUP_WINDOW_POSITIONS];
//
//    [sharedInstance autorelease]; sharedInstance = nil;
//    
    return(YES);
}
//
- (BOOL)shouldCascadeWindows
{
    return(NO);
}
//
//
//// Content modified notifications
//// --------------------------------------------------
////A collection's content has changed
//- (void)collectionContentChanged:(NSNotification *)notification
//{
//    AIEditorCollection	*collection = [notification object];
//    
//    //Resort the collection
//    [collection sortUsingMode:[collection sortMode]];
//    
//    //Redisplay the content view
//    [outlineView_contactList reloadData];
//}
//
////A collection's status has changed
//- (void)collectionStatusChanged:(NSNotification *)notification
//{
//    [tableView_sourceList reloadData]; //Redisplay our collection view
//}
//
////The collection array has changed
//- (void)collectionArrayChanged:(NSNotification *)notification
//{
//    [tableView_sourceList reloadData]; //Redisplay our collection view
//
//    selectedCollection = nil;
//    [self tableViewSelectionIsChanging:nil]; //Update the content view
//
//    //If the user has multiple collections, open the drawer
//    if([[plugin collectionsArray] count] > 2){
//        [drawer_sourceList open:nil];
//    }
//}


// Collections table view
// --------------------------------------------------
//As the selection changes, update the outline view to reflect the selected collection
//- (void)tableViewSelectionIsChanging:(NSNotification *)notification
//{
//    if(notification == nil || [notification object] == tableView_sourceList){
//        int			selectedRow;
//
//        //Ensure a valid selection
//        selectedRow = [tableView_sourceList selectedRow];
//        if(selectedRow < 0 || selectedRow >= [tableView_sourceList numberOfRows]) selectedRow = 0; 
//
//        //Configure the outline view for the new selection
//        selectedCollection = [[plugin collectionsArray] objectAtIndex:selectedRow];
//        [self configureForCollection:selectedCollection];
//
//        //Notify
//        [[adium notificationCenter] postNotificationName:Editor_ActiveCollectionChanged object:selectedCollection];
//
//        //Give first responder to outline view, and select its first row
//        [[self window] makeFirstResponder:outlineView_contactList];
//        [outlineView_contactList selectRow:0 byExtendingSelection:NO];
//    }
//}
//
////Configure the editor for the specified collection
//- (void)configureForCollection:(AIEditorCollection *)collection
//{
//    NSEnumerator			*enumerator;
//    id <AIListEditorColumnController>	columnController;
//    AIEditorCollection 			*object;
//
//    //Update the window title
//    [[self window] setTitle:[collection collectionDescription]];
//
//    //Remove all the table columns (Except for the name column)
//    while([outlineView_contactList numberOfColumns] > 1){
//        NSTableColumn	*column = [[outlineView_contactList tableColumns] objectAtIndex:0];
//
//        if(column == [outlineView_contactList outlineTableColumn]){
//            [outlineView_contactList removeTableColumn:[[outlineView_contactList tableColumns] objectAtIndex:1]];
//        }else{
//            [outlineView_contactList removeTableColumn:column];
//        }
//    }
//
//    //Add the index column
//    if([collection showIndexColumn]){
//        [outlineView_contactList addTableColumn:indexColumn];
//        [outlineView_contactList moveColumn:0 toColumn:1]; //Move the name column back to the left
//    }
//
//    //Custom list editor columns
//    if([collection showCustomEditorColumns]){
//        enumerator = [[plugin listEditorColumnControllers] objectEnumerator];
//        while((columnController = [enumerator nextObject])){
//            NSTableColumn	*tableColumn = [[NSTableColumn alloc] initWithIdentifier:columnController];
//            
//            [tableColumn setDataCell:[[[[outlineView_contactList outlineTableColumn] dataCell] copy] autorelease]];
//            [[tableColumn headerCell] setStringValue:[columnController editorColumnLabel]];
//            [tableColumn setWidth:140];
//            [tableColumn setMinWidth:40];
//            [tableColumn setMaxWidth:1000];
//            [tableColumn setEditable:YES];
//
//            [outlineView_contactList addTableColumn:tableColumn];
//        }
//    }
//
//    //Add the ownership columns
//    if([collection showOwnershipColumns]){ //If this collection requests display of the ownership column
//        //We don't display the ownership column unless there are two or more collections that request it.
//        if([self _collectionsRequestingOwnership] >= 2){
//            //Add a column for all collections that want one
//            enumerator = [[plugin collectionsArray] objectEnumerator];
//            while((object = [enumerator nextObject])){
//                if([object includeInOwnershipColumn] && [object enabled]){
//                    NSTableColumn	*tableColumn = [[[NSTableColumn alloc] initWithIdentifier:object] autorelease];
//
//                    [tableColumn setDataCell:[[[AIContactListCheckbox alloc] init] autorelease]];
//                    [[tableColumn headerCell] setStringValue:[object name]];
//                    [tableColumn setWidth:CHECK_COLUMN_WIDTH];
//                    [tableColumn setMinWidth:CHECK_COLUMN_WIDTH];
//                    [tableColumn setMaxWidth:CHECK_COLUMN_WIDTH];
//                
//                    [outlineView_contactList addTableColumn:tableColumn];
//                }
//            }
//        }
//    }
//
//    //Highlight the correct column
//    switch([collection sortMode]){
//        case AISortByName:
//            [self _reflectHighlightedColumn:[outlineView_contactList tableColumnWithIdentifier:@"handle"]];
//        break;
//        case AISortByIndex:
//            [self _reflectHighlightedColumn:[outlineView_contactList tableColumnWithIdentifier:@"index"]];
//        break;
//        default:
//        break;
//    }    
//    
//    //Redraw the content outline view
//    [outlineView_contactList reloadData];
//
//    //Set the columns to the correct width
//    [self _sizeContentColumnsToFit:nil];
//}
//

// Collection Table View Delegate ---------------------------------------------------------
//- (int)numberOfRowsInTableView:(NSTableView *)tableView
//{
//    return([[plugin collectionsArray] count]);
//}
//
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
//{
//    AIEditorCollection	*collection = [[plugin collectionsArray] objectAtIndex:row];
//
//    return([collection name]); //Ignored by our cell
//}
//
//- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
//{
//    AIEditorCollection	*collection = [[plugin collectionsArray] objectAtIndex:row];
//
//    [cell setEnabled:[collection enabled]];
//    [cell setStringValue:[collection name]];    
//    [cell setImage:[collection icon]]; //Set the correct account icon
//}
//
//- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
//{
//    if(op == NSTableViewDropOn){
//        if([tableView selectedRow] != row){
//            [tableView selectRow:row byExtendingSelection:NO];
//            [self tableViewSelectionIsChanging:nil];
//        }
//    }
//
//    return(NSDragOperationNone);
//}
//
//
//// Contact Outline View Delegate ---------------------------------------------------------
////
//- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)outlineView
//{
//    [self delete:nil]; //Delete them
//}
//
//- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
//{
//    if(item == nil){
//        return([[selectedCollection list] objectAtIndex:index]);
//    }else{
//        return([item handleAtIndex:index]);
//    }
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
//{
//    if([item isKindOfClass:[AIEditorListGroup class]]){ //Only allow expanding of groups
//        return(YES);
//    }else{
//        return(NO);
//    }
//}
//
//- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
//{
//    if(item == nil){
//        return([[selectedCollection list] count]);
//    }else{
//        return([item count]);
//    }
//}
//
//- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
//{
//    id		identifier = [tableColumn identifier];
//    id		value = nil;
//
//    if([identifier isKindOfClass:[NSString class]]){
//        if([(NSString *)identifier compare:@"handle"] == 0){
//            value = [item UID];
//            
//        }else if([(NSString *)identifier compare:@"index"] == 0){
//            value = [NSString stringWithFormat:@"%i",[outlineView rowForItem:item]+1];
////            value = [NSString stringWithFormat:@"%2.4f",[item orderIndex]];
//        }
//
//    }else if([identifier isKindOfClass:[AIEditorCollection class]]){
//        //Return the correct checkbox state
//        if([item isKindOfClass:[AIEditorListHandle class]]){
//            value = [NSNumber numberWithInt:[identifier containsHandleWithUID:[item UID]]];
//
//        }else if([item isKindOfClass:[AIEditorListGroup class]]){
//            value = [NSNumber numberWithInt:[self allHandlesInGroup:item belongToCollection:identifier]];
//
//        }
//        
//    }else if([identifier conformsToProtocol:@protocol(AIListEditorColumnController)]){
//        if([item isKindOfClass:[AIEditorListHandle class]]){
//            value = [(id <AIListEditorColumnController>)identifier editorColumnStringForServiceID:[(AIEditorListHandle *)item serviceID] UID:[item UID]];
//        }
//    }
//
//    return(value);
//}
//
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
//{
//    id		identifier = [tableColumn identifier];
//
//    //When the item only remains on one collection, we disable the checkbox corresponding to that collection
//    if([identifier isKindOfClass:[AIEditorCollection class]]){
//        if([identifier enabled]){
//            if([item isKindOfClass:[AIEditorListHandle class]]){
//                BOOL			enabled = YES;
//
//                //If this box is checked
//                if([identifier containsHandleWithUID:[item UID]]){
//                    NSEnumerator		*enumerator;
//                    AIEditorCollection		*column;
//
//                    //Scan the other boxes
//                    enabled = NO;
//                    enumerator = [[plugin collectionsArray] objectEnumerator];
//                    while((column = [enumerator nextObject])){
//                        if(column != identifier && [column includeInOwnershipColumn] && [column containsHandleWithUID:[item UID]]){
//                            //Once we find another checked checkbox, we can enable this one, and stop searching
//                            enabled = YES;
//                            break;
//                        }
//                    }
//                }
//
//                [cell setEnabled:enabled];
//            }else{
//                [cell setEnabled:NO];
//            }
//        }else{
//            [cell setEnabled:NO];
//        }
//    }
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
//{
//    return(YES);
//}
//
//- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
//{
//    id		identifier = [tableColumn identifier];
//
//    if([identifier isKindOfClass:[NSString class]] && [(NSString *)identifier compare:@"handle"] == 0){ //Handle/Group name column
//        if([item isKindOfClass:[AIEditorListHandle class]]){
//            [selectedCollection renameHandle:item to:object];
//
//        }else if([item isKindOfClass:[AIEditorListGroup class]]){
//            [selectedCollection renameGroup:item to:object];
//            
//        }
//
//    }else if([identifier isKindOfClass:[AIEditorCollection class]]){
//        AIEditorCollection	*collection = identifier;
//        AIEditorListHandle	*handle = (AIEditorListHandle *)item;
//       
//        if([object intValue]){ //Add
//            NSString		*groupName;
//            AIEditorListGroup	*group;
//
//            //Get the containing group
//            groupName = [[handle containingGroup] UID];
//            group = [collection addGroupNamed:groupName temporary:NO];
//
//            //Add the handle
//            [collection addHandleNamed:[handle UID] inGroup:group index:0 temporary:NO];
//
//        }else{ //Remove
//            [collection deleteHandle:[collection handleWithUID:[handle UID]]];
//
//        }
//
//    }else if([identifier conformsToProtocol:@protocol(AIListEditorColumnController)]){ //custom column
//        //Pass the new value to the column controller
//        if([item isKindOfClass:[AIEditorListHandle class]]){
//            [(id <AIListEditorColumnController>)identifier editorColumnSetStringValue:object forServiceID:[(AIEditorListHandle *)item serviceID] UID:[(AIEditorListHandle *)item UID]];
//        }
//    }
//
//    //Refresh
//    [outlineView_contactList reloadData];        
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
//{
//    NSEnumerator	*enumerator;
//    id			object;
//    BOOL		handles = NO, groups = NO;
//
//    //We either drag all handles, or all groups.  A mix of the two is not allowed
//    enumerator = [items objectEnumerator];
//    while((object = [enumerator nextObject]) && !(handles && groups)){
//        if([object isKindOfClass:[AIEditorListGroup class]]) groups = YES;
//        if([object isKindOfClass:[AIEditorListHandle class]]) handles = YES;
//    }
//
//    if(!(handles && groups)){
//        [pboard declareTypes:[NSArray arrayWithObjects:@"AIContactObjects",nil] owner:self];
//
//        //Build a list of all the highlighted objects
//        if(dragItems) [dragItems release];
//        dragItems = [items copy];
//        dragSourceCollection = selectedCollection;
//
//        //put it on the pasteboard
//        [pboard setString:@"Private" forType:@"AIContactObjects"];
//
//        return(YES);
//    }else{
//        return(NO);
//    }
//}
//
//- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
//{
//    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];
//
//    if([avaliableType compare:@"AIContactObjects"] == 0){
//        if([[dragItems objectAtIndex:0] isKindOfClass:[AIEditorListGroup class]] &&	//Dragging a group
//           ([selectedCollection sortMode] == AISortByIndex)){				//List is sorted by index
//
//            //If the group is being hovered over a group or within a group, refocus them below the group
//            if(item != nil){
//                [outlineView setDropItem:nil dropChildIndex:[[selectedCollection list] indexOfObject:item] + 1];
//            }
//            
//            return(NSDragOperationPrivate);	//Valid Drop
//
//        }else if(([[dragItems objectAtIndex:0] isKindOfClass:[AIEditorListHandle class]]) &&	//Dragging a handle
//                 (item != nil) &&								//Drag to inside a group
//                 ([item isKindOfClass:[AIEditorListGroup class]])/* &&				//Not dragging onto a handle
//                 ([dragItems indexOfObject:item] == NSNotFound))*/){				//Not dragged into itself
//            
//            //If Collection is alphabetized & user is dropping into a group, refocus them onto the containing group
//            if([selectedCollection sortMode] != AISortByIndex && index != -1){		
//                [outlineView setDropItem:item dropChildIndex:-1];
//            }
//
//            return(NSDragOperationPrivate); 	//Valid Drop
//    
//        }else{
//            return(NSDragOperationNone);	//Invalid Drop
//            
//        }
//    }
//
//    return(NSDragOperationNone);
//}
//
////Testing this out...  It isn't going to work well without several different hacks to the outline view :\ .. Have to live w/ autoexpanding for now.
///*- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
//{
//    //If we are in a drag (And not sorted manually), return NO so the outline view doesn't automatically expand our items
//    if(dragItems &&
//       (([[dragItems objectAtIndex:0] isKindOfClass:[AIEditorListHandle class]] && [selectedCollection sortMode] != AISortByIndex) ||
//        [[dragItems objectAtIndex:0] isKindOfClass:[AIEditorListGroup class]])){
//        return(NO);
//    }else{
//        return(YES);
//    }
//}*/
//
//- (BOOL)outlineView:(NSOutlineView*)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
//{
//    NSString 		*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIContactObjects"]];
//    
//    if([availableType compare:@"AIContactObjects"] == 0){
//        NSEnumerator		*enumerator;
//        AIEditorListHandle	*handle;
//        AIEditorListGroup	*group;
//
//        //Move the groups first
//        enumerator = [dragItems objectEnumerator];
//        while((group = [enumerator nextObject])){
//            if([group isKindOfClass:[AIEditorListGroup class]]){
//                [dragSourceCollection moveGroup:group toIndex:index];
//            }
//        }
//
//        //Then move the handles
//        enumerator = [dragItems objectEnumerator];
//        while((handle = [enumerator nextObject])){
//            if([handle isKindOfClass:[AIEditorListHandle class]]){
//                [handle retain]; //Temporarily hold onto the handle
//
//                if(dragSourceCollection == selectedCollection){
//                    //Move within the collection
//                    [dragSourceCollection moveHandle:handle toGroup:item index:index];
//                    
//                }else{
//                    //Remove from the source collection
//                    [dragSourceCollection deleteHandle:handle];
//
//                    //Add to the dest collection
//                    [selectedCollection addHandleNamed:[handle UID] inGroup:item index:index temporary:NO];
//                }
//                
//                [handle release];
//            }
//        }
//    }
//
//    [outlineView_contactList reloadData]; //Refresh
//
//    //Select all the groups and handles
//    {
//        NSEnumerator	*enumerator;
//        id		object;
//
//        [outlineView deselectAll:nil];
//        enumerator = [dragItems objectEnumerator];
//        while((object = [enumerator nextObject])){
//            int row = [outlineView rowForItem:object];
//            if(row != NSNotFound) [outlineView selectRow:row byExtendingSelection:YES];
//        }
//    }
//
//    [dragItems release]; dragItems = nil;
//    
//    return(YES);
//}
//
//- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
//{
//    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
//    NSMutableDictionary	*groupStateDict = [[preferenceDict objectForKey:KEY_CONTACT_EDITOR_GROUP_STATE] mutableCopy];
//
//    if(!groupStateDict) groupStateDict = [[NSMutableDictionary alloc] init];
//
//    //Save the group new state
//    [groupStateDict setObject:[NSNumber numberWithBool:state]
//                        forKey:[NSString stringWithFormat:@"%@.%@", [selectedCollection UID], [item UID]]];
//
//    [[adium preferenceController] setPreference:groupStateDict forKey:KEY_CONTACT_EDITOR_GROUP_STATE group:PREF_GROUP_CONTACT_LIST];
//    [groupStateDict release];
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
//{
//    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
//    NSMutableDictionary	*groupStateDict = [preferenceDict objectForKey:KEY_CONTACT_EDITOR_GROUP_STATE];
//    NSNumber		*expandedNum;
//
//    //Lookup the group's saved state
//    expandedNum = [groupStateDict objectForKey:[NSString stringWithFormat:@"%@.%@", [selectedCollection UID], [item UID]]];
//
//    //Correctly expand/collapse the group
//    if(!expandedNum || [expandedNum boolValue] == YES){ //Default to expanded
//        return(YES);
//    }else{
//        return(NO);
//    }
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectTableColumn:(NSTableColumn *)tableColumn
//{
//    //Reflect the selection
//    [self _reflectHighlightedColumn:tableColumn];
//
//    //Sort & Reload
//    {
//        id	identifier = [selectedColumn identifier];
//        
//        if([identifier isKindOfClass:[NSString class]]){ //Name/Index
//
//            if([(NSString *)identifier compare:@"handle"] == 0){
//                [selectedCollection sortUsingMode:AISortByName];
//                
//            }else if([(NSString *)identifier compare:@"index"] == 0){
//                [selectedCollection sortUsingMode:AISortByIndex];
//
//            }            
//
//        }else if([identifier isKindOfClass:[AIEditorCollection class]]){ //Ownership
//            
//        }else if([identifier conformsToProtocol:@protocol(AIListEditorColumnController)]){
//
//        }
//
//        [outlineView reloadData];
//    }
//    
//    return(NO);
//}
//
//
////Reflect a sort column & direction
//- (void)_reflectHighlightedColumn:(NSTableColumn *)tableColumn
//{
//    //Highlight the table column
//    selectedColumn = [tableColumn retain];
//    [outlineView_contactList setHighlightedTableColumn:tableColumn];
//}
//

// Toolbar actions ------------------------------------------------------------------
//Toggle the collection drawer
//- (IBAction)toggleDrawer:(id)sender
//{
//    [drawer_sourceList toggle:nil];
//}
//
////Inspect the selected contact
- (IBAction)inspect:(id)sender
{
///*    AIEditorListHandle	*selectedObject = [outlineView_contactList itemAtRow:[outlineView_contactList selectedRow]];
//
//    if([selectedObject isKindOfClass:[AIEditorListHandle class]]){
//        AIListContact	*contact;
//        AIServiceType	*serviceType;
//    
//        //Find the contact
//        serviceType = [[adium accountController] serviceTypeWithID:[(AIEditorListHandle *)selectedObject serviceID]];
//        contact = [[adium contactController] contactInGroup:nil
//                                                withService:serviceType
//                                                        UID:[selectedObject UID]];
//
//        //Show its info
//        [[adium contactController] showInfoForContact:contact];
//    }*/
}

//Delete the selection
- (IBAction)delete:(id)sender
{
	NSArray			*objects = [browser_contactList selectedItems];
	AIListGroup		*group = [[browser_contactList selectedColumn] representedObject];
	
	if(objects && [objects count]){
		[[adium contactController] removeListObjects:objects];
	}
	
	
//    NSDictionary	*contextInfo;
//    NSMutableArray	*handles;
//    NSMutableArray 	*groups;
//    NSEnumerator 	*enumerator;
//    NSNumber		*row;
//    int			numGroups = 0, numHandles = 0;
//
//    //End any editing
//    [self endEditing];
//
//    //build a list of targeted handles and groups
//    handles = [NSMutableArray array];
//    groups = [NSMutableArray array];
//    enumerator = [outlineView_contactList selectedRowEnumerator];
//    while(row = [enumerator nextObject]){
//        id object = [outlineView_contactList itemAtRow:[row intValue]];
//
//        if([object isMemberOfClass:[AIEditorListHandle class]]){
//            numHandles++;
//            [handles addObject:object];
//        }else{
//            if([object count] != 0){
//                numGroups++;
//            }
//            [groups addObject:object];
//        }
//    }
//    contextInfo = [[NSDictionary dictionaryWithObjectsAndKeys:handles, HANDLE_DELETE_KEY, groups, GROUP_DELETE_KEY, nil] retain];
//  
//    //confirm for mass amounts of deleting
//    if(numGroups != 0 && numHandles > 1){
//        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i group%@ and %i contact%@ from %@'s list?", numGroups, (numGroups != 1) ? @"s" : @"", numHandles, (numHandles != 1) ? @"s" : @"", [selectedCollection name]], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Be careful, you cannot undo this action.");
//
//    }else if(numGroups != 0){
//        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i group%@ from %@'s list?", numGroups, (numGroups != 1) ? @"s" : @"", [selectedCollection name]], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Any handles in %@ will be deleted.  Be careful, you cannot undo this action.", (numGroups != 1) ? @"these groups" : @"this group");
//
//    }else if(numHandles > 1){
//        NSBeginAlertSheet([NSString stringWithFormat:@"Delete %i contact%@ from %@'s list?", numHandles, (numHandles != 1) ? @"s" : @"", [selectedCollection name]], @"Delete", @"Cancel", nil, [self window], self, @selector(concludeDeleteSheet:returnCode:contextInfo:), nil, contextInfo, @"Be careful, you cannot undo this action.");
//    }else{ //for single handle and empty group deletes, we don't prompt the user
//        [self concludeDeleteSheet:nil returnCode:NSAlertDefaultReturn contextInfo:contextInfo];
//    }
//
//    //De-select everything
//    [outlineView_contactList deselectAll:nil];
}

- (void)concludeDeleteSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//    NSDictionary	*targetDict = contextInfo;
//    
//    if(returnCode == NSAlertDefaultReturn){
//        NSEnumerator		*enumerator;
//        AIEditorListGroup	*group;
//        AIEditorListHandle	*handle;
//
//        //Delete all the handles
//        enumerator = [[targetDict objectForKey:HANDLE_DELETE_KEY] objectEnumerator];
//        while((handle = [enumerator nextObject])){
//            [selectedCollection deleteHandle:handle]; //Delete the handle
//        }
//
//        //Delete all the groups
//        enumerator = [[targetDict objectForKey:GROUP_DELETE_KEY] objectEnumerator];
//        while((group = [enumerator nextObject])){
//            [selectedCollection deleteGroup:group]; //Delete the group
//        }
//    }
//    
//    [targetDict release];
//    [outlineView_contactList reloadData]; //Refresh
}

//Create a new group
- (IBAction)group:(id)sender
{
//    AIEditorListGroup	*newGroup;
//
//    //End any editing
//    [self endEditing];
//    
//    //Create the new group
//    newGroup = [selectedCollection addGroupNamed:@"New Group" temporary:YES];
//    [outlineView_contactList reloadData];
//    
//    //Select, scroll to, and edit the new group
//    [self scrollToAndEditObject:newGroup column:[outlineView_contactList tableColumnWithIdentifier:@"handle"]];

}

//Create a new handle
- (IBAction)handle:(id)sender
{
	[AINewContactWindowController promptForNewContactOnWindow:[self window]];
	

	
	//    AIEditorListHandle	*newHandle;
//    AIEditorListGroup	*selectedGroup;
//    int			selectedIndex;
//
//    //End any editing
//    [self endEditing];
//
//    //Get the currently selected group
//    selectedIndex = [self selectedIndexAndGroup:&selectedGroup];
//    if(!selectedGroup){
//        selectedGroup = [selectedCollection addGroupNamed:@"New Group" temporary:NO]; //Create them a new group
//        selectedIndex = 0;
//    }
//    if(selectedIndex < 0){
//        selectedIndex = [selectedGroup count];
//    }
//
//    //Create the new handle
//    newHandle = [selectedCollection addHandleNamed:@"New Contact" inGroup:selectedGroup index:selectedIndex temporary:YES];
//
//    //Select, scroll to, and edit the new handle
//    [outlineView_contactList reloadData];
//    [outlineView_contactList expandItem:[newHandle containingGroup]]; //make sure it's expanded
//    [self scrollToAndEditObject:newHandle column:[outlineView_contactList tableColumnWithIdentifier:@"handle"]];

}

////End any editing in our outline view
//- (void)endEditing
//{
//    //Give outline view focus to end any editing
//    [[outlineView_contactList window] makeFirstResponder:outlineView_contactList];
//}
//
//Import contacts from a .blt file
- (IBAction)import:(id)sender
{
//    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//    
//    [openPanel 
//            beginSheetForDirectory:[[NSString stringWithString:@"~/Documents/"] stringByExpandingTildeInPath]
//            file:nil
//            types:[NSArray arrayWithObject:@"blt"]
//            modalForWindow:[self window]
//            modalDelegate:self
//            didEndSelector:@selector(concludeImportPanel:returnCode:contextInfo:)
//            contextInfo:nil];
}

////Finish up the importing panel
- (void)concludeImportPanel:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//    if(returnCode == NSOKButton){
//        [plugin importFile:[[panel filenames] objectAtIndex:0]];
//    }
}

//
//// Window toolbar ---------------------------------------------------------------
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
                                           toolTip:@"Import Contacts"
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"importContacts" forClass:[self class]]
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

//    [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
//                                    withIdentifier:@"ToggleDrawer"
//                                             label:@"ToggleDrawer"
//                                      paletteLabel:@"ToggleDrawer"
//                                           toolTip:@"ToggleDrawer"
//                                            target:self
//                                   settingSelector:@selector(setImage:)
//                                       itemContent:[AIImageUtilities imageNamed:@"AccountLarge" forClass:[self class]]
//                                            action:@selector(toggleDrawer:)
//                                              menu:NULL];
    
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
//    if(([[theItem itemIdentifier] compare:@"Delete"] == 0) || ([[theItem itemIdentifier] compare:@"Inspector"] == 0)){
//        if([outlineView_contactList selectedRow] != -1 && [[self window] firstResponder] == outlineView_contactList){
//            return(YES);
//        }else{
//            return(NO);
//        }
//    }else if(([[theItem itemIdentifier] compare:@"Group"] == 0) || ([[theItem itemIdentifier] compare:@"Handle"] == 0)){
//        if(selectedCollection){
//            return(YES);
//        }else{
//            return(NO);
//        }
//    }
//
    return(YES);
}

////Return the requested toolbar item
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

////Return the default toolbar set
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Group",@"Handle",NSToolbarSeparatorItemIdentifier,@"Delete",@"Import",NSToolbarFlexibleSpaceItemIdentifier,@"Inspector",nil];
}

////Return a list of allowed toolbar items
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Group",@"Handle",@"Delete",@"Import",@"Inspector",@"ToggleDrawer",NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,nil];
}


//
//
//// Private ------------------------------------------------------------------
////Returns the currently "selected" group, or the group whose handles are selected
//- (int)selectedIndexAndGroup:(AIEditorListGroup **)group
//{
//    id			selectedItem;
//    AIEditorListGroup	*selectedGroup;
//    int			index = -1;
//
//    //Get the currently selected group
//    selectedItem = [outlineView_contactList itemAtRow:[outlineView_contactList selectedRow]];
//    if(selectedItem == nil){
//        NSArray	*list = [selectedCollection list];
//
//        if([list count]){
//            selectedGroup = [list objectAtIndex:0];
//        }else{
//            selectedGroup = nil;
//        }
//
//    }else if([selectedItem isKindOfClass:[AIEditorListHandle class]]){
//        selectedGroup = [(AIEditorListHandle *)selectedItem containingGroup];
//        index = [selectedGroup indexOfHandle:selectedItem];
//        
//    }else{
//        selectedGroup = (AIEditorListGroup *)selectedItem;
//    }
//
//    //
//    *group = selectedGroup;
//    return(index);
//}
//
////Select, scroll to, and edit a list object
//- (void)scrollToAndEditObject:(id)object column:(NSTableColumn *)column
//{
//    int		row;
//
//    [outlineView_contactList indexOfTableColumnWithIdentifier:@"handle"];
//
//    row = [outlineView_contactList rowForItem:object];
//    if(row != -1){
//        [outlineView_contactList scrollRowToVisible:row];
//        [outlineView_contactList selectRow:row byExtendingSelection:NO];
//        if([self outlineView:outlineView_contactList shouldEditTableColumn:column item:object]){
//            [outlineView_contactList editColumn:[outlineView_contactList indexOfTableColumn:column] row:row withEvent:nil select:YES];
//        }
//    }
//}

//Returns 2 for mixed, 1 for all handles owned, 0 for all handles not owned
//- (int)allHandlesInGroup:(AIEditorListGroup *)group belongToCollection:(AIEditorCollection *)collection
//{
//    NSEnumerator	*enumerator;
//    AIEditorListHandle	*handle;
//    BOOL		owned = NO;
//    BOOL		notOwned = NO;
//
//    enumerator = [group handleEnumerator];
//    while((handle = [enumerator nextObject])){
//        if([collection containsHandleWithUID:[handle UID]]){
//            owned = YES;
//        }else{
//            notOwned = YES;
//        }
//
//        if(owned && notOwned) break; //Abort early if we find a mix
//    }
//
//    if(owned && notOwned){
//        return(2);
//    }else if(owned){
//        return(1);
//    }else{
//        return(0);
//    }
//}
//
////Returns the number of collection that want an ownership column
//- (int)_collectionsRequestingOwnership
//{
//    NSEnumerator		*enumerator;
//    AIEditorCollection		*object;
//    int				ownerCount = 0;
//
//    enumerator = [[plugin collectionsArray] objectEnumerator];
//    while((object = [enumerator nextObject])){
//        if([object includeInOwnershipColumn]){
//            ownerCount++;
//        }
//    }
//
//    return(ownerCount);
//}
//
////Adjust outline view column widths
//- (void)_sizeContentColumnsToFit:(NSNotification *)notification
//{
//    NSEnumerator	*enumerator;
//    NSTableColumn	*column;
//    int			totalWidth = [scrollView_contactList documentVisibleRect].size.width;
//    int			flexColumns = 0;
//    BOOL		firstColumnProcessed = NO;
//    float		flexWidth;
//    NSSize		spacing = [outlineView_contactList intercellSpacing];
//    float		indentation = ([outlineView_contactList indentationPerLevel] * 2);
//
//    //Factor in the width of all fixed width columns
//    enumerator = [[outlineView_contactList tableColumns] objectEnumerator];
//    while((column = [enumerator nextObject])){
//        if([column minWidth] == [column maxWidth]){ //Fixed width column
//            totalWidth -= ([column width] + spacing.width);
//        }else{
//            flexColumns++;
//        }
//    }
//
//    //Compensate for the indentation in the leftmost column
//    totalWidth -= indentation;
//
//    //Split the remaining space
//    flexWidth = totalWidth / flexColumns;
//    enumerator = [[outlineView_contactList tableColumns] objectEnumerator];
//    while((column = [enumerator nextObject])){
//        if([column minWidth] != [column maxWidth]){ //Flex width column
//            if(firstColumnProcessed){
//                [column setWidth:(flexWidth - spacing.width)];
//            }else{
//                //Give the first column any extra pixels, and compensate for the indentation
//                [column setWidth:((totalWidth / flexColumns) + (totalWidth % flexColumns) + (indentation) - spacing.width)];
//                firstColumnProcessed = YES;
//            }
//        }
//    }
//
//}


	
	
	
	
	
	
	
- (void)browserSingleClick:(NSBrowser *)sender
{
	NSLog(@"browserSingleClick");
}

- (void)browserDoubleClick:(NSBrowser *)sender
{
	NSLog(@"browserDoubleClick");
}
	
// Browser delegate ----------------------------------------------------------------------------------------------------

- (id)browserView:(AIBrowser *)browserView child:(int)index ofItem:(id)item
{
	if(!item) item = [[adium contactController] contactList];
	return([item objectAtIndex:index]);
}

- (BOOL)browserView:(AIBrowser *)browserView isItemExpandable:(id)item
{
	if(!item) item = [[adium contactController] contactList];
	return([item isKindOfClass:[AIListGroup class]]);
}

- (int)browserView:(AIBrowser *)browserView numberOfChildrenOfItem:(id)item
{
	if(!item) item = [[adium contactController] contactList];
	return([item count]);
}

- (id)browserView:(AIBrowser *)browserView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if(!item) item = [[adium contactController] contactList];
	return([item displayName]);
}










//- (AIListGroup *)browser:(NSBrowser *)browser groupForColumn:(int)column
//{
//	AIListGroup *group = [[adium contactController] contactList];
//	int 		i;
//	
//	for(i = 0; i < column; i++)
//	{
//		int index = [browser selectedRowInColumn:i];
//		group = [group objectAtIndex:index];
//		
//		if(![group isKindOfClass:[AIListGroup class]]) return(nil);
//	}
//
//	return(group);
//}
//
//- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
//{
//	if ([[self browser:sender groupForColumn:column] respondsToSelector:@selector(count)])
//		return ([[self browser:sender groupForColumn:column] count]);
//	else return 0;
//}
//
//- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column
//{
//	AIListGroup		*group = [self browser:sender groupForColumn:column];
//	AIListObject	*object = [group objectAtIndex:row];
//	
//	[cell setStringValue:[object displayName]];
//	[cell setLeaf:![object isKindOfClass:[AIListGroup class]]];
//	
//	if([object isKindOfClass:[AIListGroup class]]){
//		[cell setLeaf:NO];
//		[cell setImage:groupImage];
//	}else{
//		[cell setLeaf:YES];
//		[cell setImage:[serviceImageDict objectForKey:[object serviceID]]];
//	}
//}
	
@end

