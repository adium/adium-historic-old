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

#define Menu_didChange  @"Menu_didChange"

typedef enum {
    LOC_Adium_About = 0, LOC_Adium_Preferences,
    LOC_File_New, LOC_File_Close, LOC_File_Save, LOC_File_Accounts, LOC_File_Additions, LOC_File_Status,
    LOC_Edit_Bottom, LOC_Edit_Additions,
    LOC_Format_Styles, LOC_Format_Palettes, LOC_Format_Additions, 
    LOC_Window_Top, LOC_Window_Commands, LOC_Window_Auxiliary, LOC_Window_Fixed,
    LOC_Help_Local, LOC_Help_Web, LOC_Help_Additions,
    LOC_Contact_Editing, LOC_Contact_Manage, LOC_Contact_Action, LOC_Contact_NegativeAction, LOC_Contact_Additions,
	LOC_View_General, LOC_View_Unnamed_A, LOC_View_Unnamed_B, LOC_View_Unnamed_C, 
    LOC_Dock_Status
} MENU_LOCATION;

typedef enum {
    Context_Group_Manage,Context_Contact_Manage, Context_Contact_Action, Context_Contact_NegativeAction, Context_Contact_Additions    
} CONTEXT_MENU_LOCATION;

@interface AIMenuController : NSObject {
    IBOutlet	AIAdium		*owner;
	
    IBOutlet	NSMenuItem	*nilMenuItem;
    IBOutlet	NSMenuItem	*menu_Adium_About;
    IBOutlet	NSMenuItem	*menu_Adium_Preferences;
    IBOutlet	NSMenuItem	*menu_File_New;
    IBOutlet	NSMenuItem	*menu_File_Close;
    IBOutlet	NSMenuItem	*menu_File_Save;
    IBOutlet	NSMenuItem	*menu_File_Accounts;
    IBOutlet	NSMenuItem	*menu_File_Additions;
    IBOutlet	NSMenuItem	*menu_File_Status;
    IBOutlet	NSMenuItem	*menu_Edit_Bottom;
    IBOutlet	NSMenuItem	*menu_Edit_Additions;
    IBOutlet	NSMenuItem	*menu_Format_Styles;
    IBOutlet	NSMenuItem	*menu_Format_Palettes;
    IBOutlet	NSMenuItem	*menu_Format_Additions;
    IBOutlet	NSMenuItem	*menu_Window_Top;
    IBOutlet	NSMenuItem	*menu_Window_Commands;
    IBOutlet	NSMenuItem	*menu_Window_Auxiliary;
    IBOutlet	NSMenuItem	*menu_Window_Fixed;
    IBOutlet	NSMenuItem	*menu_Help_Local;
    IBOutlet	NSMenuItem	*menu_Help_Web;
    IBOutlet	NSMenuItem	*menu_Help_Additions;
    IBOutlet	NSMenuItem	*menu_Contact_Editing;
    IBOutlet	NSMenuItem	*menu_Contact_Manage;
    IBOutlet	NSMenuItem	*menu_Contact_Action;
    IBOutlet	NSMenuItem	*menu_Contact_NegativeAction;
    IBOutlet	NSMenuItem	*menu_Contact_Additions;
    IBOutlet	NSMenuItem	*menu_View_General;
    IBOutlet	NSMenuItem	*menu_View_Unnamed_A;
    IBOutlet	NSMenuItem	*menu_View_Unnamed_B;
    IBOutlet	NSMenuItem	*menu_View_Unnamed_C;
    IBOutlet	id			menu_Dock_Status;
    IBOutlet    NSMenuItem  *menuItem_Format_Italics;
    
    NSMenu						*contextualMenu;
    NSMutableDictionary			*contextualMenuItemDict;
    AIListContact				*contactualMenuContact;
    
    NSMutableArray				*locationArray;
    BOOL                        isTracking;
	
}

//Custom menu items
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location;
- (void)removeMenuItem:(NSMenuItem *)targetItem;

//Contextual menu items
- (void)addContextualMenuItem:(NSMenuItem *)newItem toLocation:(CONTEXT_MENU_LOCATION)location;
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject;
- (AIListContact *)contactualMenuContact;

//Control over the italics menu item
- (void)removeItalicsKeyEquivalent;
- (void)restoreItalicsKeyEquivalent;

//Private
- (void)initController;
- (void)closeController;

@end



@interface AIMenuController (INTERNAL)
@end
