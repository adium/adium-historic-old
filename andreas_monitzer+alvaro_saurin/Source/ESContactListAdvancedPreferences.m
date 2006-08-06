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
#import "AIListWindowController.h"
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
	int	menuIndex;

	[popUp_windowPosition setMenu:[[adium interfaceController] menuForWindowLevelsNotifyingTarget:self]];
	menuIndex =  [popUp_windowPosition indexOfItemWithTag:[[[adium preferenceController] preferenceForKey:KEY_CL_WINDOW_LEVEL
																									 group:PREF_GROUP_CONTACT_LIST] intValue]];
	if (menuIndex >= 0 && menuIndex < [popUp_windowPosition numberOfItems]) {
		[popUp_windowPosition selectItemAtIndex:menuIndex];
	}

#define WHILE_ADIUM_IS_IN_BACKGROUND	AILocalizedString(@"While Adium is in the background","Checkbox to indicate that something should occur while Adium is not the active application")

	[[matrix_hiding cellWithTag:AIContactListWindowHidingStyleNone] setTitle:AILocalizedString(@"Never", nil)];
	[[matrix_hiding cellWithTag:AIContactListWindowHidingStyleBackground] setTitle:WHILE_ADIUM_IS_IN_BACKGROUND];
	[[matrix_hiding cellWithTag:AIContactListWindowHidingStyleSliding] setTitle:AILocalizedString(@"On screen edges", "Advanced contact list: hide the contact list: On screen edges")];

	[checkBox_flash setLocalizedString:AILocalizedString(@"Flash names with unviewed messages",nil)];
	[checkBox_showTransitions setLocalizedString:AILocalizedString(@"Show transitions as contacts sign on and off","Transitions in this context means the names fading in as the contact signs on and out as the contact signs off")];
	[checkBox_showTooltips setLocalizedString:AILocalizedString(@"Show contact information tooltips",nil)];
	[checkBox_showTooltipsInBackground setLocalizedString:WHILE_ADIUM_IS_IN_BACKGROUND];
	[checkBox_windowHasShadow setLocalizedString:AILocalizedString(@"Show window shadow",nil)];
	[checkBox_windowHasShadow setToolTip:@"Stay close to the Vorlon."];

	[label_appearance setLocalizedString:AILocalizedString(@"Appearance",nil)];
	[label_tooltips setLocalizedString:AILocalizedString(@"Tooltips",nil)];
	[label_windowHandling setLocalizedString:AILocalizedString(@"Window Handling",nil)];
	[label_hide setLocalizedString:AILocalizedString(@"Automatically hide the contact list:",nil)];
	[label_orderTheContactList setLocalizedString:AILocalizedString(@"Show the contact list:",nil)];
	
	[self configureControlDimming];
}

/*!
 * @brief Called in response to all preference controls, applies new settings
 */
- (IBAction)changePreference:(id)sender
{
	if (sender == matrix_hiding) {
		[self configureControlDimming];
	}
}

- (void)configureControlDimming
{
	[checkBox_hideOnScreenEdgesOnlyInBackground setEnabled:([[matrix_hiding selectedCell] tag] == AIContactListWindowHidingStyleSliding)];
}

- (void)selectedWindowLevel:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
										 forKey:KEY_CL_WINDOW_LEVEL
										  group:PREF_GROUP_CONTACT_LIST];
}

@end
