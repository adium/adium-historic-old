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

#import <Cocoa/Cocoa.h>

//#define SUB_COLUMN_WIDTH	12 //18
//#define LABEL_ROTATION		55 //45
//#define LABEL_SIZE		10
//#define LABEL_HEIGHT		16
//#define LABEL_LENGTH		180
//#define LABEL_X_OFFSET		1 //4
//#define LABEL_Y_OFFSET		-4// -6
//#define LABEL_NAME_X_OFFSET	2


#define MAIN_COLUMN_WIDTH	160		//Width of the main column
#define ALIAS_COLUMN_WIDTH	160		//Width of the alias column
#define SUB_COLUMN_WIDTH	12		//Width of the account columns

@class AIAdium, AIContactGroup, AIContactObject, AIAlternatingRowOutlineView, AISCLEditHeaderView;

@interface AIContactListEditorWindowController : NSWindowController {

    IBOutlet	AIAlternatingRowOutlineView	*outlineView_contactList;	//The contact list outline view
    IBOutlet	NSScrollView			*scrollView_contactList;	//The contact list's scroll view
    IBOutlet	AISCLEditHeaderView		*customView_tableHeader;	//The custom table header view
    
    NSImage			*folderImage;			//The image of a small folder

    AIAdium			*owner;				//AIAdium
    AIContactGroup		*contactList;			//A local reference to the contact list

    NSMutableDictionary		*toolbarItems; 			//A dictionary of toolbar items for the login window

    NSTextField			*editor;			//The custom outline view editor field
    BOOL			editorOpen;			//YES if the editor is currently open
    AIContactObject		*editedObject;			//The contact being edited
    NSTableColumn		*editedColumn;			//The column being edited

    NSMutableArray		*dragItems;
}

+ (id)contactListEditorWindowControllerWithOwner:(id)inOwner;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;

@end
