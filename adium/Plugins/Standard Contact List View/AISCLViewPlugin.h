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

#define	PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"

#define SCL_DEFAULT_PREFS		@"SCL Defaults"

#define KEY_SCL_FONT			@"Font"
#define KEY_SCL_CONTACT_COLOR		@"Contact Color"
#define	KEY_SCL_ALTERNATING_GRID	@"Alternating Grid"
#define	KEY_SCL_SHOW_LABELS		@"Show Labels"
#define KEY_SCL_GRID_COLOR		@"Grid Color"
#define KEY_SCL_BACKGROUND_COLOR	@"Background Color"
#define KEY_SCL_CUSTOM_GROUP_COLOR	@"Custom Group Color"
#define KEY_SCL_BOLD_GROUPS		@"Bold Groups"
#define KEY_SCL_GROUP_COLOR		@"Group Color"

//Advanced
#define KEY_SCL_BORDERLESS              @"Borderless"
#define KEY_SCL_SHADOWS                 @"Shadows"
#define KEY_SCL_SPACING                 @"Row Spacing"
#define KEY_SCL_OPACITY			@"Opacity"
#define KEY_SCL_OUTLINE_GROUPS          @"Outline Groups"
#define KEY_SCL_OUTLINE_GROUPS_COLOR    @"Outline Groups Color"
#define KEY_SCL_BACKGROUND_TOOLTIPS     @"Tooltips In Background"

#define KEY_SCL_LABEL_AROUND_CONTACT    @"Label Around Contact"
#define KEY_SCL_OUTLINE_LABELS          @"Outline Labels"
#define KEY_SCL_LABEL_OPACITY           @"Label Opacity"
#define KEY_SCL_LABEL_GROUPS            @"Label Groups"
#define KEY_SCL_LABEL_GROUPS_COLOR      @"Label Groups Color"
#define KEY_SCL_USE_GRADIENT		@"Use Gradient"

@class AIListGroup, AICLPreferences, ESCLViewAdvancedPreferences, ESCLViewLabelsAdvancedPrefs, AICLGroupPreferences;
@protocol AIContactListViewController;

@interface AISCLViewPlugin : AIPlugin <AIContactListViewPlugin> {
    NSMutableArray                  *controllerArray;
    
    AICLPreferences                 *preferences;
	AICLGroupPreferences			*preferencesGroup;
    ESCLViewAdvancedPreferences     *preferencesAdvanced;
    ESCLViewLabelsAdvancedPrefs     *preferencesLabelsAdvanced;
}

@end
