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

#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "ESGeneralPreferences.h"
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISendingTextView.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

#define	TAB_DEFAULT_PREFS			@"TabDefaults"

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
	
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SENDING_KEY_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_GENERAL];
	
	//Install our preference view
    preferences = [[ESGeneralPreferences preferencePaneForPlugin:self] retain];	

    //Register as a text entry filter for sending key setting purposes
    [[adium contentController] registerTextEntryFilter:self];

    //Observe preference changes for updating sending key settings
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];	
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
	NSEnumerator	*enumerator;
	id				entryView;
	
	//Set sending keys of all open views
	enumerator = [[[adium contentController] openTextEntryViews] objectEnumerator];
	while(entryView = [enumerator nextObject]){
		[self _configureSendingKeysForObject:entryView];
	}
}

//Configure the message sending keys
- (void)_configureSendingKeysForObject:(id)inObject
{
    if([inObject isKindOfClass:[AISendingTextView class]]){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
			
        [(AISendingTextView *)inObject setSendOnReturn:[[prefDict objectForKey:SEND_ON_RETURN] boolValue]];
		[(AISendingTextView *)inObject setSendOnEnter:[[prefDict objectForKey:SEND_ON_ENTER] boolValue]];
    }
}

#pragma mark Service and status icons


@end
