/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

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











