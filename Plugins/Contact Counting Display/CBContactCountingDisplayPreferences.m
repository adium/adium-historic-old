//
//  CBContactCountingDisplayPreferences.m
//  Adium XCode
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBContactCountingDisplayPreferences.h"
#import "CBContactCountingDisplayPlugin.h"

/* useful code snippet
    groupsPane = [AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Groups withDelegate:self label:CL_PREF_GROUPS_TITLE];
    [[adium preferenceController] addPreferencePane:groupsPane];

#define PREF_GROUP_CONTACT_LIST     @"Contact List"
#define KEY_COUNT_ALL_CONTACTS      @"Count All Contacts"
#define KEY_COUNT_VISIBLE_CONTACTS  @"Count Visible Contacts"
*/

#define CONTACT_COUNTING_NIB	@"ContactCountingDisplay"
#define CONTACT_COUNTING_LABEL  @"Contact Count Display"

@interface CBContactCountingDisplayPreferences (PRIVATE)

- (void)configureView;

@end

@implementation CBContactCountingDisplayPreferences

+ (CBContactCountingDisplayPreferences *)contactCountingDisplayPreferences
{
    return([[[self alloc] init] autorelease]);
}

- (IBAction)changePreference:(id)sender
{
	
    if(sender == checkBox_visibleContacts){
    	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_COUNT_VISIBLE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST];
    } else if(sender == checkBox_allContacts) {
    	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_COUNT_ALL_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST];
    }
	
}

- (id)init
{
    //Init
    [super init];
	
    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Groups withDelegate:self label:CONTACT_COUNTING_LABEL]];
	
    return(self);
}


- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:CONTACT_COUNTING_NIB owner:self];
		
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
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
	
    [checkBox_visibleContacts setState:[[preferenceDict objectForKey:KEY_COUNT_VISIBLE_CONTACTS] boolValue]];
	[checkBox_allContacts setState:[[preferenceDict objectForKey:KEY_COUNT_ALL_CONTACTS] boolValue]];
	
}

@end
