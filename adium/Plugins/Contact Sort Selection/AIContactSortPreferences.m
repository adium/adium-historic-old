//
//  AIContactSortPreferences.m
//  Adium
//
//  Created by Adam Iser on Mon Feb 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AIContactSortPreferences.h"
#import "AIContactSortSelectionPlugin.h"

#define CONTACT_SORT_PREF_NIB		@"SortingPrefs"
#define CONTACT_SORT_PREF_TITLE		@"Sorting"

@interface AIContactSortPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)buildSortModeMenu;
@end

@implementation AIContactSortPreferences

+ (AIContactSortPreferences *)contactSortPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//User selected a sort mode
- (IBAction)selectSortMode:(id)sender
{
    NSString	*identifier = [sender representedObject];

    [[owner preferenceController] setPreference:identifier forKey:KEY_CURRENT_SORT_MODE_IDENTIFIER group:PREF_GROUP_CONTACT_SORTING];
    
    [self configureView]; //Update the sort description
}




//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:CONTACT_SORT_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:CONTACT_SORT_PREF_TITLE categoryName:PREFERENCE_CATEGORY_CONTACTLIST view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING] retain];
    [self configureView];

    [[owner notificationCenter] addObserver:self selector:@selector(configureView) name:Contact_SortSelectorListChanged object:nil];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    NSString				*identifier;
    NSEnumerator			*enumerator;
    id <AIListSortController>		controller;
    
    //Soundset popup
    [self buildSortModeMenu];
    identifier = [preferenceDict objectForKey:KEY_CURRENT_SORT_MODE_IDENTIFIER];
    [popUp_sortMode selectItemWithRepresentedObject:identifier];

    //Description
    enumerator = [[[owner contactController] sortControllerArray] objectEnumerator];
    while((controller = [enumerator nextObject])){
        if([identifier compare:[controller identifier]] == 0){
            [textField_description setStringValue:[controller description]];    
        }
    }
}

//Build the sort mode popup menu
- (void)buildSortModeMenu
{
    NSEnumerator			*enumerator;
    id <AIListSortController>	controller;

    //Remove all menu items
    [popUp_sortMode removeAllItems];

    //Add an item for each sort controller
    enumerator = [[[owner contactController] sortControllerArray] objectEnumerator];
    while((controller = [enumerator nextObject])){
        NSMenuItem	*menuItem;

        menuItem = [[NSMenuItem alloc] initWithTitle:[controller displayName] target:self action:@selector(selectSortMode:) keyEquivalent:@""];
        [menuItem setRepresentedObject:[controller identifier]];
        
        [[popUp_sortMode menu] addItem:menuItem];
    }
}


@end











