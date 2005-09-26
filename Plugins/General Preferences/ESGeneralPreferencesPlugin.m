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
	AIPreferenceController *preferenceController = [adium preferenceController];
	[preferenceController registerDefaults:[NSDictionary dictionaryNamed:TAB_DEFAULT_PREFS
	                                                            forClass:[self class]]
	                                                            forGroup:PREF_GROUP_INTERFACE];
	
	[preferenceController registerDefaults:[NSDictionary dictionaryNamed:SENDING_KEY_DEFAULT_PREFS
	                                                            forClass:[self class]]
	                                                            forGroup:PREF_GROUP_GENERAL];

	//Install our preference view
	preferences = [[ESGeneralPreferences preferencePaneForPlugin:self] retain];	

}

- (void)uninstallPlugin
{

}

@end
