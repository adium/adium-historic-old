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

#import "AIEventSoundsPlugin.h"
#import "AIEventSoundPreferences.h"
#import "ESEventSoundAlertDetailPane.h"

#define EVENT_SOUNDS_DEFAULT_PREFS	@"EventSoundDefaults"
#define EVENT_SOUNDS_ALERT_SHORT	AILocalizedString(@"Play a sound",nil)
#define EVENT_SOUNDS_ALERT_LONG		AILocalizedString(@"Play the sound \"%@\"",nil)

@interface AIEventSoundsPlugin (PRIVATE)
- (void)eventNotification:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
- (BOOL)_upgradeEventSoundArray;
@end

@implementation AIEventSoundsPlugin

- (void)installPlugin
{
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:SOUND_ALERT_IDENTIFIER withHandler:self];
    
    //Setup our preferences
    preferences = [[AIEventSoundPreferences preferencePaneForPlugin:self] retain];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:EVENT_SOUNDS_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SOUNDS];

    //Observe preference changes
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	
	//Wait for Adium to finish launching before we set up our sounds so the event plugins are ready
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_PluginsDidFinishLoading
									 object:nil];
}

- (void)uninstallPlugin
{
    //[[adium contactController] unregisterHandleObserver:self];
    //remove observers
    
    //Uninstall our contact alert
//    [[adium contactAlertsController] unregisterContactAlertProvider:self];
    [[adium notificationCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//If no upgrade occurred, call preferences manually
	if (![self _upgradeEventSoundArray]){
		[self preferencesChanged:nil];
	}
	
	[[adium notificationCenter] removeObserver:self
										  name:Adium_PluginsDidFinishLoading
										object:nil];
}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_SOUNDS]){
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
        NSString		*soundSetPath;
        NSEnumerator	*enumerator;
        NSDictionary	*eventDict;
		NSArray			*eventSoundArray;
		
        //Load the soundset
        soundSetPath = [preferenceDict objectForKey:KEY_EVENT_SOUND_SET];
        if(soundSetPath && [soundSetPath length] != 0){ //Soundset
            eventSoundArray = [self loadSoundSetAtPath:[soundSetPath stringByExpandingBundlePath] creator:nil description:nil]; //Load the soundset
        }else{ //Custom
            eventSoundArray = [preferenceDict objectForKey:KEY_EVENT_CUSTOM_SOUNDSET]; //Load the user's custom set
        }
		
		//Clear out old global sound alerts
		[[adium contactAlertsController] removeAllGlobalAlertsWithActionID:SOUND_ALERT_IDENTIFIER];

		//        
        enumerator = [eventSoundArray objectEnumerator];
        while((eventDict = [enumerator nextObject])){

            NSString		*eventID = [eventDict objectForKey:KEY_EVENT_SOUND_EVENT_ID];
            NSString		*soundPath = [eventDict objectForKey:KEY_EVENT_SOUND_PATH];
			NSDictionary	*soundAlert = [NSDictionary dictionaryWithObjectsAndKeys:eventID, KEY_EVENT_ID,
				SOUND_ALERT_IDENTIFIER, KEY_ACTION_ID, 
				[NSDictionary dictionaryWithObject:soundPath forKey: KEY_ALERT_SOUND_PATH], KEY_ACTION_DETAILS,nil];
			
            [[adium contactAlertsController] addGlobalAlert:soundAlert];
        }
    }
}

