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

#import "AIContactSortSelectionPlugin.h"
#import "AIContactSortPreferences.h"

#define CONTACT_SORTING_DEFAULT_PREFS	@"SortingDefaults"

@interface AIContactSortSelectionPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIContactSortSelectionPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_SORTING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_SORTING];

    //Our preference view
    preferences = [[AIContactSortPreferences contactSortPreferences] retain];
    [self preferencesChanged:nil];
    
    //Observe
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Contact_SortSelectorListChanged object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
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
        identifier = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING] objectForKey:KEY_CURRENT_SORT_MODE_IDENTIFIER];
        
        //
        enumerator = [[[adium contactController] sortControllerArray] objectEnumerator];
        while((controller = [enumerator nextObject])){
            if([identifier compare:[controller identifier]] == 0){
                [[adium contactController] setActiveSortController:controller];
                break;
            }
        }
    }
}
        
@end






