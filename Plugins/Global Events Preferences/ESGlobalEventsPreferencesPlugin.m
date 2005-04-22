/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AISoundController.h"
#import "ESContactAlertsController.h"
#import "ESGlobalEventsPreferences.h"
#import "ESGlobalEventsPreferencesPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>

#define	NEW_PRESET_NAME				AILocalizedString(@"New Event Set",nil)

#define KEY_ACTIVE_EVENT_SET		@"Active Event Set"
#define KEY_STORED_EVENT_PRESETS	@"Event Presets"
#define	KEY_EVENT_SET_NAME			@"Name"
#define KEY_ORDER_INDEX				@"OrderIndex"
#define KEY_NEXT_ORDER_INDEX		@"NextOrderIndex"

//Sound set defines
#define SOUND_EVENT_START			@"\nSoundset:\n"	//String marking start of event list
#define SOUND_EVENT_QUOTE			@"\""			//Character before and after event name
#define SOUND_NEWLINE				@"\n"			//Newline character
#define KEY_EVENT_CUSTOM_SOUNDSET	@"Event Custom Sounds"
#define	KEY_EVENT_SOUND_PATH		@"Path"
#define	KEY_EVENT_SOUND_EVENT_ID	@"Notification"
#define KEY_ALERT_SOUND_PATH		@"SoundPath"

#define EVENT_SOUNDS_DEFAULT_PREFS	@"EventSoundDefaults"

//Dock behavior defines
#define DOCK_BEHAVIOR_DEFAULT_PREFS			@"DockBehaviorDefaults"
#define DOCK_BEHAVIOR_PRESETS				@"DockBehaviorPresets"
#define KEY_DOCK_PRESET_BEHAVIOR			@"Behavior"
#define	KEY_DOCK_PRESET_EVENT_ID			@"Notification"
#define KEY_DOCK_PRESET_BEHAVIOR_TYPE		@"BehaviorType"

//Speech
#define	SPEECH_PRESETS						@"SpeechPresets"
#define KEY_SPEECH_PRESET_EVENT_ID			@"Notification"
#define	KEY_SPEECH_PRESET_DETAILS			@"Details"

//Growl
#define GROWL_DEFAULT_PREFS					@"GrowlDefaults"
#define	GROWL_PRESETS						@"GrowlPresets"
#define KEY_GROWL_PRESET_EVENT_ID			@"Notification"

@interface ESGlobalEventsPreferencesPlugin (PRIVATE)
- (NSArray *)soundSetArrayAtPath:(NSString *)inPath creator:(NSString **)outCreator description:(NSString **)outDesc;
- (void)activateSoundSet:(NSArray *)soundSetArray;

- (void)activateDockBehaviorSet:(NSArray *)behaviorArray;
- (NSDictionary *)dockAlertFromPresetDictionary:(NSDictionary *)dictionary;

- (void)activateSpeechPreset:(NSArray *)presetArray;
- (NSDictionary *)speechAlertFromDictionary:(NSDictionary *)dictionary;

- (void)activateGrowlPreset:(NSArray *)presetArray;
- (NSDictionary *)growlAlertFromDictionary:(NSDictionary *)dictionary;

- (NSArray *)_behaviorForPreset:(NSString *)presetName inPresetArray:(NSArray *)presetArray;

- (void)_activateSet:(NSArray *)setArray withActionID:(NSString *)actionID alertGenerationSelector:(SEL)selector;
- (NSArray *)_availablePresetsFromArray:(NSArray *)presetsArray;
- (void)_updateActiveSetFromPresetsArray:(NSArray *)presetsArray withActionID:(NSString *)actionID alertGenerationSelector:(SEL)selector preferencesKey:(NSString *)prefKey preferencesGroup:(NSString *)prefGroup;

- (void)applySoundSetWithPath:(NSString *)soundSetPath;
@end

@implementation ESGlobalEventsPreferencesPlugin

