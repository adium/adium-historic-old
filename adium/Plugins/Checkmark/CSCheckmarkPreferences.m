//
//  CSCheckmarkPreferences.m
//  Adium XCode
//
//  Created by Chris Serino on Sun Jan 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CSCheckmarkPlugin.h"
#import "CSCheckmarkPreferences.h"


#define	CHECKMARK_PREF_NIB		@"CheckmarkPreferences"
#define CHECKMARK_PREF_TITLE		@"Checkmark Display"

@interface CSCheckmarkPreferences (PRIVATE)
- (void)configureView;
@end

@implementation CSCheckmarkPreferences

+ (CSCheckmarkPreferences *)checkmarkPreferences
{
    return([[[self alloc] init] autorelease]);
}



- (IBAction)changePreference:(id)sender
{
	
    if(sender == checkBox_displayCheckmark){
		
    	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_DISPLAY_CHECKMARK
											  group:PREF_GROUP_CHECKMARK];
    }
	
}


- (id)init
{
    //Init
    [super init];
	
    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Advanced_ContactList withDelegate:self label:CHECKMARK_PREF_TITLE]];
	
    return(self);
}


- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:CHECKMARK_PREF_NIB owner:self];
		
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
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CHECKMARK];
	
    [checkBox_displayCheckmark setState:[[preferenceDict objectForKey:KEY_DISPLAY_CHECKMARK] boolValue]];
	
}

@end
