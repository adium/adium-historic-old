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

#import "AIEventSoundsPlugin.h"
#import "AIEventSoundPreferences.h"

#define EVENT_SOUNDS_DEFAULT_PREFS	@"EventSoundDefaults"

@interface AIEventSoundsPlugin (PRIVATE)
- (void)eventNotification:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIEventSoundsPlugin

- (void)installPlugin
{
    //
    soundPathDict = nil;

    //Setup our preferences
    preferences = [[AIEventSoundPreferences preferencePaneWithPlugin:self owner:owner] retain];
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:EVENT_SOUNDS_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SOUNDS];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
    //remove observers
    [[owner notificationCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
}


//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_SOUNDS] == 0){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
        NSString	*soundSetPath;
        NSEnumerator	*enumerator;
        NSDictionary	*eventDict;

        //Reset our observations
        [[owner notificationCenter] removeObserver:self];
        [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
        
        //Load the soundset
        [eventSoundArray release]; eventSoundArray = nil;
        
        soundSetPath = [preferenceDict objectForKey:KEY_EVENT_SOUND_SET];
        if(soundSetPath && [soundSetPath length] != 0){ //Soundset
            [self loadSoundSetAtPath:[soundSetPath stringByExpandingBundlePath] creator:nil description:nil sounds:&eventSoundArray]; //Load the soundset
        }else{ //Custom
            eventSoundArray = [[preferenceDict objectForKey:KEY_EVENT_CUSTOM_SOUNDSET] retain]; //Load the user's custom set
        }

        //Put the sound paths into a dictionary (so it's quicker to lookup sounds), and observe the notifications
        [soundPathDict release]; soundPathDict = [[NSMutableDictionary alloc] init];

        enumerator = [eventSoundArray objectEnumerator];
        while((eventDict = [enumerator nextObject])){
            NSString	*notificationName = [eventDict objectForKey:KEY_EVENT_SOUND_NOTIFICATION];
            NSString	*soundPath = [eventDict objectForKey:KEY_EVENT_SOUND_PATH];

            //Observe the notification
            [[owner notificationCenter] addObserver:self
                                           selector:@selector(eventNotification:)
                                               name:notificationName
                                             object:nil];

            //Add the sound path to our dictionary
            [soundPathDict setObject:soundPath forKey:notificationName];
        }
    }
}

- (void)eventNotification:(NSNotification *)notification
{
    NSDictionary    *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
    if (!([[preferenceDict objectForKey:KEY_EVENT_MUTE_WHILE_AWAY] boolValue] && [[owner accountController] propertyForKey:@"AwayMessage" account:nil]))
        [[owner soundController] playSoundAtPath:[soundPathDict objectForKey:[notification name]]];
}



//Loads various info from a sound set file
- (BOOL)loadSoundSetAtPath:(NSString *)inPath creator:(NSString **)outCreator description:(NSString **)outDesc sounds:(NSArray **)outArray
{
    NSCharacterSet	*newlineSet = [NSCharacterSet characterSetWithCharactersInString:SOUND_NEWLINE];
    NSCharacterSet	*whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    NSString		*path;
    NSString		*soundSet;
    NSScanner		*scanner;
    BOOL		success = NO;

    //Open the soundset.rtf file
    path = [NSString stringWithFormat:@"%@/%@.txt", inPath, [inPath lastPathComponent]];
    soundSet = [NSString stringWithContentsOfFile:path];

    if(soundSet && [soundSet length] != 0){
        //Setup the scanner
        scanner = [NSScanner scannerWithString:soundSet];
        [scanner setCaseSensitive:NO];
        [scanner setCharactersToBeSkipped:whitespaceSet];

        //Scan the creator
        [scanner scanUpToCharactersFromSet:newlineSet intoString:(outCreator ? outCreator : nil)];
        [scanner scanCharactersFromSet:newlineSet intoString:nil];

        //Scan the description
        [scanner scanUpToString:SOUND_EVENT_START intoString:(outDesc ? outDesc : nil)];
        [scanner scanString:SOUND_EVENT_START intoString:nil];

        //Scan the events
        if(outArray){
            NSMutableArray	*soundArray = [[NSMutableArray alloc] init];

            while(![scanner isAtEnd]){
                NSEnumerator	*enumerator;
                NSDictionary	*eventDict;
                NSString	*event;
                NSString	*soundPath;

                [scanner scanUpToString:SOUND_EVENT_QUOTE intoString:nil];
                [scanner scanString:SOUND_EVENT_QUOTE intoString:nil];

                //get the event display name
                [scanner scanUpToString:SOUND_EVENT_QUOTE intoString:&event];
                [scanner scanString:SOUND_EVENT_QUOTE intoString:nil];

                //and sound
                [scanner scanUpToCharactersFromSet:newlineSet intoString:&soundPath];
                [scanner scanCharactersFromSet:newlineSet intoString:nil];

                //Locate the notification associated with the given display name
                enumerator = [[[owner eventNotifications] allValues] objectEnumerator];
                while((eventDict = [enumerator nextObject])){
                    if([event compare:[eventDict objectForKey:KEY_EVENT_DISPLAY_NAME]] == 0){
                        //Add this sound to our array
                        [soundArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[eventDict objectForKey:KEY_EVENT_NOTIFICATION], KEY_EVENT_SOUND_NOTIFICATION, [inPath stringByAppendingPathComponent:soundPath], KEY_EVENT_SOUND_PATH, nil]];
                    }
                }
            }

            *outArray = soundArray;
            success = YES;
        }
    }

    return(success);
}


@end
