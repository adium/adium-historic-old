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

#import "AIPreferenceController.h"
#import "CBStatusMenuItemPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>

@interface CBStatusMenuItemPlugin(PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation CBStatusMenuItemPlugin

- (void)installPlugin
{
    //We're Panther only
    if([NSApp isOnPantherOrBetter]){
    
        //Just in case
        itemController = nil;
        
        //Register our defaults
        [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_MENU_ITEM_DEFAULT_PREFS 
                                              forClass:[self class]]
                                              forGroup:PREF_GROUP_STATUS_MENU_ITEM];

		//Wait for Adium to finish launching before we perform further actions
		[[adium notificationCenter] addObserver:self
									   selector:@selector(adiumFinishedLaunching:)
										   name:Adium_CompletedApplicationLoad
										 object:nil];
	}		
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Observe for preference changes, initially loading our status menu item controller if necessary
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_STATUS_MENU_ITEM];

	[[adium notificationCenter] removeObserver:self
										  name:Adium_CompletedApplicationLoad
										object:nil];
}

- (void)uninstallPlugin
{
    if([NSApp isOnPantherOrBetter]){
		[[adium preferenceController] unregisterPreferenceObserver:self];
        [itemController release]; itemController = nil;
    }
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if([[prefDict objectForKey:KEY_STATUS_MENU_ITEM_ENABLED] boolValue]){
		//If it hasn't been created yet, create it. Otherwise, tell it to show itself.
		if(!itemController){
			itemController = [CBStatusMenuItemController statusMenuItemController];
		}else{
			[itemController showStatusItem];
		}
	}else{
		//if it exists, tell it to hide itself
		if(itemController){
			[itemController hideStatusItem];
		}
	}
}

@end
