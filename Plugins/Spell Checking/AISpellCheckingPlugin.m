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

#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AISpellCheckingPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>

@interface AISpellCheckingPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_setSpellCheckingForObject:(id)inObject enabled:(BOOL)enabled;
@end

@implementation AISpellCheckingPlugin

- (void)installPlugin
{
    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SPELL_CHECKING_DEFAULT_PREFS 
																		forClass:[self class]]
										  forGroup:PREF_GROUP_SPELLING];

    //Register as a text entry filter
    [[adium contentController] registerTextEntryFilter:self];

    //Observe preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SPELLING];
}

- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    BOOL	spellEnabled = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_SPELL_CHECKING] boolValue];

    //Set spellcheck state
    [self _setSpellCheckingForObject:inTextEntryView enabled:spellEnabled];
}

- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Save spellcheck state
    if([inTextEntryView respondsToSelector:@selector(isContinuousSpellCheckingEnabled)]){
        BOOL	spellEnabled = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_SPELL_CHECKING] boolValue];
        BOOL	currentEnabled = [(NSTextView *)inTextEntryView isContinuousSpellCheckingEnabled];

        if(currentEnabled != spellEnabled){
            [[adium preferenceController] setPreference:[NSNumber numberWithBool:currentEnabled]
												 forKey:KEY_SPELL_CHECKING
												  group:PREF_GROUP_SPELLING];
        }
    }
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	BOOL			spellEnabled = [[prefDict objectForKey:KEY_SPELL_CHECKING] boolValue];
	NSEnumerator	*enumerator;
	id				entryView;
	
	//Set spellcheck state of all open views
	enumerator = [[[adium contentController] openTextEntryViews] objectEnumerator];
	while(entryView = [enumerator nextObject]){
		[self _setSpellCheckingForObject:entryView enabled:spellEnabled];
	}
}

//
- (void)_setSpellCheckingForObject:(id)inObject enabled:(BOOL)enabled
{
    if([inObject respondsToSelector:@selector(setContinuousSpellCheckingEnabled:)]){
        [(NSTextView *)inObject setContinuousSpellCheckingEnabled:enabled];
    }
}

@end
