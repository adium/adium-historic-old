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

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

#define STATUS_EVENTS_DEFAULT_PREFS	@"ContactStatusEventsDefaults"
#define PREF_GROUP_STATUS_EVENTS	@"Contact Status Events"

#define KEY_SIGNED_OFF_LENGTH			@"Signed Off Length"
#define KEY_SIGNED_ON_LENGTH			@"Signed On Length"

@protocol AIListObjectObserver;
@class AIContactStatusEventsPreferences;

@interface AIContactStatusEventsPlugin : AIPlugin <AIListObjectObserver> {
    AIContactStatusEventsPreferences	*preferences;
    
    NSMutableDictionary		*onlineDict;
    NSMutableDictionary		*awayDict;
    NSMutableDictionary		*idleDict;

    int		signedOffLength;
    int		signedOnLength;

}

- (void)installPlugin;
- (void)uninstallPlugin;
- (void)preferencesChanged:(NSNotification *)notification;

@end
