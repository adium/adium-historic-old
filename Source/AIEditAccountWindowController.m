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

#import "AIAccountController.h"
#import "AIAccountProxySettings.h"
#import "AIContactController.h"
#import "AIPreferenceController.h"
#import "AIEditAccountWindowController.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITabViewAdditions.h>
#import <AIUtilities/AIViewAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/ESImageViewWithImagePicker.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAccountViewController.h>
#import <Adium/AIService.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>

@interface AIEditAccountWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName account:(AIAccount *)inAccount notifyingTarget:(id)inTarget;
- (void)_addCustomViewAndTabsForAccount:(AIAccount *)inAccount;
- (int)_addCustomView:(NSView *)customView toView:(NSView *)setupView tabViewItemIdentifier:(NSString *)identifier
	  availableHeight:(int)height;
- (void)_configureResponderChain:(NSTimer *)inTimer;
- (void)_removeCustomViewAndTabs;
- (void)_localizeTabViewItemLabels;
- (void)saveConfiguration;
@end

/*!
 * @class AIEditAccountWindowController
 * @brief Window controller for configuring an <tt>AIAccount</tt>
 */
@implementation AIEditAccountWindowController

/*!
 * @brief Begin editing
 *
 * @param inAccount The account to edit
 * @param parentWindow A window on which to show the edit account window as a sheet.  If nil, account editing takes place in an independent window.
 * @param notifyingTarget Target to notify when editing is complete.
 */
+ (void)editAccount:(AIAccount *)inAccount onWindow:(id)parentWindow notifyingTarget:(id)inTarget
{
	AIEditAccountWindowController	*controller;

	controller = [[self alloc] initWithWindowNibName:@"EditAccountSheet"
											 account:inAccount
									 notifyingTarget:inTarget];

	if (parentWindow) {
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[controller showWindow:nil];
	}
}

/*!
 * @brief Init the window controller
 */
- (id)initWithWindowNibName:(NSString *)windowNibName account:(AIAccount *)inAccount notifyingTarget:(id)inTarget
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		account = [inAccount retain];
		notifyTarget = inTarget;
		userIconData = nil;
		didDeleteUserIcon = NO;
	}
	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[account release];
	[userIconData release]; userIconData = nil;

	[super dealloc];
}

/*!
 * @brief Setup the window before it is displayed
 */