- (void)installPlugin
{
	NSString	*activeEventSet;
	
	builtInEventPresets = [[NSDictionary dictionaryNamed:@"BuiltInEventPresets" forClass:[self class]] retain];
	storedEventPresets = [[[adium preferenceController] preferenceForKey:KEY_STORED_EVENT_PRESETS
																   group:PREF_GROUP_EVENT_PRESETS] mutableCopy];
	if(!storedEventPresets) storedEventPresets = [[NSMutableDictionary alloc] init];

	/* If there is no active event set, or the active event set is not present in our built in or stored event sets
	 * then we are in one of two conditions: either this is a first-launch, or the user has deleted the event preferences.
	 * Either way, we want to set ourselves to the default notification set before proceeding.
	 */
	activeEventSet = [[adium preferenceController] preferenceForKey:KEY_ACTIVE_EVENT_SET
															  group:PREF_GROUP_EVENT_PRESETS];
	if(!activeEventSet || (![builtInEventPresets objectForKey:activeEventSet] &&
						   ![storedEventPresets objectForKey:activeEventSet])){
		[self setEventPreset:[builtInEventPresets objectForKey:@"Default Notifications"]];		
	}

	//Install our preference view
    preferences = [[ESGlobalEventsPreferences preferencePaneForPlugin:self] retain];

	//Wait for Adium to finish launching before we perform further actions
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];	
}

- (void)uninstallPlugin
{
    //Uninstall our observers
    [[adium notificationCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	[[adium notificationCenter] removeObserver:self
										  name:Adium_CompletedApplicationLoad
										object:nil];
}


//Called when the preferences change, reregister for the notifications
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{

}

#pragma mark Sound Sets
//Remove all global sound events; add global sound events for the passed sound set
- (void)activateSoundSet:(NSArray *)soundSetArray
{
	NSEnumerator	*enumerator;
	NSDictionary	*eventDict;

	[[adium preferenceController] delayPreferenceChangedNotifications:YES];

	//Clear out old global sound alerts
	[[adium contactAlertsController] removeAllGlobalAlertsWithActionID:SOUND_ALERT_IDENTIFIER];
	
	//        
	enumerator = [soundSetArray objectEnumerator];
	while((eventDict = [enumerator nextObject])){
		
		NSString		*eventID = [eventDict objectForKey:KEY_EVENT_SOUND_EVENT_ID];
		NSString		*soundPath = [eventDict objectForKey:KEY_EVENT_SOUND_PATH];
		NSDictionary	*soundAlert = [NSDictionary dictionaryWithObjectsAndKeys:eventID, KEY_EVENT_ID,
			SOUND_ALERT_IDENTIFIER, KEY_ACTION_ID, 
			[NSDictionary dictionaryWithObject:soundPath forKey: KEY_ALERT_SOUND_PATH], KEY_ACTION_DETAILS,nil];
		
		[[adium contactAlertsController] addGlobalAlert:soundAlert];
	}
	
	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

//Loads various info from a sound set file
- (NSArray *)soundSetArrayAtPath:(NSString *)inPath creator:(NSString **)outCreator description:(NSString **)outDesc
{
    NSCharacterSet	*newlineSet = [NSCharacterSet characterSetWithCharactersInString:SOUND_NEWLINE];
    NSCharacterSet	*whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    NSString		*path;
    NSString		*soundSet;
    NSScanner		*scanner;
	NSMutableArray	*soundArray = nil;
	NSString		*infoPlistPath = [inPath stringByAppendingPathComponent:@"Info.plist"];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath]){
		NSDictionary	*infoDict, *sounds;
		NSEnumerator	*enumerator;
		NSString		*event, *soundName, *soundLocation;
			
		infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
		sounds = [[adium soundController] soundsDictionaryFromDictionary:infoDict usingLocation:&soundLocation];
		
		enumerator = [sounds keyEnumerator];
		while(event = [enumerator nextObject]){
			NSString	*eventID = [[adium contactAlertsController] eventIDForEnglishDisplayName:event];

			soundName = [sounds objectForKey:event];

			if(eventID){
				[soundArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					eventID, KEY_EVENT_SOUND_EVENT_ID,
					[[soundLocation stringByAppendingPathComponent:soundName] stringByCollapsingBundlePath], KEY_EVENT_SOUND_PATH,
					nil]];
			}
		}
		
	}else{
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
	}
	
    return(soundArray);
}

