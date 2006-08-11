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

#import "JLPresencePlugin.h"
#import "AIPreferenceController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>

@interface JLPresencePlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation JLPresencePlugin

- (void)installPlugin
{
	presenceController = nil;
	
	//Register our defaults
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:PRESENCE_PLUGIN_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_PRESENCE_PLUGIN];
	
	//Wait for Adium to finish launching before we perform further actions
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Observe for preference changes, initially loading our status menu item controller
	AIPreferenceController *prefController = [adium preferenceController];
	[prefController addObserver:self
	                 forKeyPath:PREF_KEYPATH_PRESENCE_PLUGIN_ENABLED
	                    options:NSKeyValueObservingOptionNew
	                    context:NULL];
	[self observeValueForKeyPath:PREF_KEYPATH_PRESENCE_PLUGIN_ENABLED
	                    ofObject:prefController
	                      change:nil
	                     context:NULL];
	
	[[adium notificationCenter] removeObserver:self
										  name:Adium_CompletedApplicationLoad
										object:nil];
}

- (void)uninstallPlugin
{
	[[adium preferenceController] removeObserver:self forKeyPath:PREF_KEYPATH_PRESENCE_PLUGIN_ENABLED];
	[presenceController release];
	presenceController = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//AILog(@"JL_DEBUG: Watching keyPath: %@ value: %@", keyPath, [[object valueForKeyPath:keyPath] boolValue]);
	if ([[object valueForKeyPath:keyPath] boolValue]) {
		//If it hasn't been created yet, create it. It will be created visible.
		if (!presenceController) {
			presenceController = [[JLPresenceController presenceController] retain];
		}
		
	} else {
		[presenceController release];
		presenceController = nil;
	}
}

@end