- (void)windowDidLoad
{
	//Center our window if we're not a sheet (or opening a sheet failed)
	[[self window] center];

	//Account Overview
	[textField_serviceName setStringValue:[[account service] longDescription]];
	[textField_accountDescription setStringValue:[account UID]];
	[checkBox_autoConnect setState:[[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_autoConnect setLocalizedString:AILocalizedString(@"Automatically connect on launch","Accounts preferences: When Adium loads, connect this account immediately.")];
	[button_chooseIcon setLocalizedString:[AILocalizedString(@"Choose Icon",nil) stringByAppendingEllipsis]];
	[button_OK setLocalizedString:AILocalizedString(@"OK",nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];

	//User icon
	[imageView_userIcon setImage:[account userIcon]];

	//Insert the custom controls for this account
	[self _removeCustomViewAndTabs];
	[self _addCustomViewAndTabsForAccount:account];
	[self _localizeTabViewItemLabels];
}

/*!
 * @brief Window is closing
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	[self autorelease];
}

/*!
 * @brief Called as the user list edit sheet closes, dismisses the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

/*!
 * @brief Cancel
 *
 * Close without saving changes.
 */
- (IBAction)cancel:(id)sender
{
	if (notifyTarget) [notifyTarget editAccountSheetDidEndForAccount:account withSuccess:NO];
	[self closeWindow:nil];
}

/*!
 * @brief Okay.
 *
 * Save changes and close.
 */
- (IBAction)okay:(id)sender
{
	[self saveConfiguration];
	[accountViewController saveConfiguration];
	[accountProxyController saveConfiguration];

	if (notifyTarget) [notifyTarget editAccountSheetDidEndForAccount:account withSuccess:YES];
	[self closeWindow:nil];
}

/*!
 * @brief Save any configuration managed by the window controller
 *
 * Most configuration is handled by the custom view controllers.  Save any other configuration, such as the user icon.
 */
- (void)saveConfiguration
{
	/* User icon - save if we have data or we deleted
	 * (so if we don't have data that's the desired thing to set as the pref) */
	if (userIconData || didDeleteUserIcon) {
		[account setPreference:userIconData
						forKey:KEY_USER_ICON
						 group:GROUP_ACCOUNT_STATUS];
	}
	
	//Auto connect
	[account setPreference:[NSNumber numberWithBool:[checkBox_autoConnect state]]
					forKey:@"AutoConnect"
					 group:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Add the custom views for an account
 */
- (void)_addCustomViewAndTabsForAccount:(AIAccount *)inAccount
{
	NSRect	windowFrame = [[self window] frame];
	int		baseHeight = [view_accountSetup frame].size.height;
	int		newHeight = baseHeight;

	//Configure our account and proxy view controllers
	accountViewController = [[[inAccount service] accountViewController] retain];
	[accountViewController configureForAccount:inAccount];

	accountProxyController = ([[inAccount service] supportsProxySettings] ?
							  [[AIAccountProxySettings alloc] init] :
							  nil);
	[accountProxyController configureForAccount:inAccount];

	//Account setup view
	newHeight = [self _addCustomView:[accountViewController setupView]
						   toView:view_accountSetup
			tabViewItemIdentifier:@"account"
				  availableHeight:newHeight];
	
	//Account Profile View
	newHeight = [self _addCustomView:[accountViewController profileView]
						   toView:view_accountProfile
			tabViewItemIdentifier:@"profile"
				  availableHeight:newHeight];
	
	//Account Options view
	newHeight = [self _addCustomView:[accountViewController optionsView]
						   toView:view_accountOptions
			tabViewItemIdentifier:@"options"
				  availableHeight:newHeight];
	
	//Account Privacy view
	newHeight = [self _addCustomView:[accountViewController privacyView]
						   toView:view_accountPrivacy
			tabViewItemIdentifier:@"privacy"
				  availableHeight:newHeight];
	
	//Add proxy view
	newHeight = [self _addCustomView:[accountProxyController view]
						   toView:view_accountProxy
			tabViewItemIdentifier:@"proxy"
				  availableHeight:newHeight];
	
	//Resize our window as necessary to make room for the custom views
	windowFrame.size.height += newHeight - [view_accountSetup frame].size.height;
	[[self window] setFrame:windowFrame display:YES];
	
	//Responder chains are a pain in 10.3.  The tab view will set them up correctly when we switch tabs, but doesn't
	//get a chance to setup the responder chain for our default tab.  A quick hack to get the tab view to set things
	//up correctly is to switch tabs away and then back to our default.  This causes little harm, since our window
	//isn't visible at this point anyway.
	//XXX - I believe we're getting a method that will avoid the need for this hack in 10.4 -ai
	[tabView_auxiliary selectLastTabViewItem:nil];
	[tabView_auxiliary selectFirstTabViewItem:nil];
}

/*!
 * @brief Used when configuring to add custom views and remove tabs as necessary
 *
 * Add customView to setupView and return the height difference between the two if customView is taller than setupView.
 * Remove the tabViewItem with the passed identifier if no customView exists, avoiding empty tabs.
 *
 * @param customView The view to add
 * @param setupView The view within our nib which will be filled by customView
 * @param identifier Identifier of the <tt>NSTabViewItem</tt> which will be removed from tabView_auxiliary if customView == nil
 * @param requiredHeight The current required view height to display all our views
 * @result The new required window height to display our existing views and the newly added view
 */
- (int)_addCustomView:(NSView *)customView toView:(NSView *)setupView tabViewItemIdentifier:(NSString *)identifier
	  availableHeight:(int)height
{
	if (customView) {
		//Adjust height as necessary if our view needs more room
		if ([customView frame].size.height > height) {
			height = [customView frame].size.height;
		}

		//Align our view to the top and insert it into the window
		[customView setFrameOrigin:NSMakePoint(0, [setupView frame].size.height - [customView frame].size.height)];
		[customView setAutoresizingMask:NSViewMinYMargin];
		[setupView addSubview:customView];

	} else {
		//If no view is available, remove the corresponding tab
		[tabView_auxiliary removeTabViewItem:[tabView_auxiliary tabViewItemWithIdentifier:identifier]];
	}

	return(height);
}

/*!
 * @brief Remove any existing custom views
 */
- (void)_removeCustomViewAndTabs
{
    //Close any currently open controllers
    [view_accountSetup removeAllSubviews];
    [accountViewController release]; accountViewController = nil;
}

/*!
 * @brief Localization
 */
- (void)_localizeTabViewItemLabels
{
	[[tabView_auxiliary tabViewItemWithIdentifier:@"account"] setLabel:AILocalizedString(@"Account",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"profile"] setLabel:AILocalizedString(@"Personal",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"options"] setLabel:AILocalizedString(@"Options",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"privacy"] setLabel:AILocalizedString(@"Privacy",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"proxy"] setLabel:AILocalizedString(@"Proxy",nil)];
}


// ESImageViewWithImagePicker Delegate ---------------------------------------------------------------------
#pragma mark ESImageViewWithImagePicker Delegate
- (void)imageViewWithImagePicker:(ESImageViewWithImagePicker *)sender didChangeToImageData:(NSData *)imageData
{
	[userIconData release];
	userIconData = [imageData retain];
}

- (void)deleteInImageViewWithImagePicker:(ESImageViewWithImagePicker *)sender
{
	[userIconData release]; userIconData = nil;
	didDeleteUserIcon = YES;

	//User icon - restore to the default icon
	[imageView_userIcon setImage:[account userIcon]];
}

@end
