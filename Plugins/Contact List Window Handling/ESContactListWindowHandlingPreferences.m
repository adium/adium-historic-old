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

#import "ESContactListWindowHandlingPreferences.h"
#import "ESContactListWindowHandlingPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/ESImageAdditions.h>

#define CLWH_PREF_TITLE	AILocalizedString(@"Contact List","Contact List Window Handling")
#define CLWH_PREF_NIB	@"ContactListWindowHandlingPrefs"

@class AIPreferenceWindowController;

@interface ESContactListWindowHandlingPreferences (PRIVATE)
- (void)configureView;
@end

@implementation ESContactListWindowHandlingPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced);
}
- (NSString *)label{
    return(CLWH_PREF_TITLE);
}
- (NSString *)nibName{
    return(CLWH_PREF_NIB);
}
- (NSImage *)image{
	return([NSImage imageNamed:@"pref-contactList" forClass:[AIPreferenceWindowController class]]);
}
//
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
	int 			menuIndex = [window_position_menu indexOfItemWithTag:[[preferenceDict objectForKey:KEY_CLWH_WINDOW_POSITION] intValue]];
	
	if(menuIndex >= 0 && menuIndex < [window_position_menu numberOfItems]){
		[window_position_menu selectItemAtIndex:menuIndex];
	}
    [checkBox_hide setState:[[preferenceDict objectForKey:KEY_CLWH_HIDE] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == window_position_menu){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_CLWH_WINDOW_POSITION
											  group:PREF_GROUP_CONTACT_LIST];
		
	}else if(sender == checkBox_hide){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CLWH_HIDE
											  group:PREF_GROUP_CONTACT_LIST];
		
    }
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:CONTACT_LIST_WINDOW_HANDLING_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_CONTACT_LIST];	
	return(defaultsDict);
}

@end
