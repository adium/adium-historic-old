//
//  AIContactSortSelectionPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactSortSelectionPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIContactSortPreferences.h"

#define CONTACT_SORTING_DEFAULT_PREFS	@"SortingDefaults"

@interface AIContactSortSelectionPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIContactSortSelectionPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_SORTING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_SORTING];

    //Our preference view
    preferences = [[AIContactSortPreferences contactSortPreferencesWithOwner:owner] retain];
    [self preferencesChanged:nil];
    
    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Contact_SortSelectorListChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)uninstallPlugin
{

}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_SORTING] == 0){
        NSEnumerator			*enumerator;
        id <AIListSortController>	controller;
        NSString			*identifier;

        //
        identifier = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING] objectForKey:KEY_CURRENT_SORT_MODE_IDENTIFIER];
        
        //
        enumerator = [[[owner contactController] sortControllerArray] objectEnumerator];
        while((controller = [enumerator nextObject])){
            if([identifier compare:[controller identifier]] == 0){
                [[owner contactController] setActiveSortController:controller];
                break;
            }
        }
    }
}
        
@end






