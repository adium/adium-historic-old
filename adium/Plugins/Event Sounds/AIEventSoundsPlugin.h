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

#define PREF_GROUP_SOUNDS		@"Sounds"

#define SOUND_EVENT_START		@"\nSoundset:\n"	//String marking start of event list
#define SOUND_EVENT_QUOTE		@"\""			//Character before and after event name
#define SOUND_NEWLINE			@"\n"			//Newline character

#define KEY_ALERT_SOUND_PATH		@"SoundPath"

#define KEY_EVENT_CUSTOM_SOUNDSET	@"Event Custom Sounds"
#define KEY_EVENT_SOUND_SET		@"Event Sound Set"
#define	KEY_EVENT_SOUND_PATH		@"Path"
#define	KEY_EVENT_SOUND_NOTIFICATION	@"Notification"
#define KEY_EVENT_MUTE_WHILE_AWAY       @"Mute While Away"

#define SOUND_ALERT_IDENTIFIER        @"Sound"

#define SOUND_MENU_ICON_SIZE		16

#define OTHER_ELLIPSIS      AILocalizedString(@"Other...",nil)
#define OTHER		    AILocalizedString(@"Other",nil)

@class AIEventSoundPreferences;

@interface AIEventSoundsPlugin : AIPlugin <AIActionHandler> {
    AIEventSoundPreferences	*preferences;

    NSArray			*eventSoundArray;
    NSMutableDictionary		*soundPathDict;
}

- (BOOL)loadSoundSetAtPath:(NSString *)inPath creator:(NSString **)outCreator description:(NSString **)outDesc sounds:(NSArray **)outArray;

@end
