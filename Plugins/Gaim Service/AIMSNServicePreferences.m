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

#import "AIMSNServicePreferences.h"
#import "ESMSNService.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIServiceIcons.h>

@implementation AIMSNServicePreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category
{
    return(AIPref_Advanced);
}
- (NSString *)label
{
    return(AILocalizedString(@"MSN",nil));
}
- (NSString *)nibName
{
    return(@"MSNServicePrefs");
}
- (NSImage *)image
{
	return([AIServiceIcons serviceIconForServiceID:@"MSN" type:AIServiceIconLarge direction:AIIconNormal]);
}
//- (NSDictionary *)restorablePreferences
//{
//	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:STATUS_MENU_ITEM_DEFAULT_PREFS forClass:[self class]];
//	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_STATUS_MENU_ITEM];
//	return(defaultsDict);
//}

- (void)viewDidLoad
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_MSN_SERVICE];
	
	[checkBox_treatDisplayNamesAsStatus setState:[[prefDict objectForKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS] boolValue]];
	[checkBox_conversationClosed setState:[[prefDict objectForKey:KEY_MSN_CONVERSATION_CLOSED] boolValue]];
	[checkBox_conversationTimedOut setState:[[prefDict objectForKey:KEY_MSN_CONVERSATION_TIMED_OUT] boolValue]];
}

- (IBAction)changePreference:(id)sender
{
	if(sender == checkBox_treatDisplayNamesAsStatus){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] 
											 forKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS
											  group:PREF_GROUP_MSN_SERVICE];
		
	}else if(sender == checkBox_conversationClosed){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] 
											 forKey:KEY_MSN_CONVERSATION_CLOSED
											  group:PREF_GROUP_MSN_SERVICE];
		
	}else if(sender == checkBox_conversationTimedOut){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] 
											 forKey:KEY_MSN_CONVERSATION_TIMED_OUT
											  group:PREF_GROUP_MSN_SERVICE];
		
	}		
}

@end
