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

@protocol AIContactListViewController, AIInterfaceContainer;

#import "AIListController.h"

#define PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"
#define KEY_SCL_BORDERLESS					@"Borderless"
#define KEY_DUAL_RESIZE_VERTICAL			@"Autoresize Vertical"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

@interface AIListWindowController : AIWindowController <AIInterfaceContainer, AIListControllerDelegate> {
	BOOL                                borderless;
	
	NSSize								minWindowSize;
	IBOutlet	AIAutoScrollView		*scrollView_contactList;
    IBOutlet	AIListOutlineView		*contactListView;
	AIListController					*contactListController;
}

+ (AIListWindowController *)listWindowController;
- (NSString *)nibName;
- (void)close:(id)sender;
- (void)showWindowInFront:(BOOL)inFront;

@end
