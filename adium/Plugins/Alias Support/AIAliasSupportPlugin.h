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

#import <Foundation/Foundation.h>

#import "AIAliasSupportPreferences.h"

@protocol AIListEditorColumnController;

#define DISPLAY_NAME			1
#define DISPLAY_NAME_SCREEN_NAME	2
#define SCREEN_NAME_DISPLAY_NAME	3	
#define SCREEN_NAME			4

#define	PREF_GROUP_DISPLAYFORMAT		@"Display Format"		//Preference group to store aliases in

@interface AIAliasSupportPlugin : AIPlugin <AIListObjectObserver, AIPreferenceViewControllerDelegate> {
    IBOutlet    NSView				*view_contactAliasInfoView;
    IBOutlet	ESDelayedTextField  *textField_alias;

    AIPreferenceViewController		*contactView;
    AIListObject					*activeListObject;
    int displayFormat;
    
    AIAliasSupportPreferences		*prefs;
}

- (void)installPlugin;
- (IBAction)setAlias:(id)sender;
- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject;

@end
