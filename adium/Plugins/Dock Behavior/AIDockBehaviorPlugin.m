/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "ESDockAlertDetailPane.h"

#define DOCK_BEHAVIOR_DEFAULT_PREFS	@"DockBehaviorDefaults"
#define DOCK_BEHAVIOR_PRESETS		@"DockBehaviorPresets"
#define DOCK_BEHAVIOR_ALERT_SHORT	@"Bounce the dock icon"
#define DOCK_BEHAVIOR_ALERT_LONG	@"Bounce the dock icon %@"

@interface AIDockBehaviorPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)eventNotification:(NSNotification *)notification;
@end

@implementation AIDockBehaviorPlugin

- (void)installPlugin
{
    NSString	*path;

    //Install our contact alert
	[[adium contactAlertsController] registerActionID:DOCK_BEHAVIOR_ALERT_IDENTIFIER withHandler:self];
	
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
	
	//Wait for Adium to finish launching before we set up our dock behavior so the event plugins are ready
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_PluginsDidFinishLoading
									 object:nil];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
    [self preferencesChanged:nil];
	[[adium notificationCenter] removeObserver:self
										  name:Adium_PluginsDidFinishLoading
										object:nil];		
}

- (void)uninstallPlugin
{
    [[adium notificationCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
    //Uninstall our contact alert
//    [[adium contactAlertsController] unregisterContactAlertProvider:self];
}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_DOCK_BEHAVIOR]){
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];
        NSArray			*behaviorArray;
        NSString		*activeBehaviorSet;
        NSEnumerator	*enumerator;
        NSDictionary	*dictionary;

        //Load the behaviorSet
        activeBehaviorSet = [preferenceDict objectForKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET];
        if(activeBehaviorSet && [activeBehaviorSet length] != 0){ //preset
            behaviorArray = [self behaviorForPreset:activeBehaviorSet];

        }else{ //Custom
            behaviorArray = [preferenceDict objectForKey:KEY_DOCK_CUSTOM_BEHAVIOR];

        }

		//Clear out old global sound alerts
		[[adium contactAlertsController] removeAllGlobalAlertsWithActionID:DOCK_BEHAVIOR_ALERT_IDENTIFIER];
		
		//
        enumerator = [behaviorArray objectEnumerator];
        while((dictionary = [enumerator nextObject])){
			
            NSString		*eventID = [dictionary objectForKey:KEY_EVENT_DOCK_EVENT_ID];
            NSNumber		*behavior = [dictionary objectForKey:KEY_EVENT_DOCK_BEHAVIOR];
			NSDictionary	*soundAlert = [NSDictionary dictionaryWithObjectsAndKeys:eventID, KEY_EVENT_ID,
				DOCK_BEHAVIOR_ALERT_IDENTIFIER, KEY_ACTION_ID, 
				[NSDictionary dictionaryWithObject:behavior forKey:KEY_DOCK_BEHAVIOR_TYPE], KEY_ACTION_DETAILS,nil];
			
            [[adium contactAlertsController] addGlobalAlert:soundAlert];
        }
    }
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
        if([presetName isEqualToString:[set objectForKey:@"Name"]]){
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


/********
Methods for custom behvaior and contact alert classes
********/

//Builds and returns a dock behavior list menu
+ (NSMenu *)behaviorListMenuForTarget:(id)target
{
    NSMenu			*behaviorMenu = [[[NSMenu alloc] init] autorelease];
    DOCK_BEHAVIOR	behavior;
	
	for(behavior = 0; behavior < BOUNCE_DELAY60; behavior++){
		NSString *name = [[[AIObject sharedAdiumInstance] dockController] descriptionForBehavior:behavior];
		[behaviorMenu addItem:[AIDockBehaviorPlugin menuItemForBehavior:behavior withName:name target:target]];
	}
    
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

//Bounce Dock Alert ----------------------------------------------------------------------------------------------------
#pragma mark Bounce Dock Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(DOCK_BEHAVIOR_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	int behavior = [[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue];
	return([NSString stringWithFormat:DOCK_BEHAVIOR_ALERT_LONG, [[[adium dockController] descriptionForBehavior:behavior] lowercaseString]]);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"DockAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESDockAlertDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID
{
	[[adium dockController] performBehavior:[[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue]];
}

@end


