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

#define CONTACT_STATUS_COLORING_DEFAULT_PREFS	@"ContactStatusColoringDefaults"
#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

#define KEY_STATUS_LABEL_OPACITY	@"Status Label Opacity"

#define KEY_AWAY_ENABLED		@"Away Enabled"
#define KEY_IDLE_ENABLED		@"Idle Enabled"
#define KEY_TYPING_ENABLED		@"Typing Enabled"
#define KEY_SIGNED_OFF_ENABLED		@"Signed Off Enabled"
#define KEY_SIGNED_ON_ENABLED		@"Signed On Enabled"
#define KEY_UNVIEWED_ENABLED		@"Unviewed Content Enabled"
#define KEY_ONLINE_ENABLED		@"Online Enabled"
#define KEY_IDLE_AWAY_ENABLED		@"Idle And Away Enabled"
#define KEY_OFFLINE_ENABLED		@"Offline Enabled"

#define KEY_AWAY_COLOR			@"Away Color"
#define KEY_IDLE_COLOR			@"Idle Color"
#define KEY_TYPING_COLOR		@"Typing Color"
#define KEY_SIGNED_OFF_COLOR		@"Signed Off Color"
#define KEY_SIGNED_ON_COLOR		@"Signed On Color"
#define KEY_UNVIEWED_COLOR		@"Unviewed Content Color"
#define KEY_ONLINE_COLOR		@"Online Color"
#define KEY_IDLE_AWAY_COLOR		@"Idle And Away Color"
#define KEY_OFFLINE_COLOR		@"Offline Color"

#define KEY_LABEL_AWAY_COLOR		@"Away Label Color"
#define KEY_LABEL_IDLE_COLOR		@"Idle Label Color"
#define KEY_LABEL_TYPING_COLOR		@"Typing Label Color"
#define KEY_LABEL_SIGNED_OFF_COLOR	@"Signed Off Label Color"
#define KEY_LABEL_SIGNED_ON_COLOR	@"Signed On Label Color"
#define KEY_LABEL_UNVIEWED_COLOR	@"Unviewed Content Label Color"
#define KEY_LABEL_ONLINE_COLOR		@"Online Label Color"
#define KEY_LABEL_IDLE_AWAY_COLOR	@"Idle And Away Label Color"
#define KEY_LABEL_OFFLINE_COLOR		@"Offline Label Color"

#define	PREF_GROUP_CONTACT_LIST		@"Contact List Display"
#define KEY_SCL_OPACITY			@"Opacity"

@class AIContactStatusColoringPreferences;

@interface AIContactStatusColoringPlugin : AIPlugin <AIListObjectObserver, AIFlashObserver> {
    AIContactStatusColoringPreferences *preferences;

    NSMutableArray	*flashingListObjectArray;

    BOOL		awayEnabled;
    BOOL		idleEnabled;
    BOOL		signedOffEnabled;
    BOOL		signedOnEnabled;
    BOOL		typingEnabled;
    BOOL		unviewedContentEnabled;
    BOOL		onlineEnabled;
    BOOL		idleAndAwayEnabled;
	BOOL		offlineEnabled;
    
    NSColor		*awayColor;
    NSColor		*idleColor;
    NSColor		*signedOffColor;
    NSColor		*signedOnColor;
    NSColor		*typingColor;
    NSColor		*unviewedContentColor;
    NSColor		*onlineColor;
    NSColor		*idleAndAwayColor;
	NSColor		*offlineColor;
    
    NSColor		*awayInvertedColor;
    NSColor		*idleInvertedColor;
    NSColor		*signedOffInvertedColor;
    NSColor		*signedOnInvertedColor;
    NSColor		*typingInvertedColor;
    NSColor		*unviewedContentInvertedColor;
    NSColor		*onlineInvertedColor;
    NSColor		*idleAndAwayInvertedColor;
	NSColor		*offlineInvertedColor;
	
    NSColor		*awayLabelColor;
    NSColor		*idleLabelColor;
    NSColor		*signedOffLabelColor;
    NSColor		*signedOnLabelColor;
    NSColor		*typingLabelColor;
    NSColor		*unviewedContentLabelColor;
    NSColor		*onlineLabelColor;
    NSColor		*idleAndAwayLabelColor;
	NSColor		*offlineLabelColor;
	
    float		alpha;
}

@end
