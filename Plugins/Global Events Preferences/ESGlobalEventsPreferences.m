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

#define PREF_GROUP_EVENT_PRESETS			@"Event Presets"
#define CUSTOM_TITLE						AILocalizedString(@"Custom",nil)

#define VERTICAL_ROW_PADDING	4
#define MINIMUM_ROW_HEIGHT		30

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

	//Show menu
	[popUp_show setMenu:[self showMenu]];

	//Presets menu
	[self setAndConfigureEventPresetsMenu];

	[label_soundSet setLocalizedString:AILocalizedString(@"Sound set:",nil)];

	AIGradientImageCell				*imageCell;
	AIVerticallyCenteredTextCell	*textCell;

	imageCell = [[AIGradientImageCell alloc] init];
	[imageCell setDrawsGradientHighlight:YES];
	[imageCell setAlignment:NSCenterTextAlignment];
	[imageCell setMaxSize:NSMakeSize(32, 32)];
	[[outlineView_summary tableColumnWithIdentifier:@"image"] setDataCell:imageCell];
	[imageCell release];
	
	textCell = [[AIVerticallyCenteredTextCell alloc] init];
	[textCell setFont:[NSFont boldSystemFontOfSize:12]];
	[textCell setDrawsGradientHighlight:YES];
	[[outlineView_summary tableColumnWithIdentifier:@"event"] setDataCell:textCell];
	[textCell release];
	
	textCell = [[AIVerticallyCenteredTextCell alloc] init];
	[textCell setFont:[NSFont systemFontOfSize:10]];
	[textCell setDrawsGradientHighlight:YES];
	[[outlineView_summary tableColumnWithIdentifier:@"action"] setDataCell:textCell];
	[textCell release];
	
	
	[outlineView_summary setDrawsAlternatingRows:YES];
	[outlineView_summary setIntercellSpacing:NSMakeSize(6.0,4.0)];
	[outlineView_summary setTarget:self];
	[outlineView_summary setDoubleAction:@selector(configureSelectedEvent:)];

	//Observe contact alerts preferences to update our summary
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_ALERTS];

	//And event presets to update our presets menu
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EVENT_PRESETS];

	//Enable/disable our configure button as appropriate
	[button_configure setEnabled:([outlineView_summary selectedRow] != -1)];

	//Ensure the correct sound set is selected
	[self updateSoundSetSelection];

	//Ensure we start off on the summary tab
	[self selectShowSummary:nil];
	
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
	
	[contactAlertsEvents release]; contactAlertsEvents = nil;
	[contactAlertsActions release]; contactAlertsActions = nil;
}

/*
 * @brief Reload the information for our summary table, then update it
 */
- (void)reloadSummaryData
{
	//Get two parallel arrays for event IDs and the array of actions for that event ID
	NSDictionary	*contactAlertsDict = [[adium preferenceController] preferenceForKey:KEY_CONTACT_ALERTS
																				  group:PREF_GROUP_CONTACT_ALERTS
															  objectIgnoringInheritance:nil];
	NSEnumerator	*enumerator = [contactAlertsDict keyEnumerator];
	NSString		*eventID;
	contactAlertsEvents = [[NSMutableArray alloc] init];
	contactAlertsActions = [[NSMutableArray alloc] init];
	while(eventID = [enumerator nextObject]){
		[contactAlertsEvents addObject:eventID];
		[contactAlertsActions addObject:[contactAlertsDict objectForKey:eventID]];
	}
	
	[outlineView_summary reloadData];	
}

/*
 * @brief PREF_GROUP_CONTACT_ALERTS changed; update our summary data
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if([group isEqualToString:PREF_GROUP_CONTACT_ALERTS]){
		[self reloadSummaryData];
	}else if([group isEqualToString:PREF_GROUP_EVENT_PRESETS]){
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

- (NSArray *)renamePreset:(NSDictionary *)preset toName:(NSString *)name inPresets:(NSArray *)presets
{
	NSMutableDictionary	*newPreset = [preset mutableCopy];
	[newPreset setObject:name
				  forKey:@"Name"];
	
	//Remove the original one from the array, and add the newly-renamed one
	[plugin deleteEventPreset:preset];
	[plugin saveEventPreset:newPreset];

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

#pragma mark Summary and specific events
/*
 * @brief Menu of Show: options
 *
 * First has the Event Action Summary item, then has an item for each event
 */
