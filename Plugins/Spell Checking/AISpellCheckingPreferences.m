//
//  AISpellCheckingPreferences.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 27 2003.
//

#import "AISpellCheckingPreferences.h"
#import "AISpellCheckingPlugin.h"

@implementation AISpellCheckingPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Spell Checking");
}
- (NSString *)nibName{
    return(@"SpellCheckingPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:SPELL_CHECKING_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_SPELLING];
	return(defaultsDict);
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SPELLING];
    
    [checkBox_spellChecking setState:[[preferenceDict objectForKey:KEY_SPELL_CHECKING] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_spellChecking){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SPELL_CHECKING
                                              group:PREF_GROUP_SPELLING];
        
    }
}

@end
