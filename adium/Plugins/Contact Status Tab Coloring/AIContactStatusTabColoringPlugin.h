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

#define TAB_COLORING_DEFAULT_PREFS              @"TabColoringDefaults"
#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

#define KEY_TAB_AWAY_ENABLED		@"Tab Away Enabled"
#define KEY_TAB_IDLE_ENABLED		@"Tab Idle Enabled"
#define KEY_TAB_TYPING_ENABLED		@"Tab Typing Enabled"
#define KEY_TAB_SIGNED_OFF_ENABLED	@"Tab Signed Off Enabled"
#define KEY_TAB_SIGNED_ON_ENABLED	@"Tab Signed On Enabled"
#define KEY_TAB_UNVIEWED_ENABLED	@"Tab Unviewed Content Enabled"
#define KEY_TAB_ONLINE_ENABLED		@"Tab Online Enabled"
#define KEY_TAB_IDLE_AWAY_ENABLED	@"Tab Idle And Away Enabled"
#define KEY_TAB_OFFLINE_ENABLED		@"Tab Offline Color Enabled"
#define KEY_TAB_UNVIEWED_FLASH_ENABLED	@"Tab Unviewed Flash Enabled"
#define KEY_TAB_USE_CUSTOM_COLORS       @"Tab Use Custom Colors"

#define KEY_TAB_AWAY_COLOR		@"Tab Away Color"
#define KEY_TAB_IDLE_COLOR		@"Tab Idle Color"
#define KEY_TAB_TYPING_COLOR		@"Tab Typing Color"
#define KEY_TAB_SIGNED_OFF_COLOR	@"Tab Signed Off Color"
#define KEY_TAB_SIGNED_ON_COLOR		@"Tab Signed On Color"
#define KEY_TAB_UNVIEWED_COLOR		@"Tab Unviewed Content Color"
#define KEY_TAB_ONLINE_COLOR		@"Tab Online Color"
#define KEY_TAB_IDLE_AWAY_COLOR		@"Tab Idle And Away Color"
#define KEY_TAB_OFFLINE_COLOR		@"Tab Offline Color"

#define KEY_LABEL_AWAY_COLOR		@"Away Label Color"
#define KEY_LABEL_IDLE_COLOR		@"Idle Label Color"
#define KEY_LABEL_TYPING_COLOR		@"Typing Label Color"
#define KEY_LABEL_SIGNED_OFF_COLOR	@"Signed Off Label Color"
#define KEY_LABEL_SIGNED_ON_COLOR	@"Signed On Label Color"
#define KEY_LABEL_UNVIEWED_COLOR	@"Unviewed Content Label Color"
#define KEY_LABEL_ONLINE_COLOR		@"Online Label Color"
#define KEY_LABEL_IDLE_AWAY_COLOR	@"Idle And Away Label Color"
#define KEY_LABEL_OFFLINE_COLOR		@"Offline Label Color"

@class AIContactStatusTabColoringPreferences;

@interface AIContactStatusTabColoringPlugin : AIPlugin <AIListObjectObserver, AIFlashObserver> {
    AIContactStatusTabColoringPreferences *preferences;

    NSMutableArray	*flashingListObjectArray;

    BOOL		awayEnabled;
    BOOL		idleEnabled;
    BOOL		signedOffEnabled;
    BOOL		signedOnEnabled;
    BOOL		typingEnabled;
    BOOL		unviewedContentEnabled;
    BOOL		idleAndAwayEnabled;
	BOOL		offlineEnabled;
    BOOL		unviewedFlashEnabled;
    
    NSColor		*awayColor;
    NSColor		*idleColor;
    NSColor		*signedOffColor;
    NSColor		*signedOnColor;
    NSColor		*typingColor;
    NSColor		*unviewedContentColor;
    NSColor		*onlineColor;
    NSColor		*idleAndAwayColor;
	NSColor		*offlineColor;
}

@end
