/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AISoundController.h"
#import "Adium/ESContactAlertsViewController.h"
#import "ESContactAlertsController.h"
#import "ESGlobalEventsPreferences.h"
#import "ESGlobalEventsPreferencesPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>

#define CUSTOM_TITLE AILocalizedString(@"Custom",nil)

@interface ESGlobalEventsPreferences (PRIVATE)
- (void)popUp:(NSPopUpButton *)inPopUp shouldShowCustom:(BOOL)showCustom;
- (void)xtrasChanged:(NSNotification *)notification;
- (void)contactAlertsDidChangeForActionID:(NSString *)actionID;

- (IBAction)selectSoundSet:(id)sender;
- (NSMenu *)_soundSetMenu;

- (IBAction)selectDockBehaviorSet:(id)sender;
- (NSMenu *)_dockBehaviorSetMenu;

- (IBAction)selectSpeechPreset:(id)sender;
- (NSMenu *)_speechPresetMenu;

- (IBAction)selectGrowlPreset:(id)sender;
- (NSMenu *)_growlPresetMenu;

- (NSMenu *)_setMenuFromArray:(NSArray *)array selector:(SEL)selector;

@end

@implementation ESGlobalEventsPreferences
//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Events);
}
- (NSString *)label{
    return(EVENTS_TITLE);
}
- (NSString *)nibName{
    return(@"GlobalEventsPreferences");
}

//Configure the preference view
- (void)viewDidLoad
{
	//Configure our global contact alerts view controller
	[contactAlertsViewController setConfigureForGlobal:YES];
	[contactAlertsViewController setDelegate:self];
	[contactAlertsViewController configureForListObject:nil];
	
	//Observe for installation of new sound sets and set up the sound set menu
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
	[self xtrasChanged:nil];	
	
	//Build and set the dock behavior set menu
    [popUp_dockBehaviorSet setMenu:[self _dockBehaviorSetMenu]];
	
	//Build and set the speech preset menu
	[popUp_speechPreset setMenu:[self _speechPresetMenu]];

	//Build and set the growl preset menu
	if([NSApp isOnPantherOrBetter]){
		[popUp_growlPreset setMenu:[self _growlPresetMenu]];
	}else{
		[popUp_growlPreset setEnabled:NO];
	}

	//Observer preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DOCK_BEHAVIOR];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GROWL];
	
	[label_bounceTheDockIcon setLocalizedString:AILocalizedString(@"Bounce the dock icon:",nil)];
	[label_displayGrowlNotifications setLocalizedString:AILocalizedString(@"Display Growl notifications:",nil)];
	[label_soundSet setLocalizedString:AILocalizedString(@"Sound set:",nil)];
	[label_speech setLocalizedString:AILocalizedString(@"Speech:",nil)];
}

//Preference view is closing
- (void)viewWillClose
{
	[contactAlertsViewController viewWillClose];
	[contactAlertsViewController release]; contactAlertsViewController = nil;

	[[adium preferenceController] unregisterPreferenceObserver:self];
    [[adium notificationCenter] removeObserver:self];
}

