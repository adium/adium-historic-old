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

#import <Adium/Adium.h>
#import <Cocoa/Cocoa.h>

#define CONTACT_STATUS_COLORING_DEFAULT_PREFS	@"ContactStatusColoringDefaults"
#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

#define KEY_AWAY_ENABLED		@"Away Enabled"
#define KEY_IDLE_ENABLED		@"Idle Enabled"
#define KEY_TYPING_ENABLED		@"Typing Enabled"
#define KEY_SIGNED_OFF_ENABLED		@"Signed Off Enabled"
#define KEY_SIGNED_ON_ENABLED		@"Signed On Enabled"
#define KEY_UNVIEWED_ENABLED		@"Unviewed Content Enabled"
#define KEY_ONLINE_ENABLED		@"Online Enabled"
#define KEY_IDLE_AWAY_ENABLED		@"Idle And Away Enabled"

#define KEY_AWAY_COLOR			@"Away Color"
#define KEY_IDLE_COLOR			@"Idle Color"
#define KEY_TYPING_COLOR		@"Typing Color"
#define KEY_SIGNED_OFF_COLOR		@"Signed Off Color"
#define KEY_SIGNED_ON_COLOR		@"Signed On Color"
#define KEY_UNVIEWED_COLOR		@"Unviewed Content Color"
#define KEY_ONLINE_COLOR		@"Online Color"
#define KEY_IDLE_AWAY_COLOR		@"Idle And Away Color"

#define KEY_BACK_AWAY_COLOR		@"Away Background Color"
#define KEY_BACK_IDLE_COLOR		@"Idle Background Color"
#define KEY_BACK_TYPING_COLOR		@"Typing Background Color"
#define KEY_BACK_SIGNED_OFF_COLOR	@"Signed Off Background Color"
#define KEY_BACK_SIGNED_ON_COLOR	@"Signed On Background Color"
#define KEY_BACK_UNVIEWED_COLOR		@"Unviewed Content Background Color"
#define KEY_BACK_ONLINE_COLOR		@"Online Background Color"
#define KEY_BACK_IDLE_AWAY_COLOR	@"Idle And Away Background Color"


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
    
    NSColor		*awayColor;
    NSColor		*idleColor;
    NSColor		*signedOffColor;
    NSColor		*signedOnColor;
    NSColor		*typingColor;
    NSColor		*unviewedContentColor;
    NSColor		*onlineColor;
    NSColor		*idleAndAwayColor;
    
    NSColor		*awayInvertedColor;
    NSColor		*idleInvertedColor;
    NSColor		*signedOffInvertedColor;
    NSColor		*signedOnInvertedColor;
    NSColor		*typingInvertedColor;
    NSColor		*unviewedContentInvertedColor;
    NSColor		*onlineInvertedColor;
    NSColor		*idleAndAwayInvertedColor;

    NSColor		*backAwayColor;
    NSColor		*backIdleColor;
    NSColor		*backSignedOffColor;
    NSColor		*backSignedOnColor;
    NSColor		*backTypingColor;
    NSColor		*backUnviewedContentColor;
    NSColor		*backOnlineColor;
    NSColor		*backIdleAndAwayColor;
    
}

@end
