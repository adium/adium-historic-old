//
//  ESGlobalEventsPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 12/18/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESGlobalEventsPreferencesPlugin.h"
#import "ESGlobalEventsPreferences.h"

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
#define KEY_EVENT_DOCK_BEHAVIOR				@"Behavior"
#define	KEY_EVENT_DOCK_EVENT_ID				@"Notification"
#define KEY_DOCK_BEHAVIOR_TYPE				@"BehaviorType"
#define DOCK_BEHAVIOR_DEFAULT_PREFS	@"DockBehaviorDefaults"
#define DOCK_BEHAVIOR_PRESETS		@"DockBehaviorPresets"

@interface ESGlobalEventsPreferencesPlugin (PRIVATE)
- (NSArray *)soundSetArrayAtPath:(NSString *)inPath creator:(NSString **)outCreator description:(NSString **)outDesc;
- (void)activateSoundSet:(NSArray *)soundSetArray;

- (void)activateDockBehaviorSet:(NSArray *)behaviorArray;
- (NSArray *)behaviorForPreset:(NSString *)presetName;

@end

@implementation ESGlobalEventsPreferencesPlugin

- (void)installPlugin
{
	//Install our preference view
    preferences = [[ESGlobalEventsPreferences preferencePaneForPlugin:self] retain];
	
	//Load dock behavior presets
	NSString	*path;
    path = [[NSBundle bundleForClass:[self class]] pathForResource:DOCK_BEHAVIOR_PRESETS ofType:@"plist"];
    dockBehaviorPresetsArray = [[NSArray arrayWithContentsOfFile:path] retain];
	
	
    //Register default preferences and pre-set behavior
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:EVENT_SOUNDS_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_SOUNDS];	
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_BEHAVIOR_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_DOCK_BEHAVIOR];
	
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
    //Observe preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];
 	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DOCK_BEHAVIOR];

	[[adium notificationCenter] removeObserver:self
										  name:Adium_CompletedApplicationLoad
										object:nil];
}


//Called when the preferences change, reregister for the notifications
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if([group isEqualToString:PREF_GROUP_SOUNDS]){
		NSString		*soundSetPath;
		
		//Load the soundset
		soundSetPath = [prefDict objectForKey:KEY_EVENT_SOUND_SET];
		if(soundSetPath && [soundSetPath length]){ //Soundset
			NSArray			*soundSetArray;

			soundSetArray = [self soundSetArrayAtPath:[soundSetPath stringByExpandingBundlePath]
											  creator:nil
										  description:nil]; //Load the soundset
			[self activateSoundSet:soundSetArray];
		}
	}else if([group isEqualToString:PREF_GROUP_DOCK_BEHAVIOR]){
		NSString		*activeBehaviorSet;
		
		//Load the behaviorSet
		activeBehaviorSet = [prefDict objectForKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET];
		if(activeBehaviorSet && [activeBehaviorSet length] != 0){ //preset
			NSArray			*behaviorArray;
			
			behaviorArray = [self behaviorForPreset:activeBehaviorSet];
			[self activateDockBehaviorSet:behaviorArray];
		}
	}
}



#pragma mark Sound Sets
//Remove all global sound events; add global sound events for the passed sound set
- (void)activateSoundSet:(NSArray *)soundSetArray
{
	NSEnumerator	*enumerator;
	NSDictionary	*eventDict;

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

#pragma mark Dock behavior sets
- (void)activateDockBehaviorSet:(NSArray *)behaviorArray
{
	NSEnumerator	*enumerator;
	NSDictionary	*dictionary;

	//Clear out old global dock behavior alerts
	[[adium contactAlertsController] removeAllGlobalAlertsWithActionID:DOCK_BEHAVIOR_ALERT_IDENTIFIER];
	
	//
	enumerator = [behaviorArray objectEnumerator];
	while((dictionary = [enumerator nextObject])){
		
		NSString		*eventID = [dictionary objectForKey:KEY_EVENT_DOCK_EVENT_ID];
		NSNumber		*behavior = [dictionary objectForKey:KEY_EVENT_DOCK_BEHAVIOR];
		NSDictionary	*dockAlert = [NSDictionary dictionaryWithObjectsAndKeys:eventID, KEY_EVENT_ID,
			DOCK_BEHAVIOR_ALERT_IDENTIFIER, KEY_ACTION_ID, 
			[NSDictionary dictionaryWithObject:behavior forKey:KEY_DOCK_BEHAVIOR_TYPE], KEY_ACTION_DETAILS,nil];

		[[adium contactAlertsController] addGlobalAlert:dockAlert];
	}
}

//Returns the behavior for a preset
- (NSArray *)behaviorForPreset:(NSString *)presetName
{
    NSEnumerator	*enumerator;
    NSDictionary	*set;
    
    //Search for the desired set
    enumerator = [dockBehaviorPresetsArray objectEnumerator];
    while((set = [enumerator nextObject])){
        if([presetName isEqualToString:[set objectForKey:@"Name"]]){
            return([set objectForKey:@"Behavior"]);
        }
    }
    
    return(nil);
}

//Returns an array of the available preset names
- (NSArray *)availableDockBehaviorPresets
{
    NSMutableArray	*availablePresets = [[NSMutableArray alloc] init];
    NSEnumerator	*enumerator;
    NSDictionary	*set;
    
    //Grab the name of each set
    enumerator = [dockBehaviorPresetsArray objectEnumerator];
    while((set = [enumerator nextObject])){
        [availablePresets addObject:[set objectForKey:@"Name"]];
    }
    
    return([availablePresets autorelease]);
}

@end
