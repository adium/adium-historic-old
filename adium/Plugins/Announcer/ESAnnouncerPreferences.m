//
//  ESAnnouncerPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESAnnouncerPreferences.h"
#import "ESAnnouncerPlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define ANNOUNCER_PREF_TITLE 	@"Text-to-Speech: Announcer"
#define ANNOUNCER_PREF_NIB 	@"AnnouncerPrefs.nib"
@interface ESAnnouncerPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation ESAnnouncerPreferences
+ (ESAnnouncerPreferences *)announcerPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_outgoing){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_OUTGOING
									group:PREF_GROUP_SOUNDS];
    } else if(sender == checkBox_incoming){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_INCOMING
									group:PREF_GROUP_SOUNDS];
    } else if(sender == checkBox_status){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_STATUS
									group:PREF_GROUP_SOUNDS];
    } else if(sender == checkBox_time){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_TIME
									group:PREF_GROUP_SOUNDS];
    } else if(sender == checkBox_sender){
	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									forKey:KEY_ANNOUNCER_SENDER
									group:PREF_GROUP_SOUNDS];
    }
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Sound withDelegate:self label:ANNOUNCER_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:ANNOUNCER_PREF_NIB owner:self];

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
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];

    [checkBox_outgoing setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_OUTGOING] boolValue]];
    [checkBox_incoming setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_INCOMING] boolValue]];
    [checkBox_status setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_STATUS] boolValue]];
    [checkBox_time setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_TIME] boolValue]];
    [checkBox_sender setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_SENDER] boolValue]];
}
@end
