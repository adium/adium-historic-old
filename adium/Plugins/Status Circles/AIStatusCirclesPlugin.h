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

#define STATUS_CIRCLES_DEFAULT_PREFS	@"StatusCirclesDefaults"
#define PREF_GROUP_STATUS_CIRCLES	@"StatusCircles"

#define KEY_DISPLAY_STATUS_CIRCLE		@"Display Status Circle"
#define KEY_DISPLAY_STATUS_CIRCLE_ON_LEFT	@"Display Status Circle on Left"
#define KEY_DISPLAY_IDLE_TIME			@"Display Idle Time"
#define KEY_IDLE_TIME_COLOR			@"Idle Time Text Color"

@class AIStatusCirclesPreferences;

@interface AIStatusCirclesPlugin : AIPlugin /*<AIFlashObserver, AIListObjectObserver>*/ {
//    AIStatusCirclesPreferences *preferences;
//
//    BOOL		displayStatusCircle;
//    BOOL		displayStatusCircleOnLeft;
//    BOOL		displayIdleTime;
//    NSColor		*idleStringColor;
}

@end
