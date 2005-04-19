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
- (id)initWithWindowNibName:(NSString *)windowNibName account:(AIAccount *)inAccount isNewAccount:(BOOL)inIsNewAccount;
- (void)_addCustomViewAndTabsForAccount:(AIAccount *)inAccount;
- (int)_addCustomView:(NSView *)customView toView:(NSView *)setupView tabViewItemIdentifier:(NSString *)identifier;
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
 * @param inIsNewAccount If YES and the user presses cancel, inAccount is deleted. This should be passed as YES when the method is called as a result of creating a new account.
 */
+ (void)editAccount:(AIAccount *)inAccount onWindow:(id)parentWindow isNewAccount:(BOOL)inIsNewAccount
{
	AIEditAccountWindowController	*controller;

	controller = [[self alloc] initWithWindowNibName:@"EditAccountSheet"
											 account:inAccount
									isNewAccount:inIsNewAccount];

	if(parentWindow){
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[controller showWindow:nil];
	}
}

/*!
 * @brief Init the window controller
 */
- (id)initWithWindowNibName:(NSString *)windowNibName account:(AIAccount *)inAccount isNewAccount:(BOOL)inIsNewAccount
{
	if((self = [super initWithWindowNibName:windowNibName])) {
		account = [inAccount retain];
		isNewAccount = inIsNewAccount;
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
	NSData	*iconData;

	//Center our window if we're not a sheet (or opening a sheet failed)
	[[self window] center];

	//Account Overview
	/*
	[image_serviceIcon setImage:[AIServiceIcons serviceIconForService:[account service]
																 type:AIServiceIconLarge
															direction:AIIconNormal]];
	 */
	[textField_serviceName setStringValue:[[account service] longDescription]];
	[textField_accountDescription setStringValue:[account UID]];
	[checkBox_autoConnect setState:[[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]];

	//User icon
	if(iconData = [account preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]){
		NSImage *image = [[NSImage alloc] initWithData:iconData];
		[imageView_userIcon setImage:image];
		[image release];
	}


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
 * Close without saving changes. If isNewAccount is YES, delete the account at this time.
 * isNewAccount should only be YES if we were called to edit a newly created account. Canceling the process should
 * delete the account which we were passed.
 */
- (IBAction)cancel:(id)sender
{
	if(isNewAccount){
		[[adium accountController] deleteAccount:account save:YES];
	}

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
	[self closeWindow:nil];

	//Put new accounts online by default
	if(isNewAccount){
		[account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	}
	
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
	if(userIconData || didDeleteUserIcon){
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
	NSRect	windowFrame;
	int		heightChange = 0;
	int		heightDifference;

	windowFrame = [[self window] frame];

	//Configure our account and proxy view controllers
	accountViewController = [[[inAccount service] accountViewController] retain];
	[accountViewController configureForAccount:inAccount];

	accountProxyController = ([[inAccount service] supportsProxySettings] ?
							  [[AIAccountProxySettings alloc] init] :
							  nil);
	[accountProxyController configureForAccount:inAccount];

	//Account setup view
	heightDifference = [self _addCustomView:[accountViewController setupView]
									 toView:view_accountSetup
					  tabViewItemIdentifier:@"account"];
	if(heightDifference > heightChange) heightChange = heightDifference;

	//Account Profile View
	heightDifference = [self _addCustomView:[accountViewController profileView]
									 toView:view_accountProfile
					  tabViewItemIdentifier:@"profile"];
	if(heightDifference > heightChange) heightChange = heightDifference;

	//Account Options view
	heightDifference = [self _addCustomView:[accountViewController optionsView]
									 toView:view_accountOptions
					  tabViewItemIdentifier:@"options"];
	if(heightDifference > heightChange) heightChange = heightDifference;

	//Account Privacy view
	heightDifference = [self _addCustomView:[accountViewController privacyView]
									 toView:view_accountPrivacy
					  tabViewItemIdentifier:@"privacy"];
	if(heightDifference > heightChange) heightChange = heightDifference;

	//Add proxy view
	heightDifference = [self _addCustomView:[accountProxyController view]
									 toView:view_accountProxy
					  tabViewItemIdentifier:@"proxy"];
	if(heightDifference > heightChange) heightChange = heightDifference;

	windowFrame.size.height += heightChange;
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
 * @result The positive height difference betwen customView and setupView, indicating how much taller the window needs to be to fit customView.
 */
- (int)_addCustomView:(NSView *)customView toView:(NSView *)setupView tabViewItemIdentifier:(NSString *)identifier
{
	NSSize	customViewFrameSize;
	NSRect	ourViewFrame;
	int		heightDifference;

	if(customView){
		customViewFrameSize = [customView frame].size;
		ourViewFrame = [setupView frame];

		heightDifference = (customViewFrameSize.height - ourViewFrame.size.height);
		if(heightDifference > 0){
			//Modify our frame to make room
			ourViewFrame.size.height += heightDifference;
			ourViewFrame.origin.y -= heightDifference;
			[setupView setFrame:ourViewFrame];
		}

		[customView setFrameSize:ourViewFrame.size];
		[setupView addSubview:customView];
	}else{
		//If no options are available, remove the options tab
		[tabView_auxiliary removeTabViewItem:[tabView_auxiliary tabViewItemWithIdentifier:identifier]];

		heightDifference = 0;
	}

	return(heightDifference > 0 ? heightDifference : 0);
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

/*
 * @brief Localization
 */
- (void)_localizeTabViewItemLabels
{
	[[tabView_auxiliary tabViewItemWithIdentifier:@"account"] setLabel:AILocalizedString(@"Account",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"profile"] setLabel:AILocalizedString(@"Personal",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"options"] setLabel:AILocalizedString(@"Options",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"privacy"] setLabel:AILocalizedString(@"Privcay",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"proxy"] setLabel:AILocalizedString(@"Proxy",nil)];
}

// ESImageViewWithImagePicker Delegate ---------------------------------------------------------------------
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
	NSData	*iconData;
	if(iconData = [[adium preferenceController] preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]){
		NSImage *image = [[NSImage alloc] initWithData:iconData];
		[imageView_userIcon setImage:image];
		[image release];
	}
}

@end