//Loads various info from a sound set file
- (NSArray *)loadSoundSetAtPath:(NSString *)inPath creator:(NSString **)outCreator description:(NSString **)outDesc
{
    NSCharacterSet	*newlineSet = [NSCharacterSet characterSetWithCharactersInString:SOUND_NEWLINE];
    NSCharacterSet	*whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    NSString		*path;
    NSString		*soundSet;
    NSScanner		*scanner;
	NSMutableArray	*soundArray = nil;
	
    //Open the soundset.rtf file
    path = [NSString stringWithFormat:@"%@/%@.txt", inPath, [[inPath stringByDeletingPathExtension] lastPathComponent]];
	
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
		soundArray = [NSMutableArray array];
		
		while(![scanner isAtEnd]){
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
			NSString	*eventID = [[adium contactAlertsController] eventIDForEnglishDisplayName:event];
			if (eventID){
				//Add this sound to our array
				[soundArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					eventID, KEY_EVENT_SOUND_EVENT_ID,
					[[inPath stringByAppendingPathComponent:soundPath] stringByCollapsingBundlePath], KEY_EVENT_SOUND_PATH,
					nil]];
			}
		}
	}
	
    return(soundArray);
}

- (BOOL)_upgradeEventSoundArray
{
	NSArray			*eventSoundArray = [[adium preferenceController] preferenceForKey:KEY_EVENT_CUSTOM_SOUNDSET
																				group:PREF_GROUP_SOUNDS]; //Load the user's custom set
	
	NSMutableArray  *upgradedArray = [NSMutableArray array];
	NSDictionary	*eventDict;
	NSEnumerator	*enumerator;
	BOOL			madeChanges = NO;
	
	//        
	enumerator = [eventSoundArray objectEnumerator];
	while((eventDict = [enumerator nextObject])){
		
		NSMutableDictionary *upgradedEventDict = nil;
		NSString			*eventID = [eventDict objectForKey:KEY_EVENT_SOUND_EVENT_ID];
		if ([eventID isEqualToString:@"Contact_StatusOnlineNO"]){
			upgradedEventDict = 		[[eventDict mutableCopy] autorelease];
			[upgradedEventDict setObject:CONTACT_STATUS_ONLINE_NO forKey:KEY_EVENT_SOUND_EVENT_ID];
			
		}else if ([eventID isEqualToString:@"Content_FirstContentRecieved"]){
			upgradedEventDict = 		[[eventDict mutableCopy] autorelease];
			[upgradedEventDict setObject:CONTENT_MESSAGE_RECEIVED_FIRST forKey:KEY_EVENT_SOUND_EVENT_ID];
			
		}else if ([eventID isEqualToString:@"Content_DidReceiveContent"]){
			upgradedEventDict = 		[[eventDict mutableCopy] autorelease];
			[upgradedEventDict setObject:CONTENT_MESSAGE_RECEIVED forKey:KEY_EVENT_SOUND_EVENT_ID];
			
		}else if ([eventID isEqualToString:@"Content_DidSendContent"]){
			upgradedEventDict = 		[[eventDict mutableCopy] autorelease];
			[upgradedEventDict setObject:CONTENT_MESSAGE_SENT forKey:KEY_EVENT_SOUND_EVENT_ID];
			
		}
		
		if (upgradedEventDict){
			madeChanges = YES;
			[upgradedArray addObject:upgradedEventDict];
		}else{
			[upgradedArray addObject:eventDict];	
		}
	}
	
	if (madeChanges){
		[[adium preferenceController] setPreference:upgradedArray
											 forKey:KEY_EVENT_CUSTOM_SOUNDSET
											  group:PREF_GROUP_SOUNDS];
		return YES;
	}
	
	return NO;
	
}

//Play Sound Alert -----------------------------------------------------------------------------------------------------
#pragma mark Play Sound Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(EVENT_SOUNDS_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*fileName = [[details objectForKey:KEY_ALERT_SOUND_PATH] lastPathComponent];
	
	if(fileName && [fileName length]){
		return([NSString stringWithFormat:EVENT_SOUNDS_ALERT_LONG, fileName]);
	}else{
		return(EVENT_SOUNDS_ALERT_LONG);
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"SoundAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESEventSoundAlertDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSString	*soundPath = [[details objectForKey:KEY_ALERT_SOUND_PATH] stringByExpandingBundlePath];
	[[adium soundController] playSoundAtPath:soundPath];
}

@end

