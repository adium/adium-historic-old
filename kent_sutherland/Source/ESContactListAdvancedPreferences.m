//
//  ESContactListAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 2/20/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESContactListAdvancedPreferences.h"
#import "AISCLViewPlugin.h"
#import "AIInterfaceController.h"
#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

@interface ESContactListAdvancedPreferences (PRIVATE)
- (NSMenu *)windowPositionMenu;
- (void)configureControlDimming;
@end

/*!
 * @class ESContactListAdvancedPreferences
 * @brief Advanced contact list preferences
 */
@implementation ESContactListAdvancedPreferences

/*!
 * @brief Category
 */
- (PREFERENCE_CATEGORY)category{
    return AIPref_Advanced;
}

/*!
 * @brief Label
 */
- (NSString *)label{
    return CONTACT_LIST_TITLE;
}

/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"ContactListAdvancedPrefs";
}

/*!
 * @brief Image
 */
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-contactList" forClass:[AIPreferenceWindowController class]];
}

/*!
 * @brief View loaded; configure it for display
 */
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
	int 			menuIndex;
	
	[popUp_windowPosition setMenu:[[adium interfaceController] menuForWindowLevelsNotifyingTarget:self]];
	menuIndex =  [popUp_windowPosition indexOfItemWithTag:[[preferenceDict objectForKey:KEY_CL_WINDOW_LEVEL] intValue]];
	if (menuIndex >= 0 && menuIndex < [popUp_windowPosition numberOfItems]) {
		[popUp_windowPosition selectItemAtIndex:menuIndex];
	}
    [checkBox_hide setState:[[preferenceDict objectForKey:KEY_CL_HIDE] boolValue]];
	[checkBox_edgeSlide setState:[[preferenceDict objectForKey:KEY_CL_EDGE_SLIDE] boolValue]];
	
	[checkBox_flash setState:[[preferenceDict objectForKey:KEY_CL_FLASH_UNVIEWED_CONTENT] boolValue]];
	[checkBox_showTransitions setState:[[preferenceDict objectForKey:KEY_CL_SHOW_TRANSITIONS] boolValue]];
	[checkBox_showTooltips setState:[[preferenceDict objectForKey:KEY_CL_SHOW_TOOLTIPS] boolValue]];
	[checkBox_showTooltipsInBackground setState:[[preferenceDict objectForKey:KEY_CL_SHOW_TOOLTIPS_IN_BACKGROUND] boolValue]];
	[checkBox_windowHasShadow setState:[[preferenceDict objectForKey:KEY_CL_WINDOW_HAS_SHADOW] boolValue]];
	
#define WHILE_ADIUM_IS_IN_BACKGROUND	AILocalizedString(@"While Adium is in the background","Checkbox to indicate that something should occur while Adium is not the active application")
	
	[checkBox_hide setLocalizedString:WHILE_ADIUM_IS_IN_BACKGROUND];
	[checkBox_edgeSlide setLocalizedString:AILocalizedString(@"Automatically on screen edges", "Refers to a window sliding off the edge of the screen like the Dock")];
	[checkBox_flash setLocalizedString:AILocalizedString(@"Flash names with unviewed messages",nil)];
	[checkBox_showTransitions setLocalizedString:AILocalizedString(@"Show transitions as contacts sign on and off","Transitions in this context means the names fading in as the contact signs on and out as the contact signs off")];
	[checkBox_showTooltips setLocalizedString:AILocalizedString(@"Show contact information tooltips",nil)];
	[checkBox_showTooltipsInBackground setLocalizedString:WHILE_ADIUM_IS_IN_BACKGROUND];
	[checkBox_windowHasShadow setLocalizedString:AILocalizedString(@"Show window shadow",nil)];
	[checkBox_windowHasShadow setToolTip:@"Stay close to the Vorlon."];

	[label_appearance setLocalizedString:AILocalizedString(@"Appearance",nil)];
	[label_tooltips setLocalizedString:AILocalizedString(@"Tooltips",nil)];
	[label_windowHandling setLocalizedString:AILocalizedString(@"Window Handling",nil)];
	[label_hide setLocalizedString:AILocalizedString(@"Hide",nil)];
	[label_orderTheContactList setLocalizedString:AILocalizedString(@"Show the contact list:",nil)];
	
	[self configureControlDimming];
}

/*!
 * @brief Called in response to all preference controls, applies new settings
 */
- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_hide) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CL_HIDE
											  group:PREF_GROUP_CONTACT_LIST];
		
    } else if (sender == checkBox_edgeSlide) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CL_EDGE_SLIDE
											  group:PREF_GROUP_CONTACT_LIST];
	} else if (sender == checkBox_flash) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CL_FLASH_UNVIEWED_CONTENT
											  group:PREF_GROUP_CONTACT_LIST];
		
    } else if (sender == checkBox_showTransitions) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CL_SHOW_TRANSITIONS
											  group:PREF_GROUP_CONTACT_LIST];
		
    } else if (sender == checkBox_showTooltips) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CL_SHOW_TOOLTIPS
											  group:PREF_GROUP_CONTACT_LIST];
		[self configureControlDimming];

	} else if (sender == checkBox_showTooltipsInBackground) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_CL_SHOW_TOOLTIPS_IN_BACKGROUND
											  group:PREF_GROUP_CONTACT_LIST];
		
	} else if (sender == checkBox_windowHasShadow) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_CL_WINDOW_HAS_SHADOW
											  group:PREF_GROUP_CONTACT_LIST];
		
    }
}

/*!
 * @brief User selected a window level
 */
- (void)selectedWindowLevel:(id)sender
{	
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
										 forKey:KEY_CL_WINDOW_LEVEL
										  group:PREF_GROUP_CONTACT_LIST];
}

/*!
 * @brief Configure control dimming
 */
- (void)configureControlDimming
{
	[checkBox_showTooltipsInBackground setEnabled:([checkBox_showTooltips state] == NSOnState)];
}

@end
