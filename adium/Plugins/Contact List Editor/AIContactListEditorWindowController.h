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

#import <Cocoa/Cocoa.h>

#define MAIN_COLUMN_WIDTH	160		//Width of the main column
#define ALIAS_COLUMN_WIDTH	160		//Width of the alias column
#define SUB_COLUMN_WIDTH	12		//Width of the account columns

@class AIAdium, AIContactGroup, AIContactObject, AIAlternatingRowOutlineView, AISCLEditHeaderView, AIEditorCollection, AIContactListEditorPlugin, AIAutoScrollView;

@interface AIContactListEditorWindowController : NSWindowController {

    IBOutlet	AIAlternatingRowOutlineView	*outlineView_contactList;	//The contact list outline view
    IBOutlet	NSScrollView			*scrollView_contactList;	//The contact list's scroll view
    IBOutlet	NSTableView			*tableView_sourceList;	//
    IBOutlet	AISCLEditHeaderView		*customView_tableHeader;	//The custom table header view

    IBOutlet	AIAutoScrollView		*scrollView_sourceList;

    IBOutlet	NSDrawer			*drawer_sourceList;

    IBOutlet	NSButton		*button_newHandle;
    IBOutlet	NSButton		*button_newGroup;
    
    AIAdium			*owner;				//AIAdium
    AIContactListEditorPlugin	*plugin;			//Our owning plugin

    NSMutableDictionary		*toolbarItems; 			//A dictionary of toolbar items for the login window
    NSMutableArray		*dragItems;
    AIEditorCollection		*dragSourceCollection;
    
    AIEditorCollection		*selectedCollection;

    NSTableColumn	*indexColumn;    
        
    NSTableColumn	*selectedColumn;

    
}

+ (id)contactListEditorWindowControllerWithOwner:(id)inOwner plugin:(AIContactListEditorPlugin *)inPlugin;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)import:(id)sender;
- (IBAction)group:(id)sender;
- (IBAction)handle:(id)sender;

@end
