//
//  AISpellCheckingPreferences.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AISpellCheckingPreferences.h"
#import "AISpellCheckingPlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define SPELL_CHECKING_PREF_TITLE		@"Spell Checking"
#define	SPELL_CHECKING_PREF_NIB			@"SpellCheckingPrefs"

@interface AISpellCheckingPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AISpellCheckingPreferences
//
+ (AISpellCheckingPreferences *)spellCheckingPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
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


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    //init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Sending withDelegate:self label:SPELL_CHECKING_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:SPELL_CHECKING_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;
}

//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING];

    [checkBox_spellChecking setState:[[preferenceDict objectForKey:KEY_SPELL_CHECKING] boolValue]];
}

@end