//Called when the preferences change, update our preference display
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if([group isEqualToString:PREF_GROUP_SOUNDS]){
		//If the soundset changed
		if(!key || ([key isEqualToString:KEY_EVENT_SOUND_SET])){
			NSString		*soundSetPath = [prefDict objectForKey:KEY_EVENT_SOUND_SET];
			
			//Update the soundset popUp
			if(soundSetPath && [soundSetPath length] != 0){
				[popUp_soundSet selectItemWithRepresentedObject:[soundSetPath stringByExpandingBundlePath]];
				[self popUp:popUp_soundSet shouldShowCustom:NO];
	
			}else{
				[self popUp:popUp_soundSet shouldShowCustom:YES];
			}
		}
	}else if([group isEqualToString:PREF_GROUP_DOCK_BEHAVIOR]){
		
		//If the Behavior set changed
		if(!key || [key isEqualToString:KEY_DOCK_ACTIVE_BEHAVIOR_SET]){
			NSString	*activePreset = [prefDict objectForKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET];
			
			if(activePreset && ([activePreset length] != 0)){
				[popUp_dockBehaviorSet selectItemWithRepresentedObject:activePreset];
				[self popUp:popUp_dockBehaviorSet shouldShowCustom:NO];
				
			}else{
				[self popUp:popUp_dockBehaviorSet shouldShowCustom:YES];
			}
		}
	}else if([group isEqualToString:PREF_GROUP_ANNOUNCER]){
		if(!key || [key isEqualToString:KEY_SPEECH_ACTIVE_PRESET]){
			NSString	*activePreset = [prefDict objectForKey:KEY_SPEECH_ACTIVE_PRESET];
			
			if(activePreset && ([activePreset length] != 0)){
				[popUp_speechPreset selectItemWithRepresentedObject:activePreset];
				[self popUp:popUp_speechPreset shouldShowCustom:NO];
				
			}else{
				[self popUp:popUp_speechPreset shouldShowCustom:YES];
			}
		}
	}else if([group isEqualToString:PREF_GROUP_GROWL]){
		if(!key || [key isEqualToString:KEY_GROWL_ACTIVE_PRESET]){
			NSString	*activePreset = [prefDict objectForKey:KEY_GROWL_ACTIVE_PRESET];
			
			if(activePreset && ([activePreset length] != 0)){
				[popUp_growlPreset selectItemWithRepresentedObject:activePreset];
				[self popUp:popUp_growlPreset shouldShowCustom:NO];
				
			}else{
				[self popUp:popUp_growlPreset shouldShowCustom:YES];
			}
		}
	}
}

- (void)popUp:(NSPopUpButton *)inPopUp shouldShowCustom:(BOOL)showCustom
{
	NSMenuItem	*lastItem = [inPopUp lastItem];
	BOOL		customIsShowing = (lastItem && (![lastItem representedObject] &&
												[[lastItem title] isEqualToString:CUSTOM_TITLE]));
	if(showCustom && !customIsShowing){
		//Add 'custom' then select it
		[[inPopUp menu] addItem:[NSMenuItem separatorItem]];
		[[inPopUp menu] addItemWithTitle:CUSTOM_TITLE
								  target:nil
								  action:nil
						   keyEquivalent:@""];
		[inPopUp selectItem:[inPopUp lastItem]];

	}else if(!showCustom && customIsShowing){
		//If it currently has a 'custom' item listed, remove it and the separator above it
		[inPopUp removeItemAtIndex:([inPopUp numberOfItems]-1)];
		[inPopUp removeItemAtIndex:([inPopUp numberOfItems]-1)];
	}
}