- (NSMenu *)showMenu
{
	NSMenu			*showMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSMenuItem		*menuItem;
	NSEnumerator	*enumerator;
	
	//Add a menu item for the set
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Event Action Summary",nil)
																	 target:self
																	 action:@selector(selectShowSummary:)
															  keyEquivalent:@""] autorelease];
	[showMenu addItem:menuItem];
	
	[showMenu addItem:[NSMenuItem separatorItem]];
	
	enumerator = [[[adium contactAlertsController] arrayOfMenuItemsForEventsWithTarget:self
																		  forGlobalMenu:YES] objectEnumerator];
	while(menuItem = [enumerator nextObject]){
		[showMenu addItem:menuItem];
	}

	return([showMenu autorelease]);	
}

#pragma mark Summary
/*!
 * @brief Show the summary tab
 *
 * Called by the Show popUp menu item for the summary or by the button in the Event tab
 */
- (IBAction)selectShowSummary:(id)sender
{
	[tabView_summaryAndConfig selectTabViewItemWithIdentifier:@"summary"];

	//Ensure the Summary menu item is selected, as we can get here by means other than the user selecting it
	[popUp_show selectItemAtIndex:0];
}

/*
 * @brief Configure the currently selected event type
 *
 * This is triggerred by a double click on a row in the outline view or by clicking the Configure... button
 */
