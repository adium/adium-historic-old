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
#import "AIDockBehaviorPlugin.h"
#import "AIDockBehaviorPreferences.h"

#define DOCK_BEHAVIOR_DEFAULT_PREFS	@"DockBehaviorDefaults"

@interface AIDockBehaviorPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)eventNotification:(NSNotification *)notification;
@end

@implementation AIDockBehaviorPlugin

- (void)installPlugin
{
    //
    behaviorDict = nil;
    
    //Register default preferences and pre-set behavior
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_BEHAVIOR_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DOCK_BEHAVIOR];

    //Install our preference view
    preferences = [[AIDockBehaviorPreferences dockBehaviorPreferencesWithOwner:owner] retain];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
}

- (void)uninstallPlugin
{
    [[owner notificationCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_BEHAVIOR] == 0){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
        NSArray		*behaviorArray;
        NSString	*activeBehaviorSet;
        NSEnumerator	*enumerator;
        NSDictionary	*dictionary;
        
        //Reset our observations
        [[owner notificationCenter] removeObserver:self];
        [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

        //Load the behaviorSet
        activeBehaviorSet = [preferenceDict objectForKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET];
        if(activeBehaviorSet && [activeBehaviorSet length] != 0){ //preset
            behaviorArray = [[preferenceDict objectForKey:KEY_DOCK_BEHAVIOR_SETS] objectForKey:activeBehaviorSet];

        }else{ //Custom
            behaviorArray = [preferenceDict objectForKey:KEY_DOCK_CUSTOM_BEHAVIOR];

        }

        //Put the behavior info into a dictionary (so it's quicker to lookup), and observe the notifications
        [behaviorDict release]; behaviorDict = [[NSMutableDictionary alloc] init];
        enumerator = [behaviorArray objectEnumerator];
        while((dictionary = [enumerator nextObject])){
            NSString	*notification = [dictionary objectForKey:KEY_DOCK_EVENT_NOTIFICATION];
            NSNumber	*behavior = [dictionary objectForKey:KEY_DOCK_EVENT_BEHAVIOR];

            //Observe the notification
            [[owner notificationCenter] addObserver:self
                                           selector:@selector(eventNotification:)
                                               name:notification
                                             object:nil];

            //Add the sound path to our dictionary
            [behaviorDict setObject:behavior forKey:notification];
        }

    }
}


- (void)eventNotification:(NSNotification *)notification
{
    int	behavior = [[behaviorDict objectForKey:[notification name]] intValue];

    //Perform the behavior
    [[owner dockController] performBehavior:behavior];
}


@end