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

#import "AIAppearancePreferencesPlugin.h"
#import "AIAppearancePreferences.h"
#import "AIDockController.h"
#import <Adium/AIStatusIcons.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIDictionaryAdditions.h>

#define APPEARANCE_DEFAUT_PREFS 	@"AppearanceDefaults"

@implementation AIAppearancePreferencesPlugin

- (void)installPlugin
{
	AIPreferenceController *preferenceController = [adium preferenceController];

	//Prepare our preferences
	[preferenceController registerDefaults:[NSDictionary dictionaryNamed:APPEARANCE_DEFAUT_PREFS
	                              forClass:[self class]] 
	                              forGroup:PREF_GROUP_APPEARANCE];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];	

	preferences = [[AIAppearancePreferences preferencePaneForPlugin:self] retain];	

	[[adium notificationCenter] addObserver:self
								   selector:@selector(invalidStatusSetActivated:)
									   name:AIStatusIconSetInvalidSetNotification
									 object:nil];
	
//	[preferenceController registerDefaults:[NSDictionary dictionaryNamed:ICON_PACK_DEFAULT_PREFS
//	                              forClass:[self class]] 
//	                              forGroup:PREF_GROUP_INTERFACE];
//	
//	[preferenceController registerDefaults:[NSDictionary dictionaryNamed:SENDING_KEY_DEFAULT_PREFS
//	                              forClass:[self class]]
//	                              forGroup:PREF_GROUP_GENERAL];
}	

- (void)uninstallPlugin
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

/*!
 * @brief Apply changed preferences
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Status icons
	if (firstTime || [key isEqualToString:KEY_STATUS_ICON_PACK]) {
		NSString *path = [adium pathOfPackWithName:[prefDict objectForKey:KEY_STATUS_ICON_PACK]
										 extension:@"AdiumStatusIcons"
								resourceFolderName:@"Status Icons"];
		
		//If the preferred pack isn't found (it was probably deleted while active), use the default one
		if (!path) {
			NSString *name = [[adium preferenceController] defaultPreferenceForKey:KEY_STATUS_ICON_PACK
																			 group:PREF_GROUP_APPEARANCE
																			object:nil];
			path = [adium pathOfPackWithName:name
								   extension:@"AdiumStatusIcons"
						  resourceFolderName:@"Status Icons"];
		}
		
		[AIStatusIcons setActiveStatusIconsFromPath:path];
	}
	
	//Service icons
	if (firstTime || [key isEqualToString:KEY_SERVICE_ICON_PACK]) {
		NSString *path = [adium pathOfPackWithName:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]
										 extension:@"AdiumServiceIcons"
								resourceFolderName:@"Service Icons"];
		
		//If the preferred pack isn't found (it was probably deleted while active), use the default one
		if (!path) {
			NSString *name = [[adium preferenceController] defaultPreferenceForKey:KEY_SERVICE_ICON_PACK
																			 group:PREF_GROUP_APPEARANCE
																			object:nil];
			path = [adium pathOfPackWithName:name
								   extension:@"AdiumServiceIcons"
						  resourceFolderName:@"Service Icons"];
		}
		
		[AIServiceIcons setActiveServiceIconsFromPath:path];
	}
}

/*
 * @brief An invalid status set was activated
 *
 * Reset to the default by clearing our preference
 */
- (void)invalidStatusSetActivated:(NSNotification *)inNotification
{
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_STATUS_ICON_PACK
										  group:PREF_GROUP_APPEARANCE];
	
	//Tell the preferences to update
	[preferences xtrasChanged:nil];
}

@end