- (IBAction)configureSelectedEvent:(id)sender
{
	int		row = [outlineView_summary selectedRow];

	if(row != -1){
		NSArray	*contactEvents = [outlineView_summary itemAtRow:row];
		
		if(contactEvents){
			[self editEventsWithEventID:[[contactEvents objectAtIndex:0] objectForKey:KEY_EVENT_ID]];
		}
	}
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(int)index ofItem:(id)item
{
	if(index < [contactAlertsActions count]) {
		return([contactAlertsActions objectAtIndex:index]);
	} else {
		return nil;
	}
}

- (int)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(id)item
{
	return([contactAlertsActions count]);
}

//No items are expandable for the outline view
- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(id)item
{
	return(NO);
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSArray	*contactEvents = (NSArray *)item;
	
	if([[tableColumn identifier] isEqualToString:@"event"]){
		return([[adium contactAlertsController] globalShortDescriptionForEventID:[[contactEvents objectAtIndex:0] objectForKey:KEY_EVENT_ID]]);
		
	}else if([[tableColumn identifier] isEqualToString:@"action"]){
		NSMutableString	*actionDescription = [NSMutableString string];
		NSDictionary	*eventDict;
		BOOL			appended = NO;
		unsigned		i, count;
		
		count = [contactEvents count];
		for(i = 0; i < count; i++){
			NSString				*actionID;
			id <AIActionHandler>	actionHandler;
			
			eventDict = [contactEvents objectAtIndex:i];
			actionID = [eventDict objectForKey:KEY_ACTION_ID];
			actionHandler = [[[adium contactAlertsController] actionHandlers] objectForKey:actionID];
			
			if(actionHandler){
				NSString	*thisDescription;
				
				thisDescription = [actionHandler longDescriptionForActionID:actionID
																withDetails:[eventDict objectForKey:KEY_ACTION_DETAILS]];
				if(thisDescription && [thisDescription length]){
					if(appended){
						/* We are on the second or later action. */
						NSString	*conjunctionIfNeeded;
						NSString	*commaAndSpaceIfNeeded;
							
						//If we have more than 2 actions, we'll be combining them with commas
						if(count > 2){
							commaAndSpaceIfNeeded = @",";
						}else{
							commaAndSpaceIfNeeded = @"";
						}
						
						//If we are on the last action, we'll want to add a conjunction to finish the compound sentence
						if(i == (count - 1)){
							conjunctionIfNeeded = AILocalizedString(@" and","conjunction to end a compound sentence");
						}else{
							conjunctionIfNeeded = @"";
						}

						//Construct the string to append, then append it
						[actionDescription appendString:[NSString stringWithFormat:@"%@%@ %@%@",
							commaAndSpaceIfNeeded,
							conjunctionIfNeeded,
							[[thisDescription substringToIndex:1] lowercaseString],
							[thisDescription substringFromIndex:1]]];
						
					}else{
						/* We are on the first action.
						 *
						 * This is easy; just append the description.
						 */
						[actionDescription appendString:thisDescription];
						appended = YES;
					}
				}
			}
		}

		return actionDescription;

	}else if ([[tableColumn identifier] isEqualToString:@"image"]){
		return([[adium contactAlertsController] imageForEventID:[[contactEvents objectAtIndex:0] objectForKey:KEY_EVENT_ID]]);
	}
	
	return(@"");
}

//Each row should be tall enough to fit the number of lines of events
- (int)outlineView:(NSOutlineView *)inOutlineView heightForItem:(id)item atRow:(int)row
{
	NSEnumerator	*enumerator;
	NSTableColumn	*tableColumn;
	float			necessaryHeight = 0;
	
	enumerator = [[inOutlineView tableColumns] objectEnumerator];
	while(tableColumn = [enumerator nextObject]){
		if([[tableColumn identifier] isEqualToString:@"event"] || [[tableColumn identifier] isEqualToString:@"action"]){
			NSString		*objectValue = [self outlineView:inOutlineView objectValueForTableColumn:tableColumn byItem:item];
			float			thisHeight;
			NSFont			*font = [[tableColumn dataCell] font];
			NSDictionary	*attributes = nil;
			
			if(font){
				attributes = [NSDictionary dictionaryWithObjectsAndKeys:
					font, NSFontAttributeName, nil];
			}
			
			NSAttributedString	*attributedTitle = [[NSAttributedString alloc] initWithString:objectValue
																				   attributes:attributes];
			thisHeight = [attributedTitle heightWithWidth:[tableColumn width]];
			if(thisHeight > necessaryHeight) necessaryHeight = thisHeight;
		}
	}

	/*
	NSDictionary	*contactEvents = [contactAlertsActions objectAtIndex:row];

	return(17 * [contactEvents count]);
	 */
	necessaryHeight += VERTICAL_ROW_PADDING;

	return ((necessaryHeight > MINIMUM_ROW_HEIGHT) ? necessaryHeight : MINIMUM_ROW_HEIGHT);
}

- (void)outlineView:(NSOutlineView *)inOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{

}

/*
 * @brief Outline view selection changed
 *
 * For our summary table, disable the Configure button if no row is selected.
 * Also, give action handlers a change to preview.
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSOutlineView	*outlineView = [notification object];
	if(outlineView == outlineView_summary){
		//Enable/disable our configure button
		int row = [outlineView_summary selectedRow];
		[button_configure setEnabled:(row != -1)];
		
		NSDictionary	*eventDict;
		NSEnumerator	*enumerator;
		NSMutableSet	*perfomedPreviewsSet = [NSMutableSet set];
		
		//Preview each action if the action handler supports it
		enumerator = [[outlineView_summary itemAtRow:row] objectEnumerator];
		while(eventDict = [enumerator nextObject]){			
			NSString				*actionID;
			id <AIActionHandler>	actionHandler;

			actionID = [eventDict objectForKey:KEY_ACTION_ID];

			if(![perfomedPreviewsSet containsObject:actionID]){
				actionHandler = [[[adium contactAlertsController] actionHandlers] objectForKey:actionID];
				
				if(actionHandler && [actionHandler respondsToSelector:@selector(performPreviewForAlert:)]){
					[(id)actionHandler performPreviewForAlert:eventDict];
					[perfomedPreviewsSet addObject:actionID];
				}				
			}
		}
	}
}

- (void)deleteContactEvents:(NSArray *)contactEvents
{
	NSDictionary	*eventDict;
	NSEnumerator	*enumerator;

	[[adium preferenceController] delayPreferenceChangedNotifications:YES];
	enumerator = [contactEvents objectEnumerator];
	while(eventDict = [enumerator nextObject]){			
		[[adium contactAlertsController] removeAlert:eventDict fromListObject:nil];
	}
	[[adium preferenceController] delayPreferenceChangedNotifications:NO];

	//Save the current preset
	[self saveCurrentEventPreset];	
}

- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)inOutlineView
{
	int		row = [inOutlineView selectedRow];

	//Remove
	if(row != -1){
		NSArray		*contactEvents = [outlineView_summary itemAtRow:row];
		unsigned	contactEventsCount = [contactEvents count];
		
		if(contactEventsCount > 1){
			//Warn before deleting more than one event simultaneously
			NSBeginAlertSheet(AILocalizedString(@"Delete Event?",nil),
							  AILocalizedString(@"OK",nil),
							  AILocalizedString(@"Cancel",nil),
							  nil, /*otherButton*/
							  [[self view] window],
							  self,
							  @selector(sheetDidEnd:returnCode:contextInfo:),
							  NULL, /* didDismissSelector */
							  contactEvents,
							  AILocalizedString(@"Remove all %i actions associated with this event?",nil), contactEventsCount);
		}else{
			//Delete a single event immediately
			[self deleteContactEvents:contactEvents];
		}
	}else{
		NSBeep();
	}
}

