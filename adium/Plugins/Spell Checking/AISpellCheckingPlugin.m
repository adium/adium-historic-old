//
//  AISpellCheckingPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AISpellCheckingPlugin.h"
#import "AISpellCheckingPreferences.h"

#define SPELL_CHECKING_DEFAULT_PREFS	@"SpellingDefaults"

@interface AISpellCheckingPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_setSpellCheckingForObject:(id)inObject enabled:(BOOL)enabled;
@end

@implementation AISpellCheckingPlugin

- (void)installPlugin
{
    //Setup our preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SPELL_CHECKING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SPELLING];
    preferences = [[AISpellCheckingPreferences preferencePaneWithOwner:owner] retain];

    //Register as a text entry filter
    [[owner contentController] registerTextEntryFilter:self];

    //Observe preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    BOOL	spellEnabled = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_SPELL_CHECKING] boolValue];

    //Set spellcheck state
    [self _setSpellCheckingForObject:inTextEntryView enabled:spellEnabled];
}

- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Save spellcheck state
    if([inTextEntryView respondsToSelector:@selector(isContinuousSpellCheckingEnabled)]){
        BOOL	spellEnabled = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_SPELL_CHECKING] boolValue];
        BOOL	currentEnabled = [(NSTextView *)inTextEntryView isContinuousSpellCheckingEnabled];

        if(currentEnabled != spellEnabled){
            [[owner preferenceController] setPreference:[NSNumber numberWithBool:currentEnabled] forKey:KEY_SPELL_CHECKING group:PREF_GROUP_SPELLING];
        }
    }
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_SPELLING] == 0){
        BOOL		spellEnabled = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_SPELL_CHECKING] boolValue];
        NSEnumerator	*enumerator;
        id		entryView;

        //Set spellcheck state of all open views
        enumerator = [[[owner contentController] openTextEntryViews] objectEnumerator];
        while(entryView = [enumerator nextObject]){
            [self _setSpellCheckingForObject:entryView enabled:spellEnabled];
        }
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
