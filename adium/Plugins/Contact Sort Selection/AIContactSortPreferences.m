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

#import "AIContactSortPreferences.h"
#import "AIContactSortSelectionPlugin.h"

#define CONTACT_SORT_PREF_NIB		@"SortingPrefs"
#define CONTACT_SORT_PREF_TITLE		@"Sorting"

@interface AIContactSortPreferences (PRIVATE)
- (void)configureView;
- (void)buildSortModeMenu;
@end

@implementation AIContactSortPreferences
//
+ (AIContactSortPreferences *)contactSortPreferences
{
    return([[[self alloc] init] autorelease]);
}

//User selected a sort mode
- (IBAction)selectSortMode:(id)sender
{
    NSString	*identifier = [sender representedObject];

    [[adium preferenceController] setPreference:identifier forKey:KEY_CURRENT_SORT_MODE_IDENTIFIER group:PREF_GROUP_CONTACT_SORTING];
    
    [self configureView]; //Update the sort description
}


//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_General withDelegate:self label:CONTACT_SORT_PREF_TITLE]];

    //Observe changes to the sort selector list
    [[adium notificationCenter] addObserver:self selector:@selector(configureView) name:Contact_SortSelectorListChanged object:nil];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:CONTACT_SORT_PREF_NIB owner:self];

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
    NSDictionary			*preferenceDict;
    NSString				*identifier;
    NSEnumerator			*enumerator;
    AISortController		*controller;

    //Load our preferences
    preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING];
    
    //Soundset popup
    [self buildSortModeMenu];
    identifier = [preferenceDict objectForKey:KEY_CURRENT_SORT_MODE_IDENTIFIER];
    [popUp_sortMode selectItemWithRepresentedObject:identifier];

    //Description
    enumerator = [[[adium contactController] sortControllerArray] objectEnumerator];
    while((controller = [enumerator nextObject])){
        if([identifier compare:[controller identifier]] == 0){
            [textField_description setStringValue:[controller description]];    
        }
    }
}

//Build the sort mode popup menu
- (void)buildSortModeMenu
{
    NSEnumerator                *enumerator;
    AISortController		*controller;

    //Remove all menu items
    [popUp_sortMode removeAllItems];

    //Add an item for each sort controller
    enumerator = [[[adium contactController] sortControllerArray] objectEnumerator];
    while((controller = [enumerator nextObject])){
        NSMenuItem	*menuItem;

        menuItem = [[[NSMenuItem alloc] initWithTitle:[controller displayName] target:self action:@selector(selectSortMode:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[controller identifier]];
        
        [[popUp_sortMode menu] addItem:menuItem];
    }
}

@end