- (void)xtrasChanged:(NSNotification *)notification
{
	if (!notification || [[notification object] caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame){		
		//Build the soundset menu
		[popUp_soundSet setMenu:[self _soundSetMenu]];
	}
}

#pragma mark Contact alerts changed by user
- (void)contactAlertsViewController:(ESContactAlertsViewController *)inController
					   updatedAlert:(NSDictionary *)newAlert
						   oldAlert:(NSDictionary *)oldAlert
{	
	[self contactAlertsDidChangeForActionID:[newAlert objectForKey:KEY_ACTION_ID]];
}

- (void)contactAlertsViewController:(ESContactAlertsViewController *)inController
					   deletedAlert:(NSDictionary *)deletedAlert
{
	[self contactAlertsDidChangeForActionID:[deletedAlert objectForKey:KEY_ACTION_ID]];	
}

- (void)contactAlertsDidChangeForActionID:(NSString *)actionID
{
	if([actionID isEqualToString:SOUND_ALERT_IDENTIFIER]){
		
		NSArray			*alertsArray = [[adium contactAlertsController] alertsForListObject:nil
																			   withActionID:SOUND_ALERT_IDENTIFIER];
		NSMenuItem		*soundMenuItem = nil;
		
		//We can select "None" if there are no sounds
		if(![alertsArray count]){
			soundMenuItem = (NSMenuItem *)[popUp_soundSet itemWithTitle:@"None"];
		}

		//Sounds changed.  Could check all sounds to determine if we are on a soundset or are now 'custom',
		//but that would probably be very expensive.
		//For now, if sounds change, we are 'custom' even if it gets us back to a sound set
		[self selectSoundSet:soundMenuItem];
		
	}else if([actionID isEqualToString:DOCK_BEHAVIOR_ALERT_IDENTIFIER]){
		//Dock behaviors changed.
		[plugin updateActiveDockBehaviorSet];
		
	}else if([actionID isEqualToString:SPEAK_EVENT_ALERT_IDENTIFIER]){
		//Speech preset changed.
		[plugin updateActiveSpeechPreset];
		
	}else if([actionID isEqualToString:GROWL_EVENT_ALERT_IDENTIFIER]){
		//Growl preset changed.
		[plugin updateActiveGrowlPreset];
	}
}

#pragma mark Sound sets
//The user selected a sound set
- (IBAction)selectSoundSet:(id)sender
{
	//Can't set nil because if we do the default will be reapplied on next launch
	[[adium preferenceController] setPreference:([sender representedObject] ?
												 [[sender representedObject] stringByCollapsingBundlePath] :
												 @"")
										 forKey:KEY_EVENT_SOUND_SET
										  group:PREF_GROUP_SOUNDS];
}

//Builds and returns a sound set menu
- (NSMenu *)_soundSetMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*soundSetDict;
    NSMenu		*soundSetMenu = [[NSMenu alloc] init];
    
    enumerator = [[[adium soundController] soundSetArray] objectEnumerator];
    while((soundSetDict = [enumerator nextObject])){
        NSString	*setPath = [soundSetDict objectForKey:KEY_SOUND_SET];
        NSMenuItem	*menuItem;
        NSString	*soundSetFile;
		
        //Ensure this folder contains a soundset file (Otherwise, we ignore it)
        soundSetFile = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.txt", setPath, [[setPath stringByDeletingPathExtension] lastPathComponent]]];
        if(soundSetFile && [soundSetFile length] != 0){
			
            //Add a menu item for the set
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[setPath stringByDeletingPathExtension] lastPathComponent]
																			 target:self
																			 action:@selector(selectSoundSet:)
																	  keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:[soundSetDict objectForKey:KEY_SOUND_SET]];
            [soundSetMenu addItem:menuItem];
			
        }
    }

    return(soundSetMenu);
}

#pragma mark Dock behavior sets
- (IBAction)selectDockBehaviorSet:(id)sender
{
	//Can't set nil because if we do the default will be reapplied on next launch
	[[adium preferenceController] setPreference:([sender representedObject] ?
												 [sender representedObject] : 
												 @"")
										 forKey:KEY_DOCK_ACTIVE_BEHAVIOR_SET
										  group:PREF_GROUP_DOCK_BEHAVIOR];
}

//Builds and returns a behavior set menu
- (NSMenu *)_dockBehaviorSetMenu
{
	return [self _setMenuFromArray:[plugin availableDockBehaviorPresets]
						  selector:@selector(selectDockBehaviorSet:)];
}

#pragma mark Speech presets
- (IBAction)selectSpeechPreset:(id)sender
{
	//Can't set nil because if we do the default will be reapplied on next launch
	[[adium preferenceController] setPreference:([sender representedObject] ?
												 [sender representedObject] : 
												 @"")
										 forKey:KEY_SPEECH_ACTIVE_PRESET
										  group:PREF_GROUP_ANNOUNCER];	
}

