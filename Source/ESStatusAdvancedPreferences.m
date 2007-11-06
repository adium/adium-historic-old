//
//  ESStatusAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

#import "CBStatusMenuItemPlugin.h"
#import "ESStatusAdvancedPreferences.h"
#import "AIStatusController.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIImageAdditions.h>

@implementation ESStatusAdvancedPreferences
//Preference pane properties
- (AIPreferenceCategory)category{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Status",nil);
}
- (NSString *)nibName{
    return @"StatusPreferencesAdvanced";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-status" forClass:[AIPreferenceWindowController class]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
	if (sender == matrix_quitConfirmation) {
		[self configureControlDimming];
	}
}

- (void)configureControlDimming
{
	BOOL		enableSpecificConfirmations = ([[matrix_quitConfirmation selectedCell] tag] == AIQuitConfirmSelective);
	
	[checkBox_quitConfirmFT			setEnabled:enableSpecificConfirmations];
	[checkBox_quitConfirmUnread		setEnabled:enableSpecificConfirmations];
	[checkBox_quitConfirmOpenChats	setEnabled:enableSpecificConfirmations];
}

//Configure the preference view
- (void)viewDidLoad
{
	[label_statusWindow setLocalizedString:AILocalizedString(@"Away Status Window", nil)];
	[checkBox_statusWindowHideInBackground setLocalizedString:AILocalizedString(@"Hide the status window when Adium is not active", nil)];
	[checkBox_statusWindowAlwaysOnTop setLocalizedString:AILocalizedString(@"Show the status window above other windows", nil)];
	
	[label_statusMenuItem setLocalizedString:AILocalizedString(@"Status Menu Item", nil)];
	[checkBox_statusMenuItemBadge setLocalizedString:AILocalizedString(@"Badge the menu item with current status", nil)];
	[checkBox_statusMenuItemFlash setLocalizedString:AILocalizedString(@"Flash when there are unread messages", nil)];
	
	[label_quitConfirmation setLocalizedString:AILocalizedString(@"Quit Confirmation", @"Preference")];
	[checkBox_quitConfirmFT setLocalizedString:AILocalizedString(@"When file transfers are in progress", @"Quit Confirmation preference")];
	[checkBox_quitConfirmUnread setLocalizedString:AILocalizedString(@"When there are unread messages", @"Quit Confirmation preference")];
	
	[label_quitConfirmationSentence setLocalizedString:AILocalizedString(@"When quitting Adium:", nil)];
	[[matrix_quitConfirmation cellWithTag:AIQuitConfirmNever] setTitle:AILocalizedString(@"Never confirm",@"Quit Confirmation preference")];
	[[matrix_quitConfirmation cellWithTag:AIQuitConfirmAlways] setTitle:AILocalizedString(@"Always confirm",@"Quit Confirmation preference")];
	[[matrix_quitConfirmation cellWithTag:AIQuitConfirmSelective] setTitle:AILocalizedString(@"Sometimes confirm",@"Quit Confirmation preference")];
	
	[self configureControlDimming];
	
	[super viewDidLoad];
}


@end
