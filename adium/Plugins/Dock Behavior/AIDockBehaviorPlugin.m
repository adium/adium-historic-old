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
#import "ESDockBehaviorContactAlert.h"

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

    //Install our contact alert
    [[adium contactAlertsController] registerContactAlertProvider:self];

    //
    behaviorDict = nil;
    path = [[NSBundle bundleForClass:[self class]] pathForResource:DOCK_BEHAVIOR_PRESETS ofType:@"plist"];
    presetBehavior = [[NSArray arrayWithContentsOfFile:path] retain];
    
    //Register default preferences and pre-set behavior
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_BEHAVIOR_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_DOCK_BEHAVIOR];

    //Install our preference view
    preferences = [[AIDockBehaviorPreferences preferencePaneForPlugin:self] retain];

    //Observer preference changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
    [self preferencesChanged:nil];
    
}

- (void)uninstallPlugin
{
    [[adium notificationCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
    //Uninstall our contact alert
    [[adium contactAlertsController] unregisterContactAlertProvider:self];
}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_BEHAVIOR] == 0){
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
        NSArray		*behaviorArray;
        NSString	*activeBehaviorSet;
        NSEnumerator	*enumerator;
        NSDictionary	*dictionary;
        
        //Reset our observations
        [[adium notificationCenter] removeObserver:self];
        [[adium notificationCenter] addObserver:self
									   selector:@selector(preferencesChanged:)
										   name:Preference_GroupChanged 
										 object:nil];

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
            NSString	*notificationName = [dictionary objectForKey:KEY_DOCK_EVENT_NOTIFICATION];
            NSNumber	*behavior = [dictionary objectForKey:KEY_DOCK_EVENT_BEHAVIOR];

            //Observe the notification
            [[adium notificationCenter] addObserver:self
                                           selector:@selector(eventNotification:)
                                               name:notificationName
                                             object:nil];

            //Add the sound path to our dictionary
            [behaviorDict setObject:behavior forKey:notificationName];
        }

    }
}

//Called in response to an event that will invoke behavior
- (void)eventNotification:(NSNotification *)notification
{
    int	behavior = [[behaviorDict objectForKey:[notification name]] intValue];

    //Perform the behavior
    [[adium dockController] performBehavior:behavior];
}

//Active behavior preset.  Pass and return nil for custom behavior
- (void)setActivePreset:(NSString *)presetName
{
    [[adium preferenceController] setPreference:(presetName ? presetName : @"")
                                         forKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET
                                          group:PREF_GROUP_DOCK_BEHAVIOR];
}
- (NSString *)activePreset
{
    NSDictionary *preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
    
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
    [[adium preferenceController] setPreference:inBehavior
                                         forKey:KEY_DOCK_CUSTOM_BEHAVIOR
                                          group:PREF_GROUP_DOCK_BEHAVIOR];
}
- (NSArray *)customBehavior
{
    return([[adium preferenceController] preferenceForKey:KEY_DOCK_CUSTOM_BEHAVIOR
													group:PREF_GROUP_DOCK_BEHAVIOR]);
}

//*****
//ESContactAlertProvider
//*****

- (NSString *)identifier
{
    return CONTACT_ALERT_IDENTIFIER;
}

- (ESContactAlert *)contactAlert
{
    return [ESDockBehaviorContactAlert contactAlert];   
}

//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName
{
    if (details) {
        //Perform the behavior
        [[adium dockController] performBehavior:[details intValue]];
        return YES;
    } else {
        return NO;
    }
}

//continue processing after a successful action
- (BOOL)shouldKeepProcessing
{
    return NO;   
}

/********
Methods for custom behvaior and contact alert classes
********/

//Builds and returns a dock behavior list menu
+ (NSMenu *)behaviorListMenuForTarget:(id)target
{
    NSMenu		*behaviorMenu = [[[NSMenu alloc] init] autorelease];
    
    //Build the menu items
    [behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:BOUNCE_ONCE 
														   withName:AILocalizedString(@"Once",nil) target:target]];
	
    [behaviorMenu addItem:[NSMenuItem separatorItem]];
	
    [behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:BOUNCE_REPEAT
														   withName:AILocalizedString(@"Repeatedly",nil) target:target]];
	
    [behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:BOUNCE_DELAY5 
														   withName:AILocalizedString(@"Every 5 Seconds",nil) target:target]];
	
    [behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:BOUNCE_DELAY10 
														   withName:AILocalizedString(@"Every 10 Seconds",nil) target:target]];
	
    [behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:BOUNCE_DELAY15 
														   withName:AILocalizedString(@"Every 15 Seconds",nil) target:target]];
	
    [behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:BOUNCE_DELAY30
														   withName:AILocalizedString(@"Every 30 Seconds",nil) target:target]];
	
    [behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:BOUNCE_DELAY60
														   withName:AILocalizedString(@"Every Minute",nil) target:target]];
    
    [behaviorMenu setAutoenablesItems:NO];
    
    return(behaviorMenu);
}

//
+ (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name target:(id)target
{
    NSMenuItem		*menuItem;
    menuItem = [[[NSMenuItem alloc] initWithTitle:name
                                           target:target
                                           action:@selector(selectBehavior:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:behavior]];
    
    return(menuItem);
}

@end