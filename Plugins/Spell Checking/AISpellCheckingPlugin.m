//
//  AISpellCheckingPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 27 2003.
//

#import "AISpellCheckingPlugin.h"
#import "AISpellCheckingPreferences.h"

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
//    preferences = [[AISpellCheckingPreferences preferencePane] retain];

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