//Builds and returns a speech preset menu
- (NSMenu *)_speechPresetMenu
{
	return [self _setMenuFromArray:[plugin availableSpeechPresets]
						  selector:@selector(selectSpeechPreset:)];
}

#pragma mark Growl presets

- (IBAction)selectGrowlPreset:(id)sender
{
	//Can't set nil because if we do the default will be reapplied on next launch
	[[adium preferenceController] setPreference:([sender representedObject] ?
												 [sender representedObject] : 
												 @"")
										 forKey:KEY_GROWL_ACTIVE_PRESET
										  group:PREF_GROUP_GROWL];	
}

- (NSMenu *)_growlPresetMenu
{
	return [self _setMenuFromArray:[plugin availableGrowlPresets]
						  selector:@selector(selectGrowlPreset:)];
}

#pragma mark Common menu methods
/*!
 * @brief Localized a menu item title for global events preferences
 *
 * @result The equivalent localized title if available; otherwise, the passed English title
 */
- (NSString *)_localizedTitle:(NSString *)englishTitle
{
	NSString	*localizedTitle = nil;
	
	if([englishTitle isEqualToString:@"None"])
		localizedTitle = AILocalizedString(@"None",nil);
	else if([englishTitle isEqualToString:@"Never"])
		localizedTitle = AILocalizedString(@"Never",nil);
	else if([englishTitle isEqualToString:@"On New Messages"])
		localizedTitle = AILocalizedString(@"On New Messages","Events preset for the event to occur whenever a message is received");
	else if([englishTitle isEqualToString:@"On New Background Messages"])
		localizedTitle = AILocalizedString(@"On New Background Messages","Events preset for the event to occur when messages are received in a chat which is not currently active (is in the background)");
	else if([englishTitle isEqualToString:@"On Errors"])
		localizedTitle = AILocalizedString(@"On Errors","Events preset for the event to occur when an error occurs");
	else if([englishTitle isEqualToString:@"On Contact Availability"])
		localizedTitle = AILocalizedString(@"On Contact Availability","Events preset for the event to occur when a contact becomes available");
	else if([englishTitle isEqualToString:@"On Contact Connections"])
		localizedTitle = AILocalizedString(@"On Contact Connections","Events preset for the event to occur when a contact connects");
	else if([englishTitle isEqualToString:@"All Messages"])
		localizedTitle = AILocalizedString(@"All Messages","Events preset for the event to occur for any message");
	else if([englishTitle isEqualToString:@"Incoming Messages"])
		localizedTitle = AILocalizedString(@"Incoming Messages","Events preset for the event to occur when there is an incoming message");

	return (localizedTitle ? localizedTitle : englishTitle);
}

- (NSMenu *)_setMenuFromArray:(NSArray *)array selector:(SEL)selector
{
    NSEnumerator	*enumerator;
    NSString		*setName;
    NSMenu			*setMenu;
	
    //Create the behavior set menu
    setMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
	
    //Add all the premade behavior sets
    enumerator = [array objectEnumerator];
    while((setName = [enumerator nextObject])){
        NSMenuItem	*menuItem;
		
        //Create the menu item
        menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[self _localizedTitle:setName]
																		 target:self
																		 action:selector
																  keyEquivalent:@""] autorelease];
		
        //
        [menuItem setRepresentedObject:setName];
        [setMenu addItem:menuItem];
    }
	
    return(setMenu);
}
@end

