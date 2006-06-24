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

#import <Adium/AIPlugin.h>
#import "AIAbstractListController.h"
#import "AIMultiListWindowController.h"

#define KEY_LIST_LAYOUT_NAME			@"List Layout Name"
#define KEY_LIST_THEME_NAME				@"List Theme Name"

#define	CONTACT_LIST_DEFAULTS		@"ContactListDefaults"

@class AIListWindowController, AICLPreferences, ESContactListAdvancedPreferences;
@protocol AIContactListController;

@interface AISCLViewPlugin : AIPlugin <AIContactListController> {	
	AIMultiListWindowController				*contactListWindowController;
	AICLPreferences						*preferences;
	ESContactListAdvancedPreferences	*advancedPreferences;
	LIST_WINDOW_STYLE					windowStyle;
}

//Contact List Controller
- (AIMultiListWindowController *)contactListWindowController;
- (void)contactListDidClose;
- (void)showContactListAndBringToFront:(BOOL)bringToFront;
- (BOOL)contactListIsVisibleAndMain;
- (void)closeContactList;
- (void)contactListDidClose;

@end
