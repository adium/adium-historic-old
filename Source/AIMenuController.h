/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#define Menu_didChange  @"Menu_didChange"

@class AIListObject, AIChat;

@protocol AIController;

typedef enum {
    LOC_Adium_About = 0, LOC_Adium_Preferences,
    LOC_File_New, LOC_File_Close, LOC_File_Save, LOC_File_Additions,
    LOC_Edit_Bottom, LOC_Edit_Additions,
	LOC_View_General, LOC_View_Sorting, LOC_View_Toggles, LOC_View_Additions, 
    LOC_Contact_Manage, LOC_Contact_Info, LOC_Contact_Action, LOC_Contact_NegativeAction, LOC_Contact_Additions,
	LOC_Status_State, LOC_Status_Accounts, LOC_Status_Additions,
    LOC_Format_Styles, LOC_Format_Palettes, LOC_Format_Additions, 
    LOC_Window_Top, LOC_Window_Commands, LOC_Window_Auxiliary, LOC_Window_Fixed,
    LOC_Help_Local, LOC_Help_Web, LOC_Help_Additions,
    LOC_Dock_Status
} MENU_LOCATION;

typedef enum {
    Context_Group_Manage,Context_Contact_Manage, Context_Contact_Action, Context_Contact_NegativeAction,
    Context_Contact_Additions, Context_Contact_ChatAction, Context_Contact_Stranger_ChatAction, Context_Contact_ListAction,
	Context_Contact_GroupChatAction,
	Context_Tab_Action,
	Context_TextView_Edit
} CONTEXT_MENU_LOCATION;

@interface AIMenuController : NSObject <AIController> {
    IBOutlet	AIAdium		*adium;
	
    IBOutlet	id		nilMenuItem;
    IBOutlet	id		menu_Adium_About;
    IBOutlet	id		menu_Adium_Preferences;
    IBOutlet	id		menu_File_New;
    IBOutlet	id		menu_File_Close;
    IBOutlet	id		menu_File_Save;
    IBOutlet	id		menu_File_Additions;
    IBOutlet	id		menu_Edit_Bottom;
    IBOutlet	id		menu_Edit_Additions;
    IBOutlet	id		menu_View_General;
    IBOutlet	id		menu_View_Unnamed_A;
    IBOutlet	id		menu_View_Unnamed_B;
    IBOutlet	id		menu_View_Unnamed_C;
	IBOutlet	id		menu_Status_State;
    IBOutlet	id		menu_Status_Accounts;
    IBOutlet	id		menu_Status_Additions;
    IBOutlet	id		menu_Format_Styles;
    IBOutlet	id		menu_Format_Palettes;
    IBOutlet	id		menu_Format_Additions;
    IBOutlet	id		menu_Window_Top;
    IBOutlet	id		menu_Window_Commands;
    IBOutlet	id		menu_Window_Auxiliary;
    IBOutlet	id		menu_Window_Fixed;
    IBOutlet	id		menu_Help_Local;
    IBOutlet	id		menu_Help_Web;
    IBOutlet	id		menu_Help_Additions;
    IBOutlet	id		menu_Contact_Manage;
    IBOutlet	id		menu_Contact_Info;
    IBOutlet	id		menu_Contact_Action;
    IBOutlet	id		menu_Contact_NegativeAction;
    IBOutlet	id		menu_Contact_Additions;
    IBOutlet	id		menu_Dock_Status;
    IBOutlet    id  	menuItem_Format_Italics;
    
	//Menu items in MainMenu.nib for localization purposes
	IBOutlet	NSMenuItem	*menuItem_file;
	IBOutlet	NSMenuItem	*menuItem_edit;
	IBOutlet	NSMenuItem	*menuItem_view;
	IBOutlet	NSMenuItem	*menuItem_status;
	IBOutlet	NSMenuItem	*menuItem_contact;
	IBOutlet	NSMenuItem	*menuItem_format;
	IBOutlet	NSMenuItem	*menuItem_window;
	IBOutlet	NSMenuItem	*menuItem_help;
	
