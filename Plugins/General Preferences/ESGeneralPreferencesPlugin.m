//
//  ESGeneralPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

/* 
 General Preferences. Currently responsible for:
	- Logging enable/disable
	- Message sending key (enter, return)
	- Message tabs (create in tabs, organize tabs by group, sort tabs)
	- Tab switching keys
	- Sound:
		- Output device (System default vs. system alert)
		- Volume
	- Status icon packs
 
 In the past, these various items were with specific plugins.  While this provides a nice level of abstraction,
 it also makes it much more difficult to ensure a consistent look/feel to the preferences.
*/

#import "ESGeneralPreferencesPlugin.h"
#import "ESGeneralPreferences.h"

#define	TAB_DEFAULT_PREFS			@"TabDefaults"
#define	ICON_PACK_DEFAULT_PREFS		@"IconPackDefaults"

#define	SENDING_KEY_DEFAULT_PREFS	@"SendingKeyDefaults"

@interface ESGeneralPreferencesPlugin (PRIVATE)
- (void)_configureSendingKeysForObject:(id)inObject;
@end

@implementation ESGeneralPreferencesPlugin

- (void)installPlugin
{
	//Defaults
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:TAB_DEFAULT_PREFS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_INTERFACE];
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ICON_PACK_DEFAULT_PREFS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_INTERFACE];
	
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SENDING_KEY_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_GENERAL];
	
	//Install our preference view
    preferences = [[ESGeneralPreferences preferencePaneForPlugin:self] retain];	

    //Register as a text entry filter for sending key setting purposes
    [[adium contentController] registerTextEntryFilter:self];

    //Observe preference changes for updating sending key settings
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];	
	
	//Status/service icon settings
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_INTERFACE];
}

#pragma mark Sending keys
//
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _configureSendingKeysForObject:inTextEntryView]; //Configure the sending keys
}

//
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignore
}

//Update all views in response to a preference change
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if([group isEqualToString:PREF_GROUP_GENERAL]){
		NSEnumerator	*enumerator;
		id				entryView;
		
		//Set sending keys of all open views
		enumerator = [[[adium contentController] openTextEntryViews] objectEnumerator];
		while(entryView = [enumerator nextObject]){
			[self _configureSendingKeysForObject:entryView];
		}
		
	}else{ /* PREF_GROUP_INTERFACE */
		
		//Status icons
		if(firstTime || [key isEqualToString:KEY_STATUS_ICON_PACK]){
			NSString *path;
			
			path = [adium pathOfPackWithName:[prefDict objectForKey:KEY_STATUS_ICON_PACK]
								   extension:@"AdiumStatusIcons"
						  resourceFolderName:@"Status Icons"];

			//If the preferred pack isn't found (it was probably deleted while active), use the default one
			if(!path){
				NSString *name = [[NSDictionary dictionaryNamed:ICON_PACK_DEFAULT_PREFS
													   forClass:[self class]] objectForKey:KEY_STATUS_ICON_PACK];
				path = [adium pathOfPackWithName:name
									   extension:@"AdiumStatusIcons"
							  resourceFolderName:@"Status Icons"];
			}
				
			[AIStatusIcons setActiveStatusIconsFromPath:path];
		}

		//Service icons
		if(firstTime || [key isEqualToString:KEY_SERVICE_ICON_PACK]){
			NSString *path;
			
			path = [adium pathOfPackWithName:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]
								   extension:@"AdiumServiceIcons"
						  resourceFolderName:@"Service Icons"];
			
			//If the preferred pack isn't found (it was probably deleted while active), use the default one
			if(!path){
				NSString *name = [[NSDictionary dictionaryNamed:ICON_PACK_DEFAULT_PREFS
													   forClass:[self class]] objectForKey:KEY_SERVICE_ICON_PACK];
				path = [adium pathOfPackWithName:name
									   extension:@"AdiumServiceIcons"
							  resourceFolderName:@"Service Icons"];
			}
			
			[AIServiceIcons setActiveServiceIconsFromPath:path];
		}
	}
}

//Configure the message sending keys
- (void)_configureSendingKeysForObject:(id)inObject
{
    if([inObject isKindOfClass:[AISendingTextView class]]){
        [(AISendingTextView *)inObject setSendOnReturn:[[[[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL] objectForKey:SEND_ON_RETURN] boolValue]];
		[(AISendingTextView *)inObject setSendOnEnter:[[[[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL] objectForKey:SEND_ON_ENTER] boolValue]];
    }
}

#pragma mark Service and status icons


@end