#if 0
//Builds and returns a sound list menu - with full Other... support, from the old sound custom panel
- (NSMenu *)soundListMenu
{
    NSEnumerator	*enumerator;
    
    if (!soundMenu_cached)
    {
        NSDictionary	*soundSetDict;
        NSMenu		*soundMenu = [[NSMenu alloc] init];
        NSMenuItem	*menuItem;
        
        enumerator = [[[adium soundController] soundSetArray] objectEnumerator];
        while((soundSetDict = [enumerator nextObject])){
            NSEnumerator    *soundEnumerator;
            NSString        *soundSetPath;
            NSString        *soundPath;
            NSArray         *soundSetContents = [soundSetDict objectForKey:KEY_SOUND_SET_CONTENTS];
            //Add an item for the set
            if (soundSetContents && [soundSetContents count]) {
                if([soundMenu numberOfItems] != 0){
                    [soundMenu addItem:[NSMenuItem separatorItem]]; //Divider
                }
                soundSetPath = [soundSetDict objectForKey:KEY_SOUND_SET];
                menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[soundSetPath lastPathComponent]
																				 target:nil
																				 action:nil
																		  keyEquivalent:@""] autorelease];
                [menuItem setEnabled:NO];
                [soundMenu addItem:menuItem];
                
                //Add an item for each sound
                soundEnumerator = [soundSetContents objectEnumerator];
                while((soundPath = [soundEnumerator nextObject])){
                    NSImage	*soundImage;
                    NSString	*soundTitle;
                    //Keep track of our first sound (used when creating a new event)
                    if(!firstSound) firstSound = [soundPath retain];
                    
                    //Get the sound title and image
                    soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
                    soundImage = [[NSWorkspace sharedWorkspace] iconForFile:soundPath];
                    [soundImage setSize:NSMakeSize(SOUND_MENU_ICON_SIZE,SOUND_MENU_ICON_SIZE)];
                    
                    //Build the menu item
                    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:soundTitle
																					 target:self
																					 action:@selector(selectSound:)
																			  keyEquivalent:@""] autorelease];
                    [menuItem setRepresentedObject:[soundPath stringByCollapsingBundlePath]];
                    [menuItem setImage:soundImage];
                    
                    [soundMenu addItem:menuItem];
                }
            }
        }
        //Add the Other... item
        menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:OTHER_ELLIPSIS
																		 target:self
																		 action:@selector(selectSound:)
																  keyEquivalent:@""] autorelease];            
        [soundMenu addItem:menuItem];
        
        [soundMenu setAutoenablesItems:NO];
        soundMenu_cached = soundMenu;
    }
    
    //Add custom sounds to the menu as needed
    NSDictionary * soundRowDict;
    enumerator = [eventSoundArray objectEnumerator];
    while (soundRowDict = [enumerator nextObject]) {
        //add it if it's not already in the menu
        NSString *soundPath = [soundRowDict objectForKey:KEY_EVENT_SOUND_PATH];
        if(soundPath && ([soundPath length] != 0) && [soundMenu_cached indexOfItemWithRepresentedObject:soundPath] == -1) {
            NSImage	*soundImage;
            NSString	*soundTitle;
            NSMenuItem	*menuItem;
			
            //Add an "Other" header if necessary
            if([soundMenu_cached indexOfItemWithTitle:OTHER] == -1) {
                [soundMenu_cached insertItem:[NSMenuItem separatorItem] atIndex:([soundMenu_cached numberOfItems]-1)]; //Divider
                menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:OTHER
																				 target:nil
																				 action:nil
																		  keyEquivalent:@""] autorelease];
                [menuItem setEnabled:NO];
                [soundMenu_cached insertItem:menuItem atIndex:([soundMenu_cached numberOfItems]-1)];
            }
            
            //Get the sound title and image
            soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
            soundImage = [[NSWorkspace sharedWorkspace] iconForFile:soundPath];
            [soundImage setSize:NSMakeSize(SOUND_MENU_ICON_SIZE,SOUND_MENU_ICON_SIZE)];
            
            //Build the menu item
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:soundTitle
																			 target:self
																			 action:@selector(selectSound:)
																	  keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:soundPath];
            [menuItem setImage:soundImage];
            
            [soundMenu_cached insertItem:menuItem atIndex:([soundMenu_cached numberOfItems]-1)];
        }
    }
    
    return(soundMenu_cached);
}
#endif