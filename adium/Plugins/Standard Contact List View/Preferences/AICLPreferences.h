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

#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_LIST_LAYOUT_NAME	@"List Layout Name"
#define KEY_LIST_THEME_NAME		@"List Theme Name"

@interface AICLPreferences : AIPreferencePane {
    IBOutlet	NSView			*view_prefViewGeneral;
    IBOutlet	NSButton		*button_setFont;
    IBOutlet	NSTextField		*textField_fontName;
    IBOutlet	NSButton		*checkBox_alternatingGrid;
    IBOutlet	NSButton		*checkBox_showLabels;
	IBOutlet	NSButton		*checkBox_tooltips;
    IBOutlet	NSColorWell		*colorWell_contact;
    IBOutlet	NSColorWell		*colorWell_background;
    IBOutlet	NSColorWell		*colorWell_grid;
	
	NSString	*currentLayoutName;
	NSString	*currentThemeName;
	
	IBOutlet	NSTableView		*tableView_layout;
	IBOutlet	NSTableView		*tableView_theme;
	
	IBOutlet	NSButton		*button_layoutDelete;
	IBOutlet	NSButton		*button_themeDelete;
	IBOutlet	NSButton		*button_layoutEdit;
	IBOutlet	NSButton		*button_themeEdit;
	
	BOOL	ignoreSelectionChanges;
	
	NSArray		*layoutArray;
	NSArray		*themeArray;

	NSImage		*layoutStandard;
	NSImage		*layoutBorderless;
	NSImage		*layoutMockie;
	NSImage		*layoutPillows;
}

- (IBAction)spawnLayout:(id)sender;
- (IBAction)spawnTheme:(id)sender;
- (IBAction)deleteLayout:(id)sender;
- (IBAction)deleteTheme:(id)sender;
- (IBAction)editTheme:(id)sender;
- (IBAction)editLayout:(id)sender;

+ (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;

@end
