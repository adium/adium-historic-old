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
#import <Adium/ESPresetManagementController.h>
#import <Adium/ESPresetNameSheetController.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <AIUtilities/AIVariableHeightOutlineView.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AIGradientImageCell.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageTextCell.h>

#define PREF_GROUP_EVENT_PRESETS			@"Event Presets"
#define CUSTOM_TITLE						AILocalizedString(@"Custom",nil)

@interface ESGlobalEventsPreferences (PRIVATE)
- (void)popUp:(NSPopUpButton *)inPopUp shouldShowCustom:(BOOL)showCustom;
- (void)xtrasChanged:(NSNotification *)notification;
- (void)contactAlertsDidChangeForActionID:(NSString *)actionID;

- (NSMenu *)showMenu;
- (NSMenu *)eventPresetsMenu;

- (IBAction)selectSoundSet:(id)sender;
- (NSMenu *)_soundSetMenu;

- (void)editEventsWithEventID:(NSString *)eventID;

- (NSMenu *)_setMenuFromArray:(NSArray *)array selector:(SEL)selector;

- (NSString *)_localizedTitle:(NSString *)englishTitle;

- (void)saveCurrentEventPreset;

- (void)setAndConfigureEventPresetsMenu;
- (void)updateSoundSetSelection;
- (void)updateSoundSetSelectionForSoundSetPath:(NSString *)soundSetPath;
@end

@implementation ESGlobalEventsPreferences
/*
 * @brief Category
 */
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Events);
}
/*
 * @brief Label
 */
- (NSString *)label{
    return(EVENTS_TITLE);
}
/*
 * @brief Nib name
 */
- (NSString *)nibName{
    return(@"GlobalEventsPreferences");
}

/*
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	//Configure our global contact alerts view controller
	[contactAlertsViewController setConfigureForGlobal:YES];
	[contactAlertsViewController setDelegate:self];
	[contactAlertsViewController setShowEventsInEditSheet:NO];
	
	//Observe for installation of new sound sets and set up the sound set menu
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];

	//This will build the sound set menu
	[self xtrasChanged:nil];	

	//Presets menu
	[self setAndConfigureEventPresetsMenu];

	[label_soundSet setLocalizedString:AILocalizedString(@"Sound set:",nil)];

	//And event presets to update our presets menu
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EVENT_PRESETS];

	//Ensure the correct sound set is selected
	[self updateSoundSetSelection];
}

/*
 * @brief Preference view is closing
 */
- (void)viewWillClose
{
	[contactAlertsViewController viewWillClose];
	[contactAlertsViewController release]; contactAlertsViewController = nil;

	[[adium preferenceController] unregisterPreferenceObserver:self];
    [[adium notificationCenter] removeObserver:self];
}

/*
 * @brief PREF_GROUP_CONTACT_ALERTS changed; update our summary data
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if([group isEqualToString:PREF_GROUP_EVENT_PRESETS]){
		if(!key || [key isEqualToString:@"Event Presets"]){
			//Update when the available event presets change
			[self setAndConfigureEventPresetsMenu];
		}
	}
}

/*
 * @brief Set if a popup should have a "Custom" menu item
 */
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

/*
 * @brief Update our soundset menu if a new sound set is instaled
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	if (!notification || [[notification object] caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame){		
		//Build the soundset menu
		[popUp_soundSet setMenu:[self _soundSetMenu]];
	}
}

#pragma mark Event presets

/*
 * @brief Buld and return the event presets menu
 *
 * The menu will have built in presets, a divider, user-set presets, a divider, and then the preset management item(s)
 */
