//
//  AISendingKeyPreferences.m
//  Adium
//
//  Created by Adam Iser on Sat Mar 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "Adium.h"
#import "AISendingKeyPreferences.h"

#define SENDING_KEY_PREF_NIB		@"SendingKeyPrefs"
#define SENDING_KEY_PREF_TITLE		@"Sending Keys"

@interface AISendingKeyPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AISendingKeyPreferences

+ (AISendingKeyPreferences *)sendingKeyPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//User changed a preference
- (IBAction)preferenceChanged:(id)sender
{
    if(sender == checkBox_sendOnEnter){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:@"Send On Enter"
                                              group:PREF_GROUP_GENERAL];
        
    }else if(sender == checkBox_sendOnReturn){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:@"Send On Return"
                                              group:PREF_GROUP_GENERAL];
        
    }
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:SENDING_KEY_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:SENDING_KEY_PREF_TITLE categoryName:PREFERENCE_CATEGORY_OTHER view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    [checkBox_sendOnEnter setState:[[preferenceDict objectForKey:@"Send On Enter"] intValue]];
    [checkBox_sendOnReturn setState:[[preferenceDict objectForKey:@"Send On Return"] intValue]];
}

@end

