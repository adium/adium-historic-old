//
//  AIAccountSetupEditAccountView.m
//  Adium
//
//  Created by Adam Iser on 12/31/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "AIAccountSetupEditAccountView.h"
#import "AIAccountSetupWindowController.h"

@interface AIAccountSetupEditAccountView (PRIVATE)
- (void)configureViewForAccount:(AIAccount *)inAccount;
- (void)configureViewForService:(AIService *)inService;

- (void)_addCustomViewAndTabsForController:(AIAccountViewController *)inControler;
- (void)_removeCustomViewAndTabs;
- (void)_configureResponderChain:(NSTimer *)inTimer;
@end

@implementation AIAccountSetupEditAccountView

- (void)awakeFromNib
{
	
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[account release];
	account = [inAccount retain];
	
	//Service icon
	[image_serviceIcon setImage:[AIServiceIcons serviceIconForService:[account service]
																 type:AIServiceIconLarge
															direction:AIIconNormal]];
	[textField_accountDescription setStringValue:[account UID]];
	[textField_serviceName setStringValue:[[account service] longDescription]];
	
	//Fields
	[self configureViewForAccount:account];
	
}

- (NSSize)desiredSize
{
	return(NSMakeSize(536,418));
}

- (IBAction)okay:(id)sender
{
	[controller showAccountsOverview];
}












//Configure the account preferences for an account
- (void)configureViewForAccount:(AIAccount *)inAccount
{
	NSData	*iconData;
	
	//If necessary, configure for the account's service first
	if([inAccount service] != configuredForService){
		[self configureViewForService:[inAccount service]];
	}
	
	//Configure for the account
	[configuredForAccount release]; configuredForAccount = [inAccount retain];
	[accountViewController configureForAccount:inAccount];
	
	//Fill in the account's name and auto-connect status
	NSString	*formattedUID = [inAccount preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
	[textField_accountName setStringValue:(formattedUID && [formattedUID length] ? formattedUID : [inAccount UID])];
	
	//User icon
	if(iconData = [inAccount preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]){
		NSImage *image = [[NSImage alloc] initWithData:iconData];
		[imageView_userIcon setImage:image];
		[image release];
	}        
}

//Configure the account preferences for a service.  This determines which controls are loaded and the allowed values
- (void)configureViewForService:(AIService *)inService
{
	//Select the new service
	configuredForService = inService;
	//    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:inService]];
	
	//Insert the custom controls for this service
	[self _removeCustomViewAndTabs];
	[self _addCustomViewAndTabsForController:[inService setupView]];
	
	//Custom username string
	NSString *userNameLabel = [inService userNameLabel];
	[textField_userNameLabel setStringValue:[(userNameLabel ? userNameLabel : @"User Name") stringByAppendingString:@":"]];
	
	//Restrict the account name field to valid characters and length
    [textField_accountName setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[inService allowedCharactersForAccountName]
													  length:[inService allowedLengthForAccountName]
											   caseSensitive:[inService caseSensitive]
												errorMessage:AILocalizedString(@"The characters you're entering are not valid for an account name on this service.",nil)]];
}

//Add the custom views for a controller
- (void)_addCustomViewAndTabsForController:(AIAccountViewController *)inControler
{
	NSView					*accountView;
	NSEnumerator			*enumerator;
	NSTabViewItem			*tabViewItem;
	
	//Get account view
	accountViewController = [inControler retain];
	accountView = [accountViewController setupView];
	
    //Swap in the account details view
    [view_accountDetails addSubview:accountView];
	float accountViewHeight = [accountView frame].size.height;
    [accountView setFrameOrigin:NSMakePoint(0,([view_accountDetails frame].size.height - accountViewHeight))];
	
	//Setup the responder chain
	[self _configureResponderChain:nil];
	
	//Swap in the account auxiliary tabs
    enumerator = [[accountViewController auxiliaryTabs] objectEnumerator];
    while(tabViewItem = [enumerator nextObject]){
        [tabView_auxiliary addTabViewItem:tabViewItem];
    }
	
    //There must be a better way to do this.  When moving tabs over, they will stay selected - resulting in multiple
	//selected tabs.  My quick fix is to manually select each tab in the view.  Not the greatest, but it'll
	//work for now.
    [tabView_auxiliary selectLastTabViewItem:nil];
    int i;
    for(i = 1;i < [tabView_auxiliary numberOfTabViewItems];i++){
        [tabView_auxiliary selectPreviousTabViewItem:nil];
    }
}

//Hook up the responder chain
//Must wait until our view is visible to do this, otherwise our requests to set the chain up will be ignored.
//So, this method waits until our view becomes visible, and then sets up the chain :)
- (void)_configureResponderChain:(NSTimer *)inTimer
{
//	[responderChainTimer invalidate];
//	[responderChainTimer release];
//	responderChainTimer = nil;
	
//#warning hack	if([view canDraw]){
//	NSView	*accountView = [accountViewController view];
//	
//	//Name field goes to first control in account view
//	[textField_accountName setNextKeyView:[accountView nextValidKeyView]];
//	
//	//Last control in account view goes to account list
//	NSView	*nextView = [accountView nextKeyView];
//	while([nextView nextKeyView]) nextView = [nextView nextKeyView];
//	[nextView setNextKeyView:tableView_accountList];
	
	//Account list goes to service menu
	//		[tableView_accountList setNextKeyView:popupMenu_serviceList];
	/*	}else{
		responderChainTimer = [[NSTimer scheduledTimerWithTimeInterval:0.001
																target:self
															  selector:@selector(_configureResponderChain:)
															  userInfo:nil
															   repeats:NO] retain]; 
	}*/
}

//Remove any existing custom views
- (void)_removeCustomViewAndTabs
{
	int selectedTabIndex;
	
    //Remove any tabs
    if([tabView_auxiliary selectedTabViewItem]){
        selectedTabIndex = [tabView_auxiliary indexOfTabViewItem:[tabView_auxiliary selectedTabViewItem]];
    }
    while([tabView_auxiliary numberOfTabViewItems] > 1){
        [tabView_auxiliary removeTabViewItem:[tabView_auxiliary tabViewItemAtIndex:[tabView_auxiliary numberOfTabViewItems] - 1]];
    }
    
    //Close any currently open controllers
    [view_accountDetails removeAllSubviews];
    [accountViewController release]; accountViewController = nil;
}

@end
