//
//  LNStatusIconsPreferences.m
//  Adium
//
//  Created by Laura Natcher on Wed Oct 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "LNStatusIconsPlugin.h"
#import "LNStatusIconsPreferences.h"


#define	STATUS_ICONS_PREF_NIB		@"StatusIconsPrefs"
#define STATUS_ICONS_PREF_TITLE		@"Status Icons Display"

@interface LNStatusIconsPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation LNStatusIconsPreferences

+ (LNStatusIconsPreferences *)statusIconsPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}



- (IBAction)changePreference:(id)sender
{

    if(sender == checkBox_displayStatusIcons){
    
    	[[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
					     forKey:KEY_DISPLAY_STATUS_ICONS
					      group:PREF_GROUP_STATUS_ICONS];
    }

}


- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Contacts withDelegate:self label:STATUS_ICONS_PREF_TITLE]];

    return(self);
}


- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:STATUS_ICONS_PREF_NIB owner:self];

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

- (void)configureView
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_STATUS_ICONS];

    [checkBox_displayStatusIcons setState:[[preferenceDict objectForKey:KEY_DISPLAY_STATUS_ICONS] boolValue]];

}



@end