/*
 * @brief Warning sheet for deleting multiple events ended
 *
 * If the user pressed OK, go ahead with deleting the events.
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertDefaultReturn){
		[self deleteContactEvents:(NSArray *)contextInfo];
	}
}

#pragma mark Specific events
/*
 * @brief User selected an event from the Show: menu
 *
 * Edit the actions for the selected event.
 */
- (IBAction)selectEvent:(id)sender
{
	NSString	*eventID;
	if(eventID = [sender representedObject]){
		[self editEventsWithEventID:eventID];
	}
}

/*!
 * @brief Edit events for a specified event ID
 *
 * Configure the contact alerts view controller, update our tab view, update the Show menu
 */
- (void)editEventsWithEventID:(NSString *)eventID
{
	[contactAlertsViewController configureForListObject:nil showingAlertsForEventID:eventID];	

	[tabView_summaryAndConfig selectTabViewItemWithIdentifier:@"event"];
	
	[popUp_show selectItemWithRepresentedObject:eventID];
}

/*
 * @brief Called by the contact alerts controller to determine the event ID to use for a new contact alert
 *
 * We have disabled the Event popup in the contact alerts controller's NewAlert sheet (in viewDidLoad) so
 * we need to inform it with each NewAlert for what event to configure.  We configure for the event currently
 * showin the Show: popUp.
 */
- (NSString *)initialEventIDForNewContactAlert
{
	id initialEventID;

	initialEventID = [[popUp_show selectedItem] representedObject];

	if(![initialEventID isKindOfClass:[NSString class]]) initialEventID = nil;

	return((NSString *)initialEventID);
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
	[self updateSoundSetSelection];

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

- (void)updateSoundSetSelection
{
	NSDictionary	*eventPreset = [[popUp_eventPreset selectedItem] representedObject];
	
	//Update the soundset popUp
	NSString		*soundSetPath = [eventPreset objectForKey:KEY_EVENT_SOUND_SET];
	if(soundSetPath && [soundSetPath length] != 0){
		[popUp_soundSet selectItemWithRepresentedObject:[soundSetPath stringByExpandingBundlePath]];
		[self popUp:popUp_soundSet shouldShowCustom:NO];
		
	}else{
		[self popUp:popUp_soundSet shouldShowCustom:YES];
	}
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
        NSString	*setPath = [soundSetDict objectForKey:KEY_SOUND_SET];
        NSMenuItem	*menuItem;
        NSString	*soundSetFile;
		
        //Ensure this folder contains a soundset file (Otherwise, we ignore it)
        soundSetFile = [NSString stringWithContentsOfFile:
			[setPath stringByAppendingPathComponent:[[[setPath stringByDeletingPathExtension] lastPathComponent] stringByAppendingPathExtension:@"txt"]]];
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

/*
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
*/