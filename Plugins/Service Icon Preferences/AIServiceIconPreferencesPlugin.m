//
//  AIServiceIconPreferencesPlugin.m
//  Adium
//
//  Created by Adam Iser on 10/30/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIServiceIconPreferencesPlugin.h"

@interface AIServiceIconPreferencesPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIServiceIconPreferencesPlugin

- (void)installPlugin
{
    //Setup our preferences
//    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_MESSAGE_DEFAULT_PREFS forClass:[self class]]
//										  forGroup:PREF_GROUP_IDLE_MESSAGE];
//    preferences = [[IdleMessagePreferences preferencePane] retain];
	
	//Observe preference changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	
	[self preferencesChanged:nil];
}

//Hard coded icon pack for now
- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil){
		NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Status Icons"] stringByExpandingTildeInPath];
		[AIStatusIcons setActiveStatusIconsFromPath:[path stringByAppendingPathComponent:@"Gems.AdiumStatusIcons"]];
	}
}

@end