- (NSMenu *)eventPresetsMenu
{
	NSMenu			*eventPresetsMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSEnumerator	*enumerator;
	NSDictionary	*eventPreset;
	NSMenuItem		*menuItem;
	
	//Built in event presets
	enumerator = [[plugin builtInEventPresetsArray] objectEnumerator];
	while(eventPreset = [enumerator nextObject]){
		NSString		*name = [eventPreset objectForKey:@"Name"];
		
		//Add a menu item for the set
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		 target:self
																		 action:@selector(selectEventPreset:)
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:eventPreset];
		[eventPresetsMenu addItem:menuItem];
	}
	
	NSArray	*storedEventPresetsArray = [plugin storedEventPresetsArray];
	
	if([storedEventPresetsArray count]){
		[eventPresetsMenu addItem:[NSMenuItem separatorItem]];
		
		enumerator = [storedEventPresetsArray objectEnumerator];
		while(eventPreset = [enumerator nextObject]){
			NSString		*name = [eventPreset objectForKey:@"Name"];
			
			//Add a menu item for the set
			menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																			 target:self
																			 action:@selector(selectEventPreset:)
																	  keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:eventPreset];
			[eventPresetsMenu addItem:menuItem];
		}
	}
	
	//Edit Presets
	[eventPresetsMenu addItem:[NSMenuItem separatorItem]];

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Add New Preset...",nil)
																	 target:self
																	 action:@selector(addNewPreset:)
															  keyEquivalent:@""] autorelease];
	[eventPresetsMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Edit Presets...",nil)
																	 target:self
																	 action:@selector(editPresets:)
															  keyEquivalent:@""] autorelease];
	[eventPresetsMenu addItem:menuItem];
		
	return([eventPresetsMenu autorelease]);
}

- (void)setAndConfigureEventPresetsMenu
{
	[popUp_eventPreset setMenu:[self eventPresetsMenu]];
	[popUp_eventPreset selectItemWithTitle:[[adium preferenceController] preferenceForKey:@"Active Event Set"
																					group:PREF_GROUP_EVENT_PRESETS]];
}

/*
 * @brief Selected an event preset
 *
 * Pass it to the plugin, which will perform necessary changes to our contact alerts
 */
- (void)selectEventPreset:(id)sender
{
	NSDictionary	*eventPreset = [sender representedObject];
	[plugin setEventPreset:eventPreset];

	[self updateSoundSetSelection];
}

/*
 * Add a new preset
 *
 * Called by the "Add New preset..." menu item.  Functions the same as duplicate from the preset management, duplicating
 * the current event set with a new name.
 */
- (void)addNewPreset:(id)sender
{
	NSString	*defaultName;
	NSString	*explanatoryText;
	
	defaultName = [NSString stringWithFormat:@"%@ (%@)",
		[[adium preferenceController] preferenceForKey:@"Active Event Set"
												 group:PREF_GROUP_EVENT_PRESETS],
		AILocalizedString(@"Copy",nil)];
	explanatoryText = AILocalizedString(@"Enter a unique name for this new event set.",nil);

	[ESPresetNameSheetController showPresetNameSheetWithDefaultName:defaultName
													explanatoryText:explanatoryText
														   onWindow:[[self view] window]
													notifyingTarget:self
														   userInfo:nil];

	//Get our event presets menu back to its proper selection
	[popUp_eventPreset selectItemWithTitle:[[adium preferenceController] preferenceForKey:@"Active Event Set"
																					group:PREF_GROUP_EVENT_PRESETS]];	
}

/*
 * @brief Manage presets
 *
 * Called by the "Edit Presets..." menu item
 */
- (void)editPresets:(id)sender
{
	[ESPresetManagementController managePresets:[plugin storedEventPresetsArray]
									 namedByKey:@"Name"
									   onWindow:[[self view] window]
								   withDelegate:self];

	//Get our event presets menu back to its proper selection
	[popUp_eventPreset selectItemWithTitle:[[adium preferenceController] preferenceForKey:@"Active Event Set"
																					group:PREF_GROUP_EVENT_PRESETS]];
}

- (BOOL)allowDeleteOfPreset:(NSDictionary *)preset
{
	NSString				*name = [preset objectForKey:@"Name"];
	
	//Don't allow the active preset to be deleted
	return (![[[adium preferenceController] preferenceForKey:@"Active Event Set"
													   group:PREF_GROUP_EVENT_PRESETS] isEqualToString:name]);
}

