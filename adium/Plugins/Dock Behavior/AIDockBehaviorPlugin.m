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

#import "AIDockBehaviorPlugin.h"
#import "AIDockBehaviorPreferences.h"

#define DOCK_BEHAVIOR_DEFAULT_PREFS	@"DockBehaviorDefaults"
#define DOCK_BEHAVIOR_PRESETS		@"DockBehaviorPresets"

@interface AIDockBehaviorPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)eventNotification:(NSNotification *)notification;
@end

@implementation AIDockBehaviorPlugin

- (void)installPlugin
{
    NSString	*path;

    //
    behaviorDict = nil;
    path = [[NSBundle bundleForClass:[self class]] pathForResource:DOCK_BEHAVIOR_PRESETS ofType:@"plist"];
    presetBehavior = [[NSArray arrayWithContentsOfFile:path] retain];
    
    //Register default preferences and pre-set behavior
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_BEHAVIOR_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DOCK_BEHAVIOR];

    //Install our preference view
    preferences = [[AIDockBehaviorPreferences preferencePaneWithPlugin:self owner:owner] retain];

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
            behaviorArray = [self behaviorForPreset:activeBehaviorSet];

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

//Called in response to an event that will invoke behavior
- (void)eventNotification:(NSNotification *)notification
{
    int	behavior = [[behaviorDict objectForKey:[notification name]] intValue];

    //Perform the behavior
    [[owner dockController] performBehavior:behavior];
}

//Active behavior preset.  Pass and return nil for custom behavior
- (void)setActivePreset:(NSString *)presetName
{
    [[owner preferenceController] setPreference:(presetName ? presetName : @"")
                                         forKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET
                                          group:PREF_GROUP_DOCK_BEHAVIOR];
}
- (NSString *)activePreset
{
    NSDictionary *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
    
    return([preferenceDict objectForKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET]);
}

//Returns the behavior for a preset
- (NSArray *)behaviorForPreset:(NSString *)presetName
{
    NSEnumerator	*enumerator;
    NSDictionary	*set;
    
    //Search for the desired set
    enumerator = [presetBehavior objectEnumerator];
    while((set = [enumerator nextObject])){
        if([presetName compare:[set objectForKey:@"Name"]] == 0){
            return([set objectForKey:@"Behavior"]);
        }
    }
    
    return(nil);
}

//Returns an array of the available preset names
- (NSArray *)availablePresets
{
    NSMutableArray	*availablePresets = [[NSMutableArray alloc] init];
    NSEnumerator	*enumerator;
    NSDictionary	*set;
    
    //Grab the name of each set
    enumerator = [presetBehavior objectEnumerator];
    while((set = [enumerator nextObject])){
        [availablePresets addObject:[set objectForKey:@"Name"]];
    }
    
    return([availablePresets autorelease]);
}

//Custom dock behavior
- (void)setCustomBehavior:(NSArray *)inBehavior
{
    [[owner preferenceController] setPreference:inBehavior
                                         forKey:KEY_DOCK_CUSTOM_BEHAVIOR
                                          group:PREF_GROUP_DOCK_BEHAVIOR];
}
- (NSArray *)customBehavior
{
    NSDictionary 	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
    
    return([preferenceDict objectForKey:KEY_DOCK_CUSTOM_BEHAVIOR]);
}

@end