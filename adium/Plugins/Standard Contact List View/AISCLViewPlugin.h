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
#import <Adium/Adium.h>

#define	PREF_GROUP_CONTACT_LIST		@"Contact List Display"

#define SCL_DEFAULT_PREFS		@"SCL Defaults"

#define KEY_SCL_FONT			@"Font"
#define	KEY_SCL_ALTERNATING_GRID	@"Alternating Grid"
#define KEY_SCL_GRID_COLOR		@"Grid Color"
#define KEY_SCL_BACKGROUND_COLOR	@"Background Color"
#define KEY_SCL_OPACITY			@"Opacity"



@class AIListGroup, AICLPreferences;
@protocol AIContactListViewController;

@interface AISCLViewPlugin : AIPlugin <AIContactListViewController> {

    AICLPreferences	*preferences;

    AIListGroup		*contactList;
    NSMutableArray	*SCLViewArray;
    
}

- (IBAction)performDefaultActionOnSelectedContact:(id)sender;

@end
