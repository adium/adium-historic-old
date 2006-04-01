//
//  AdiumUnreadMessagesQuitConfirmation.m
//  Adium
//
//  Created by Matt Molinaro on 03/25/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "AdiumFileTransferQuitConfirmation.h"
#import "AIPreferenceController.h"

#define PREF_GROUP_CONFIRMATIONS @"Confirmations"

/*!
 * @class AdiumUnreadMessagesQuitConfirmation
 * @brief Window controller for a confirmation when quitting with unread messages
 */
@implementation AdiumFileTransferQuitConfirmation
static AdiumFileTransferQuitConfirmation *fileTransferWindowController = nil;

/*
 * @brief Show the unread messages quit confirmation dialog
 */
+ (void)showFileTransferQuitConfirmation
{
	if (!fileTransferWindowController) {
		fileTransferWindowController = [[self alloc] initWithWindowNibName:@"FileTransferQuitConfirmation"];
	}

	//Configure and show window
	[fileTransferWindowController showWindow:nil];
	[[fileTransferWindowController window] makeKeyAndOrderFront:nil];	
}

/*
 * @brief Window loaded
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[[self window] setTitle:AILocalizedString(@"Quit Confirmation","Quit confirmation window title")];
	[button_quit setLocalizedString:AILocalizedString(@"Quit", nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];
	[checkBox_dontAskAgain setLocalizedString:AILocalizedString(@"Don't ask again", "Button for stopping the quit confirmation from being shown again")];
	[textField_quitConfirmation setStringValue:AILocalizedString(@"You have file transfers in progress.\nAre you sure you want to quit?",nil)];
	
	[[self window] center];
}

/*!
 * @brief Perform behaviors before the window closes
 *
 * As our window is closing, we auto-release this window controller instance.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	[fileTransferWindowController autorelease];
	fileTransferWindowController = nil;
}

/*
 * @brief Pressed a buton
 *
 * If Quit is pressed, the Don't Ask Again checkbox is checked and the preference saved if appropriate
 */
- (IBAction)pressedButton:(id)sender;
{
	if (sender == button_quit) {
		if ([checkBox_dontAskAgain state] == NSOnState) {
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
												 forKey:@"Suppress Quit Confirmation for File Transfers"
												  group:PREF_GROUP_CONFIRMATIONS];
		}
			
		[NSApp terminate:nil];
	}

	[[self window] close];
}

@end

