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

#import "AIDockBehaviorPreferences.h"
#import "AIDockBehaviorPlugin.h"
#import "AIDockCustomBehavior.h"

#define TABLE_COLUMN_BEHAVIOR   @"behavior"
#define TABLE_COLUMN_EVENT		@"event"

@interface AIDockBehaviorPreferences (PRIVATE)
- (id)initWithPlugin:(id)inPlugin;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSMenu *)behaviorSetMenu;
@end

@implementation AIDockBehaviorPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Dock);
}
- (NSString *)label{
    return(AILocalizedString(@"Dock Bouncing","Dock bouncing preferences label"));
}
- (NSString *)nibName{
    return(@"DockBehaviorPreferences");
}

//Configure the preference view
- (void)viewDidLoad
{
    //Build the behavior set menu
    [popUp_behaviorSet setMenu:[self behaviorSetMenu]];

    //Observer preference changes
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
    [self preferencesChanged:nil];
}

//Preference view is closing
- (void)viewWillClose
{
    [AIDockCustomBehavior closeDockBehaviorCustomPanel];
    [[adium notificationCenter] removeObserver:self];
}

//Called when the preferences change, update our preference display
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_DOCK_BEHAVIOR]){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];

        //If the Behavior set changed
        if(notification == nil || [key isEqualToString:KEY_DOCK_ACTIVE_BEHAVIOR_SET]){
            NSString	*activePreset = [plugin activePreset];

            if(activePreset && ([activePreset length] != 0)){
                [popUp_behaviorSet selectItemWithRepresentedObject:activePreset];
            }else{
                [popUp_behaviorSet selectItem:[popUp_behaviorSet lastItem]];
            }
        }
    }
}

//The user selected a dock behavior preset
- (IBAction)selectBehaviorSet:(id)sender
{
    NSString	*newPreset = nil;

    if(sender) newPreset = [sender representedObject];

    //Set the new preset as active
    [plugin setActivePreset:newPreset];

    //If the user moves from a preset to custom, we copy that preset's behavior into custom.
    if([plugin activePreset] && [[plugin activePreset] length]){
        [plugin setCustomBehavior:[plugin behaviorForPreset:[plugin activePreset]]];
    }
    
    //Hide or show the custom panel as necessary
    if(newPreset){
        [AIDockCustomBehavior closeDockBehaviorCustomPanel];
    }else{
        [AIDockCustomBehavior showDockBehaviorCustomPanelWithPlugin:plugin];
    }
}

//Builds and returns a behavior set menu
- (NSMenu *)behaviorSetMenu
{
    NSEnumerator	*enumerator;
    NSString		*setName;
    NSMenu		*behaviorSetMenu;

    //Create the behavior set menu
    behaviorSetMenu = [[[NSMenu alloc] init] autorelease];

    //Add all the premade behavior sets
    enumerator = [[plugin availablePresets] objectEnumerator];
    while((setName = [enumerator nextObject])){
        NSMenuItem	*menuItem;

        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:setName
                                               target:self
                                               action:@selector(selectBehaviorSet:)
                                        keyEquivalent:@""] autorelease];

        //
        [menuItem setRepresentedObject:setName];
        [behaviorSetMenu addItem:menuItem];
    }

    //Add the custom option
    [behaviorSetMenu addItem:[NSMenuItem separatorItem]];
    [behaviorSetMenu addItemWithTitle:AILocalizedString(@"Custom...",nil) 
							   target:self
							   action:@selector(selectBehaviorSet:)
						keyEquivalent:@""];

    return(behaviorSetMenu);
}

@end