#pragma mark Dock behavior sets
- (void)activateDockBehaviorSet:(NSArray *)behaviorArray
{
	[self _activateSet:behaviorArray withActionID:DOCK_BEHAVIOR_ALERT_IDENTIFIER alertGenerationSelector:@selector(dockAlertFromPresetDictionary:)];
}

#pragma mark Speech presets
- (void)activateSpeechPreset:(NSArray *)presetArray
{
	[self _activateSet:presetArray
		  withActionID:SPEAK_EVENT_ALERT_IDENTIFIER
alertGenerationSelector:@selector(speechAlertFromDictionary:)];
}

#pragma mark Growl presets
- (void)activateGrowlPreset:(NSArray *)presetArray
{
	[self _activateSet:presetArray withActionID:GROWL_EVENT_ALERT_IDENTIFIER alertGenerationSelector:@selector(growlAlertFromDictionary:)];
}

#pragma mark All simple presets
//Returns the behavior for a preset
- (NSArray *)_behaviorForPreset:(NSString *)presetName inPresetArray:(NSArray *)presetArray
{
    NSEnumerator	*enumerator;
    NSDictionary	*set;
    
    //Search for the desired set
    enumerator = [presetArray objectEnumerator];
    while((set = [enumerator nextObject])){
        if([presetName isEqualToString:[set objectForKey:@"Name"]]){
            return([set objectForKey:@"Behavior"]);
        }
    }
    
    return(nil);
}

- (void)_activateSet:(NSArray *)setArray withActionID:(NSString *)actionID alertGenerationSelector:(SEL)selector
{
	NSEnumerator	*enumerator;
	NSDictionary	*dictionary;
	
	//Clear out old global dock behavior alerts
	[[adium contactAlertsController] removeAllGlobalAlertsWithActionID:actionID];
	
	//
	enumerator = [setArray objectEnumerator];
	while((dictionary = [enumerator nextObject])){
		[[adium contactAlertsController] addGlobalAlert:[self performSelector:selector
																   withObject:dictionary]];
	}
}

- (void)setEventPreset:(NSDictionary *)eventPreset
{
	[[adium contactAlertsController] setAllGlobalAlerts:[eventPreset objectForKey:@"Events"]];
	
	/* For a built in set, we now should apply the sound set it specified. User-created sets already include the
	 * soundset as individual events.
	 */
	if([eventPreset objectForKey:@"Built In"] && [[eventPreset objectForKey:@"Built In"] boolValue]){
		[self applySoundSetWithPath:[eventPreset objectForKey:KEY_EVENT_SOUND_SET]];		
	}
	
	//Set the name of the now-active event set, which includes sounds and all other events
	[[adium preferenceController] setPreference:[eventPreset objectForKey:KEY_EVENT_SET_NAME]
										 forKey:KEY_ACTIVE_EVENT_SET
										  group:PREF_GROUP_EVENT_PRESETS];
}

- (float)nextOrderIndex
{
	NSNumber *nextOrderIndexNumber = [[adium preferenceController] preferenceForKey:KEY_NEXT_ORDER_INDEX
																			  group:PREF_GROUP_EVENT_PRESETS];
	float	nextOrderIndex;
	
	nextOrderIndex = (nextOrderIndexNumber ? [nextOrderIndexNumber floatValue] : 1.0);
	
	[[adium preferenceController] setPreference:[NSNumber numberWithFloat:(nextOrderIndex + 1)]
										 forKey:KEY_NEXT_ORDER_INDEX
										  group:PREF_GROUP_EVENT_PRESETS];	

	return nextOrderIndex;
}