	//Adium menu
	IBOutlet	NSMenuItem	*menuItem_aboutAdium;
	IBOutlet	NSMenuItem	*menuItem_adiumXtras;
	IBOutlet	NSMenuItem	*menuItem_preferences;
	IBOutlet	NSMenuItem	*menuItem_services;
	IBOutlet	NSMenuItem	*menuItem_hideAdium;
	IBOutlet	NSMenuItem	*menuItem_hideOthers;
	IBOutlet	NSMenuItem	*menuItem_showAll;
	IBOutlet	NSMenuItem	*menuItem_quitAdium;
	
	//File menu
	IBOutlet	NSMenuItem	*menuItem_close;
	IBOutlet	NSMenuItem	*menuItem_closeChat;
	IBOutlet	NSMenuItem  *menuItem_closeAllChats;
	IBOutlet	NSMenuItem	*menuItem_saveAs;
	IBOutlet	NSMenuItem	*menuItem_pageSetup;
	IBOutlet	NSMenuItem	*menuItem_print;
	
	//Edit menu
	IBOutlet	NSMenuItem	*menuItem_cut;
	IBOutlet	NSMenuItem	*menuItem_copy;
	IBOutlet	NSMenuItem	*menuItem_paste;
	IBOutlet	NSMenuItem	*menuItem_pasteAndMatchStyle;
	IBOutlet	NSMenuItem	*menuItem_clear;
	IBOutlet	NSMenuItem	*menuItem_selectAll;
	
	IBOutlet	NSMenuItem	*menuItem_find;
	IBOutlet	NSMenuItem	*menuItem_findCommand;
	IBOutlet	NSMenuItem	*menuItem_findNext;
	IBOutlet	NSMenuItem	*menuItem_findPrevious;
	IBOutlet	NSMenuItem	*menuItem_findUseSelectionForFind;
	IBOutlet	NSMenuItem	*menuItem_findJumpToSelection;
	
	IBOutlet	NSMenuItem	*menuItem_spelling;
	IBOutlet	NSMenuItem	*menuItem_spellingCommand;
	IBOutlet	NSMenuItem	*menuItem_spellingCheckSpelling;
	IBOutlet	NSMenuItem	*menuItem_spellingCheckSpellingAsYouType;
		
	IBOutlet	NSMenuItem	*menuItem_speech;
	IBOutlet	NSMenuItem	*menuItem_startSpeaking;
	IBOutlet	NSMenuItem	*menuItem_stopSpeaking;

	//View menu
	IBOutlet	NSMenuItem	*menuItem_customizeToolbar;
	
	//Format menu
	IBOutlet	NSMenuItem	*menuItem_bold;
	IBOutlet	NSMenuItem	*menuItem_italic;
	IBOutlet	NSMenuItem	*menuItem_underline;
	IBOutlet	NSMenuItem	*menuItem_showFonts;
	IBOutlet	NSMenuItem	*menuItem_showColors;
	
	//Window menu
	IBOutlet	NSMenuItem	*menuItem_minimize;
	IBOutlet	NSMenuItem	*menuItem_bringAllToFront;

	//Help menu
	IBOutlet	NSMenuItem	*menuItem_adiumHelp;
	IBOutlet	NSMenuItem	*menuItem_reportABug;
	IBOutlet	NSMenuItem	*menuItem_sendFeedback;
	IBOutlet	NSMenuItem	*menuItem_adiumForums;
	
    NSMenu                              *contextualMenu;
    NSMutableDictionary					*contextualMenuItemDict;
    AIListObject						*currentContextMenuObject;
    AIChat								*currentContextMenuChat;
	
    //disabled until post .53
    NSMenu                              *textViewContextualMenu;
    NSTextView                          *contextualMenu_TextView;
    
    NSMutableArray                      *locationArray;
    BOOL                                 isTracking;
	
}

//Custom menu items
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location;
- (void)removeMenuItem:(NSMenuItem *)targetItem;

//Contextual menu items
- (void)addContextualMenuItem:(NSMenuItem *)newItem toLocation:(CONTEXT_MENU_LOCATION)location;
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject;
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject inChat:(AIChat *)inChat;
- (AIListObject *)currentContextMenuObject;
- (AIChat *)currentContextMenuChat;

- (NSTextView *)contextualMenuTextView;
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forTextView:(NSTextView *)inObject;

//Control over the italics menu item
- (void)removeItalicsKeyEquivalent;
- (void)restoreItalicsKeyEquivalent;

@end



@interface AIMenuController (INTERNAL)
@end
