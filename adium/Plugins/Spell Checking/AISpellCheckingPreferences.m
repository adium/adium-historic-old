//
//  AISpellCheckingPreferences.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
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

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING];
    
    [checkBox_spellChecking setState:[[preferenceDict objectForKey:KEY_SPELL_CHECKING] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_spellChecking){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SPELL_CHECKING
                                              group:PREF_GROUP_SPELLING];
        
    }
}

@end