- (NSArray *)renamePreset:(NSDictionary *)preset toName:(NSString *)newName inPresets:(NSArray *)presets renamedPreset:(id *)renamedPreset
{
	NSString				*oldPresetName = [preset objectForKey:@"Name"];
	NSMutableDictionary		*newPreset = [preset mutableCopy];
	[newPreset setObject:newName
				  forKey:@"Name"];

	//Mark the newly created (but still functionally identical) event set as active if the old one was active
	if([[[adium preferenceController] preferenceForKey:@"Active Event Set"
												 group:PREF_GROUP_EVENT_PRESETS] isEqualToString:oldPresetName]){
		[[adium preferenceController] setPreference:newName
											 forKey:@"Active Event Set"
											  group:PREF_GROUP_EVENT_PRESETS];
	}
	
	//Remove the original one from the array, and add the newly-renamed one
	[plugin deleteEventPreset:preset];
	[plugin saveEventPreset:newPreset];
	
	if(renamedPreset) *renamedPreset = newPreset;

	//Return an updated presets array
	return [plugin storedEventPresetsArray];
}

- (NSArray *)duplicatePreset:(NSDictionary *)preset inPresets:(NSArray *)presets createdDuplicate:(id *)duplicatePreset
{
	NSMutableDictionary	*newEventPreset = [preset mutableCopy];
	NSString			*newName = [NSString stringWithFormat:@"%@ (%@)", [preset objectForKey:@"Name"], AILocalizedString(@"Copy",nil)];
	[newEventPreset setObject:newName
					   forKey:@"Name"];
	
	//Remove the original preset's order index
	[newEventPreset removeObjectForKey:@"OrderIndex"];
	
	//Now save the new preset
	[plugin saveEventPreset:newEventPreset];

	//Return the created duplicate by reference
	if(duplicatePreset != NULL) *duplicatePreset = [[newEventPreset retain] autorelease];
	
	//Cleanup
	[newEventPreset release];

	//Return an updated presets array
	return [plugin storedEventPresetsArray];
}

- (NSArray *)deletePreset:(NSDictionary *)preset inPresets:(NSArray *)presets
{
	//Remove the preset
	[plugin deleteEventPreset:preset];
	
	//Return an updated presets array
	return [plugin storedEventPresetsArray];
}

