//
//  AITextProfilePreferences.m
//  Adium
//
//  Created by Adam Iser on Fri Jan 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITextProfilePreferences.h"

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define TEXT_PROFILE_PREF_NIB		@"TextProfilePrefs"	//Name of preference nib
#define TEXT_PROFILE_PREF_TITLE		@"Profile"		//Title of the preference view

#define ADIUM_DEFAULT_PROFILE_STRING	@"Adium (www.adiumx.com)"	//Default user profile

@interface AITextProfilePreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AITextProfilePreferences
+ (AITextProfilePreferences *)textProfilePreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (void)textDidEndEditing:(NSNotification *)notification;
{
    [[owner accountController] setStatusObject:[[textView_textProfile textStorage] dataRepresentation] forKey:@"TextProfile" account:nil];
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:TEXT_PROFILE_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:TEXT_PROFILE_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    NSAttributedString	*profile = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"TextProfile" account:nil]];

    if(!profile){
        profile = [[NSAttributedString alloc] initWithString:ADIUM_DEFAULT_PROFILE_STRING];
    }
    
    [[textView_textProfile textStorage] setAttributedString:profile];
}

@end