/*!
 * @brief Save an event preset
 *
 * This will assign an order index to the preset if necessary and then save it to the stored event presets dictionary.
 * If a preset with the same name exists, it will be overwritten
 */
- (void)saveEventPreset:(NSMutableDictionary *)eventPreset
{
	NSString	*name = [eventPreset objectForKey:KEY_EVENT_SET_NAME];
	//Assign the next order index to this preset if it doesn't have one yet
	if(![eventPreset objectForKey:KEY_ORDER_INDEX]){
		[eventPreset setObject:[NSNumber numberWithFloat:[self nextOrderIndex]]
						forKey:KEY_ORDER_INDEX];
	}

	//If we don't have a name at this point, simply assign one
	if(!name){
		name = NEW_PRESET_NAME;
		
		//Make sure we're not using a name which is already in use
		if([storedEventPresets objectForKey:name]){
			unsigned i = 1;
			name = [NEW_PRESET_NAME stringByAppendingFormat:@" (%i)",i];
			
			while([storedEventPresets objectForKey:name] != nil){
				i++;
				name = [NEW_PRESET_NAME stringByAppendingFormat:@" (%i)",i];
			}
		}
		
		[eventPreset setObject:name
						forKey:KEY_EVENT_SET_NAME];
	}
	
	[storedEventPresets setObject:eventPreset
						   forKey:name];

	[[adium preferenceController] setPreference:storedEventPresets
										 forKey:KEY_STORED_EVENT_PRESETS
										  group:PREF_GROUP_EVENT_PRESETS];
}

/*!
 * @brief Delete an event preset
 */
- (void)deleteEventPreset:(NSDictionary *)eventPreset
{
	[storedEventPresets removeObjectForKey:[eventPreset objectForKey:KEY_EVENT_SET_NAME]];
	
	[[adium preferenceController] setPreference:storedEventPresets
										 forKey:KEY_STORED_EVENT_PRESETS
										  group:PREF_GROUP_EVENT_PRESETS];	
}

/*
 * @brief Apply a sound set
 */
- (void)applySoundSetWithPath:(NSString *)soundSetPath
{
	if(soundSetPath && [soundSetPath length]){ //Soundset
		NSArray			*soundSetArray;
		
		soundSetArray = [self soundSetArrayAtPath:[soundSetPath stringByExpandingBundlePath]
										  creator:nil
									  description:nil]; //Load the soundset
		[self activateSoundSet:soundSetArray];
	}	
}

- (NSDictionary *)builtInEventPresets
{
	return builtInEventPresets;
}

- (NSDictionary *)storedEventPresets
{
	return storedEventPresets;
}

int eventPresetsSort(id eventPresetA, id eventPresetB, void *context)
{
	float orderIndexA = [[eventPresetA objectForKey:KEY_ORDER_INDEX] floatValue];
	float orderIndexB = [[eventPresetB objectForKey:KEY_ORDER_INDEX] floatValue];
	
	if(orderIndexA > orderIndexB){
		return(NSOrderedDescending);
	}else if (orderIndexA < orderIndexB){
		return(NSOrderedAscending);
	}else{
		return([[eventPresetA objectForKey:KEY_EVENT_SET_NAME] caseInsensitiveCompare:[eventPresetB objectForKey:KEY_EVENT_SET_NAME]]);
	}
}

- (NSArray *)storedEventPresetsArray
{
	return [[storedEventPresets allValues] sortedArrayUsingFunction:eventPresetsSort
															 context:nil];
}

- (NSArray *)builtInEventPresetsArray
{
	return [[builtInEventPresets allValues] sortedArrayUsingFunction:eventPresetsSort
															 context:nil];
}

@end