- (NSArray *)movePreset:(NSDictionary *)preset toIndex:(int)index inPresets:(NSArray *)presets presetAfterMove:(id *)presetAfterMove
{
	NSMutableDictionary	*newEventPreset = [preset mutableCopy];
	float newOrderIndex;
	if(index == 0){		
		newOrderIndex = [[[presets objectAtIndex:0] objectForKey:@"OrderIndex"] floatValue] / 2.0;

	}else if(index < [presets count]){
		float above = [[[presets objectAtIndex:index-1] objectForKey:@"OrderIndex"] floatValue];
		float below = [[[presets objectAtIndex:index] objectForKey:@"OrderIndex"] floatValue];
		newOrderIndex = ((above + below) / 2.0);

	}else{
		newOrderIndex = [plugin nextOrderIndex];
	}
	
	[newEventPreset setObject:[NSNumber numberWithFloat:newOrderIndex]
					   forKey:@"OrderIndex"];
			 
	//Now save the new preset
	[plugin saveEventPreset:newEventPreset];
	if(presetAfterMove != NULL) *presetAfterMove = [[newEventPreset retain] autorelease];
	[newEventPreset release];

	//Return an updated presets array
	return [plugin storedEventPresetsArray];
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

/*
 * @brief Contact alerts were changed by the user
 */
- (void)contactAlertsDidChangeForActionID:(NSString *)actionID
{
	if([actionID isEqualToString:SOUND_ALERT_IDENTIFIER]){
		
		NSArray			*alertsArray = [[adium contactAlertsController] alertsForListObject:nil
																				withEventID:nil
																				   actionID:SOUND_ALERT_IDENTIFIER];
		NSMenuItem		*soundMenuItem = nil;
	
		//We can select "None" if there are no sounds
		if(![alertsArray count]){
			soundMenuItem = (NSMenuItem *)[popUp_soundSet itemWithTitle:@"None"];
		}

		/* Sounds changed.  Could check all sounds to determine if we are on a soundset or are now 'custom',
		 * but that would probably be very expensive.
		 *
		 * For now, if sounds change, we no longer show as being in a set, even if we really are.
		 * 
		 * Simulate the user having selected the appropriate menu item.
		 */
		[self selectSoundSet:soundMenuItem];

	}else{
		[self saveCurrentEventPreset];
	}
}

#pragma mark Sound sets
/*
 * @brief Called when an item in the sound set popUp is selected.
 *
 * Also called after the user changes sounds manually, by -[ESGlobalEventsPreferences contactAlertsDidChangeForActionID].
 */
- (IBAction)selectSoundSet:(id)sender
{
	NSString			*soundSetPath = ([sender representedObject] ?
										 [[sender representedObject] stringByCollapsingBundlePath] :
										 @"");
	
	//Apply the sound set so its events are in the current alerts.
	[plugin applySoundSetWithPath:soundSetPath];

	/* Update the selection, which will select Custom as appropriate.  This must be done before saving the event
	 * preset so the menu is on the correct sound set to save.
	 */
	[self updateSoundSetSelectionForSoundSetPath:soundSetPath];

	/* Save the preset which is now updated to have the appropriate sounds; 
	 * in saving, the name of the soundset, or @"", will also be saved.
	 */
	[self saveCurrentEventPreset];
}

/*
 * @brief Revert the event set to how it was before the last attempted operation
 */
- (void)revertToSavedEventSet
{
	NSDictionary		*eventPreset;

	[popUp_eventPreset selectItemWithTitle:[[adium preferenceController] preferenceForKey:@"Active Event Set"
																					group:PREF_GROUP_EVENT_PRESETS]];	
	eventPreset = [[popUp_eventPreset selectedItem] representedObject];

	[plugin setEventPreset:eventPreset];
	
	//Ensure the correct sound set is selected
	[self updateSoundSetSelection];
}

/*
 * @brief Build and return the event set as it should be saved
 */
- (NSMutableDictionary *)currentEventSetForSaving
{
	NSDictionary		*eventPreset = [[popUp_eventPreset selectedItem] representedObject];
	NSMutableDictionary	*currentEventSetForSaving = [[eventPreset mutableCopy] autorelease];
	
	//Set the sound set, which is just stored here for ease of preference pane display
	NSString	*soundSet = [[popUp_soundSet selectedItem] representedObject];
	
	[currentEventSetForSaving setObject:(soundSet ?
										 [soundSet stringByCollapsingBundlePath] :
										 @"")
								 forKey:KEY_EVENT_SOUND_SET];
	
	//Get and store the alerts array
	NSArray				*alertsArray = [[adium contactAlertsController] alertsForListObject:nil
																				withEventID:nil
																				   actionID:nil];
	[currentEventSetForSaving setObject:alertsArray forKey:@"Events"];

	//Ensure this set doesn't claim to be built in.
	[currentEventSetForSaving removeObjectForKey:@"Built In"];
	
	return(currentEventSetForSaving);
}

#pragma mark Preset saving

/*
 * @brief Save the current event preset
 *
 * Called after each event change to immediately update the current preset.
 * If a built-in preset is currently selected, this method will prompt for a new name before saving.
 */
- (void)saveCurrentEventPreset
{
	NSDictionary		*eventPreset = [[popUp_eventPreset selectedItem] representedObject];

	if([eventPreset objectForKey:@"Built In"] && [[eventPreset objectForKey:@"Built In"] boolValue]){
		/* Perform after a delay so that if we got here as a result of a sheet-based add or edit of an event
		 * the sheet will close before we try to open a new one. */
		[self performSelector:@selector(showPresetCopySheet:)
				   withObject:[eventPreset objectForKey:@"Name"]
				   afterDelay:0];
	}else{	
		//Now save the current settings
		[plugin saveEventPreset:[self currentEventSetForSaving]];
	}		
}

/*
 * @brief Show the sheet for naming the preset created by an attempt to modify a built-in set
 *
 * @param originalPresetName The name of the original set, used as a base for the new name.
 */
- (void)showPresetCopySheet:(NSString *)originalPresetName
{
	NSString	*defaultName;
	NSString	*explanatoryText;
	
	defaultName = [NSString stringWithFormat:@"%@ (%@)", originalPresetName, AILocalizedString(@"Copy",nil)];
	explanatoryText = AILocalizedString(@"You are editing a default event set.  Please enter a unique name for your modified set.",nil);
	
	[ESPresetNameSheetController showPresetNameSheetWithDefaultName:defaultName
													explanatoryText:explanatoryText
														   onWindow:[[self view] window]
													notifyingTarget:self
														   userInfo:nil];
}

- (BOOL)presetNameSheetController:(ESPresetNameSheetController *)controller
			  shouldAcceptNewName:(NSString *)newName
						 userInfo:(id)userInfo
{
	return(![[[plugin builtInEventPresets] allKeys] containsObject:newName] &&
		   ![[[plugin storedEventPresets] allKeys] containsObject:newName]);
}
	
- (void)presetNameSheetControllerDidEnd:(ESPresetNameSheetController *)controller 
							 returnCode:(ESPresetNameSheetReturnCode)returnCode
								newName:(NSString *)newName
							   userInfo:(id)userInfo
{
	switch(returnCode){
		case ESPresetNameSheetOkayReturn:
		{
			//XXX error if overwriting existing set?
			NSMutableDictionary	*newEventPreset = [self currentEventSetForSaving];
			[newEventPreset setObject:newName
							   forKey:@"Name"];
			
			//Now save the current settings
			[plugin saveEventPreset:newEventPreset];
			
			//Presets menu
			[[adium preferenceController] setPreference:newName
												 forKey:@"Active Event Set"
												  group:PREF_GROUP_EVENT_PRESETS];
			[popUp_eventPreset setMenu:[self eventPresetsMenu]];
			[popUp_eventPreset selectItemWithTitle:newName];
			
			break;
		}
		case ESPresetNameSheetCancelReturn:
		{
			[self revertToSavedEventSet];
			break;
		}
	}
}
		
/*!
 * @brief Called when the OK button on the preset copy sheet is pressed
 *
 * Save the current event set under the name specified by [textField_name stringValue].
 * Set the name of the active event set to this new name, and ensure our menu is up to date.
 *
 * Also, close the sheet.
 */
- (IBAction)selectedNameForPresetCopy:(id)sender
{
	
}

- (void)updateSoundSetSelectionForSoundSetPath:(NSString *)soundSetPath
{
	if(soundSetPath && [soundSetPath length] != 0){
		[popUp_soundSet selectItemWithRepresentedObject:[soundSetPath stringByExpandingBundlePath]];
		[self popUp:popUp_soundSet shouldShowCustom:NO];
		
	}else{
		[self popUp:popUp_soundSet shouldShowCustom:YES];
	}
}

- (void)updateSoundSetSelection
{
	NSDictionary	*eventPreset = [[popUp_eventPreset selectedItem] representedObject];
	
	//Update the soundset popUp
	NSString		*soundSetPath = [eventPreset objectForKey:KEY_EVENT_SOUND_SET];
	
	[self updateSoundSetSelectionForSoundSetPath:soundSetPath];
}

/*
 * @brief Build and return a menu of sound set choices
 *
 * The menu items have an action of -[self selectSoundSet:].
 */
- (NSMenu *)_soundSetMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*soundSetDict;
    NSMenu		*soundSetMenu = [[NSMenu alloc] init];
    
    enumerator = [[[adium soundController] soundSetArray] objectEnumerator];
    while((soundSetDict = [enumerator nextObject])){
        NSString		*setPath = [soundSetDict objectForKey:KEY_SOUND_SET];
        NSFileManager	*defaultManager = [NSFileManager defaultManager];
        NSMenuItem		*menuItem;
	
		//Ensure this folder contains a soundset file (Otherwise, we ignore it)
		if([defaultManager fileExistsAtPath:[setPath stringByAppendingPathComponent:[[[setPath stringByDeletingPathExtension] lastPathComponent] stringByAppendingPathExtension:@"txt"]]] ||
		   [defaultManager fileExistsAtPath:[setPath stringByAppendingPathComponent:@"Info.plist"]]){

            //Add a menu item for the set
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[setPath stringByDeletingPathExtension] lastPathComponent]
																			 target:self
																			 action:@selector(selectSoundSet:)
																	  keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:setPath];
            [soundSetMenu addItem:menuItem];
        }
    }

    return(soundSetMenu);
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
