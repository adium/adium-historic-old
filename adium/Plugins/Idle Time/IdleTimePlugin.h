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


#define IDLE_TIME_DEFAULT_PREFERENCES	@"IdleDefaultPrefs"

#define PREF_GROUP_IDLE_TIME		@"Idle"
#define KEY_IDLE_TIME_ENABLED		@"Idle Enabled"
#define KEY_IDLE_TIME_IDLE_MINUTES	@"Threshold"
#define KEY_AUTO_AWAY_ENABLED		@"Auto Away Enabled"
#define KEY_AUTO_AWAY_IDLE_MINUTES	@"Auto Away Threshold"
#define KEY_AUTO_AWAY_MESSAGE_INDEX @"Auto Away Message Index"

#define PREF_GROUP_AWAY_MESSAGES    @"Away Messages"
#define KEY_SAVED_AWAYS				@"Saved Away Messages"

#define MENU_AWAY_DISPLAY_LENGTH		30

typedef enum {
    AINotIdle = 0,
    AIAutoIdle,
    AIManualIdle,
    AIDelayedManualIdle,
	AIAutoAway
} AIIdleState;

typedef enum {
    SetIdle = 0,
    RemoveIdle,
} ESIdleMenuState;

@protocol AIMiniToolbarItemDelegate;

@class IdleTimeWindowController, IdleTimePreferences;

@interface AIIdleTimePlugin : AIPlugin <AIMiniToolbarItemDelegate> {
    IdleTimePreferences	*preferences;

    BOOL		isIdle;
    NSTimer		*idleTimer;

    BOOL		idleEnabled;
    double		idleThreshold;
	
	BOOL		autoAwayEnabled;
	double		autoAwayThreshold;
	
	double		autoAwayMessageIndex;

    NSMenuItem		*menuItem_setIdle;
    NSMenuItem		*menuItem_removeIdle;
    NSMenuItem          *menuItem_alternate;
    
    AIIdleState		idleState;
    ESIdleMenuState     idleMenuState;
    double		manualIdleTime;

}

- (void)installPlugin;
- (void)uninstallPlugin;
- (void)setIdleState:(AIIdleState)inState;
- (void)setManualIdleTime:(double)inSeconds;
- (void)showManualIdleWindow:(id)sender;

@end
