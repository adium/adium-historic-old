//
//  AIAwayMessagePreferences.m
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIAwayMessagePreferences.h"

#define AWAY_MESSAGES_PREF_NIB		@"AwayMessagePrefs"	//Name of preference nib
#define AWAY_MESSAGES_PREF_TITLE	@"Away Messages"	//Title of the preference view

@interface AIAwayMessagePreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AIAwayMessagePreferences

+ (AIAwayMessagePreferences *)awayMessagePreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:AWAY_MESSAGES_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:AWAY_MESSAGES_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    
}

@end
