/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface BGThemesPreferences : AIPreferencePane {
    // Create panel
    IBOutlet NSWindow		*createWindow;
    IBOutlet NSTextField	*textField_name;
    IBOutlet NSTextField	*textField_author;
    IBOutlet NSTextField	*textField_version;
    IBOutlet NSButton		*button_create;
    IBOutlet NSButton		*button_cancel;
	
    // List of themes
    IBOutlet AIAlternatingRowTableView		*tableView_themesList;
	IBOutlet NSButton						*button_apply;
	IBOutlet NSButton						*button_createNewTheme;
	IBOutlet NSButton						*button_delete;
	
	// other
    NSMenu *themeMenu;
	
    NSString			*defaultThemePath;
    NSMutableArray		*themes;
    int 				themeCount;
}

-(IBAction)showCreateNewThemeSheet:(id)sender;
-(IBAction)createNewThemeSheetAction:(id)sender;
-(IBAction)applyTheme:(id)sender;
-(IBAction)deleteTheme:(id)sender;

@end
