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

@class AIAccountController, AIAccount;

@interface AIAccountListPreferencesPlugin : AIPlugin {
    IBOutlet		NSView		*view_accountPreferences;
    IBOutlet		NSTableView	*tableView_accountList;
    IBOutlet		NSScrollView	*scrollView_accountList;
    IBOutlet		NSButton	*button_editAccount;
    IBOutlet		NSButton	*button_deleteAccount;
    IBOutlet		NSButton	*button_toggleAccount;

    AIPreferenceViewController	*preferenceView;

    NSMutableDictionary	*toolbarItems;

    NSArray		*serviceArray;
    BOOL		accountDetailsVisible;	//YES if the details view is visible
    NSSize		accountViewPadding;	//The amount of space around the custom account view

    NSSize		accountListPadding;
    NSArray		*accountArray;
    AIAccount		*tempDragAccount;
}

- (IBAction)deleteAccount:(id)sender;
- (IBAction)newAccount:(id)sender;
- (IBAction)toggleConnection:(id)sender;
- (IBAction)editAccount:(id)sender;


@end
