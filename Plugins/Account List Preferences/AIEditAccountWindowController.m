/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIEditAccountWindowController.h"
#import "AIAccountProxySettings.h"

@interface AIEditAccountWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName account:(AIAccount *)inAccount deleteIfCanceled:(BOOL)inDeleteIfCanceled;
- (void)_addCustomViewAndTabsForAccount:(AIAccount *)inAccount;
- (int)_addCustomView:(NSView *)customView toView:(NSView *)setupView tabViewItemIdentifier:(NSString *)identifier;
- (void)_configureResponderChain:(NSTimer *)inTimer;
- (void)_removeCustomViewAndTabs;

- (void)saveConfiguration;
@end

@implementation AIEditAccountWindowController

+ (void)editAccount:(AIAccount *)inAccount onWindow:(id)parentWindow deleteIfCanceled:(BOOL)inDeleteIfCanceled
{
	AIEditAccountWindowController	*controller;
	
	controller = [[self alloc] initWithWindowNibName:@"EditAccountSheet" 
											 account:inAccount
									deleteIfCanceled:inDeleteIfCanceled];

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

//init the window controller
- (id)initWithWindowNibName:(NSString *)windowNibName account:(AIAccount *)inAccount deleteIfCanceled:(BOOL)inDeleteIfCanceled
{
    [super initWithWindowNibName:windowNibName];

	account = [inAccount retain];
	deleteIfCanceled = inDeleteIfCanceled;

	return(self);
}

//Dealloc
- (void)dealloc
{
	[account release];
	[super dealloc];
}
	
//Setup the window before it is displayed
- (void)windowDidLoad
{
	NSData	*iconData;

	//Center our window if we're not a sheet (or opening a sheet failed)
	[[self window] center];
	
	//Account Overview
	[image_serviceIcon setImage:[AIServiceIcons serviceIconForService:[account service]
																 type:AIServiceIconLarge
															direction:AIIconNormal]];	
	[textField_serviceName setStringValue:[[account service] longDescription]];
	[textField_accountDescription setStringValue:[account UID]];
	
	//User icon
	if(iconData = [account preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]){
		NSImage *image = [[NSImage alloc] initWithData:iconData];
		[imageView_userIcon setImage:image];
		[image release];
	}        
	

	//Insert the custom controls for this account
	[self _removeCustomViewAndTabs];
	[self _addCustomViewAndTabsForAccount:account];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
	[self autorelease];
    return(YES);
}

//Stop automatic window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
	if([self windowShouldClose:nil]){
		if([[self window] isSheet]){
			[NSApp endSheet:[self window]];
		}else{
			[[self window] close];
		}
	}
}

//Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Cancel.  Close without saving changes
- (IBAction)cancel:(id)sender
{
	/* deleteIfCanceled should only be YES if we were called to edit a newly created account. Canceling the process should
	 * delete the account which we were passed. */
	if(deleteIfCanceled){
		[[adium accountController] deleteAccount:account save:YES];
	}

	[self closeWindow:nil];
}

//Okay.  Save changes and close
- (IBAction)okay:(id)sender
{
	[self saveConfiguration];
	[accountViewController saveConfiguration];
	[accountProxyController saveConfiguration];
	[self closeWindow:nil];
}

- (void)saveConfiguration
{
	//User icon
	[account setPreference:[[imageView_userIcon image] PNGRepresentation]
					forKey:KEY_USER_ICON 
					 group:GROUP_ACCOUNT_STATUS];
}

//Add the custom views for a controller
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

//Add customView to setupView and return the height difference between the two if customView is taller than setupView
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

//Remove any existing custom views
- (void)_removeCustomViewAndTabs
{
    //Close any currently open controllers
    [view_accountSetup removeAllSubviews];
    [accountViewController release]; accountViewController = nil;
}


@end
