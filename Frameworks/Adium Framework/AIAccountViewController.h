/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIObject.h"

@protocol AIListObjectObserver;

@interface AIAccountViewController : AIObject {
	//These are the views used in Adium's account preferences.  If views aren't provided by a custom account view
	//nib, default views with the most common controls will be used.  There is no need to provide a custom nib
	//if your account code only needs the default controls.
    IBOutlet	NSView			*view_setup;              		//Account setup (UID, password, etc)
    IBOutlet	NSView			*view_connection;              	//Account connection (Host, port, protocol, etc)
    IBOutlet	NSTabView		*view_auxiliaryTabView;			//Tab view containing auxiliary tabs
	
	//These common controls are used by most protocols, so we place them here as a convenience to protocol code.
	//Custom account view nibs are encouraged to connect to these outlets.
	IBOutlet	NSTextField		*textField_accountUID;			//UID field
	IBOutlet	NSTextField		*textField_password;			//Password field

	//Instance variables
    AIAccount			*account;
	NSArray				*auxiliaryTabs;
}

+ (id)accountViewController;
- (id)init;
- (NSView *)setupView;
- (NSView *)connectionView;
- (void)configureForAccount:(AIAccount *)inAccount;
- (IBAction)changedPreference:(id)sender;
- (NSArray *)loadAuxiliaryTabsFromTabView:(NSTabView *)inTabView;
- (NSString *)nibName;
- (NSArray *)auxiliaryTabs;
- (void)saveFieldsImmediately;

@end
