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

@class AIModularPaneCategoryView;

@interface AIContactInfoWindowController : AIWindowController {	
	IBOutlet		NSTabView						*tabView_category;
	IBOutlet		NSImageView						*imageView_userIcon;
	IBOutlet		NSTextField						*textField_accountName;
	IBOutlet		NSTextField						*textField_service;
	
	IBOutlet		AIModularPaneCategoryView		*view_Profile;
	IBOutlet		AIModularPaneCategoryView		*view_Accounts;
	IBOutlet		AIModularPaneCategoryView		*view_Alerts;
	IBOutlet		AIModularPaneCategoryView		*view_Settings;

	AIListObject	*displayedObject;
	NSMutableArray	*loadedPanes;
}

+ (void)showInfoWindowForListObject:(AIListObject *)listObject;
+ (void)closeInfoWindow;
- (void)configureForListObject:(AIListObject *)inObject;
- (IBAction)closeWindow:(id)sender;
- (void)configurePanes;

@end
