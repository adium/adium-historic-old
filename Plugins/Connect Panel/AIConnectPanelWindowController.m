//
//  AIConnectPanelWindowController.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIConnectPanelWindowController.h"

#define CONNET_PANEL_NIB		@"ConnectPanel"
#define	KEY_CONNECT_PANEL_FRAME	@"Connect Panel Frame"

@implementation AIConnectPanelWindowController

//Return a new connection window
AIConnectPanelWindowController	*sharedConnectPanelInstance = nil;
+ (AIConnectPanelWindowController *)connectPanelWindowController
{
    if(!sharedConnectPanelInstance){
        sharedConnectPanelInstance = [[self alloc] initWithWindowNibName:CONNET_PANEL_NIB];
    }
    return(sharedConnectPanelInstance);
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];
	
    return(self);
}

//Window did load
- (void)windowDidLoad
{
    NSString	*savedFrame;
	
    //Restore the window position
	savedFrame = [[adium preferenceController] preferenceForKey:KEY_CONNECT_PANEL_FRAME group:PREF_GROUP_WINDOW_POSITIONS];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }
	
	//Service popup
	[popupMenu_serviceList setMenu:[[adium accountController] menuOfServicesWithTarget:self]];

	//Observe account list objects so we can enable/disable our controls for connected accounts
    [[adium contactController] registerListObjectObserver:self];
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_CONNECT_PANEL_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
    return(YES);
}

//dealloc
- (void)dealloc
{	
    [super dealloc];
}

//Prevent the system from tiling this window
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//
- (IBAction)connect:(id)sender
{
	NSLog(@"Connect");
}

//
- (IBAction)selectServiceType:(id)sender
{
	NSLog(@"WOOT!");
}

//
- (IBAction)showAccounts:(id)sender
{
	[[adium preferenceController] openPreferencesToCategory:AIPref_Accounts];
}



//Account status changed.
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
//    if(inObject == configuredForAccount && [inModifiedKeys containsObject:@"Online"]){
//		[self enableDisableControls];
//    }
//    
    return(nil);
}

//We need to make sure all changes to the account have been saved before a service switch occurs.
//This code is called when the service menu is opened, and takes focus away from the first responder,
//causing it to save any outstanding changes.
//- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
//{
//	[[popupMenu_serviceList window] makeFirstResponder:popupMenu_serviceList];
//	return(YES);
//}
//



//User changed the service of our account
//- (IBAction)selectServiceType:(id)sender
//{
//	id <AIServiceController>	service = [sender representedObject];
//	[[adium accountController] switchAccount:configuredForAccount toService:service];
//}
//
//- (IBAction)changeUIDField:(id)sender
//{
//	NSString *newUID = [textField_accountName stringValue];
//	if (![[configuredForAccount UID] isEqualToString:newUID])
//		[[adium accountController] changeUIDOfAccount:configuredForAccount to:newUID];	
//}



//Configure the account preferences for an account
//- (void)configureViewForAccount:(AIAccount *)inAccount
//{
//	//If necessary, configure for the account's service first
//	if([inAccount service] != configuredForService){
//		[self configureViewForService:[inAccount service]];
//	}
//	
//	//Configure for the account
//	configuredForAccount = inAccount;
//	[accountViewController configureForAccount:inAccount];
//	[self enableDisableControls];
//	
//	//Fill in the account's name and auto-connect status
//	NSString	*formattedUID = [inAccount preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
//	[textField_accountName setStringValue:(formattedUID && [formattedUID length] ? formattedUID : [inAccount UID])];
//    [button_autoConnect setState:[[inAccount preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]];
//}
//
////Configure the account preferences for a service.  This determines which controls are loaded and the allowed values
//- (void)configureViewForService:(id <AIServiceController>)inService
//{
//	AIServiceType	*serviceType = [inService handleServiceType];
//	
//	//Select the new service
//	configuredForService = inService;
//    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:inService]];
//	
//	//Insert the custom controls for this service
//	[self _removeCustomViewAndTabs];
//	[self _addCustomViewAndTabsForController:[inService accountView]];
//	
//	//Restrict the account name field to valid characters and length
//    [textField_accountName setFormatter:
//		[AIStringFormatter stringFormatterAllowingCharacters:[serviceType allowedCharacters]
//													  length:[serviceType allowedLength]
//											   caseSensitive:[serviceType caseSensitive]
//												errorMessage:@"The characters you're entering are not valid for an account name on this service."]];
//}
//
////Add the custom views for a controller
//- (void)_addCustomViewAndTabsForController:(AIAccountViewController *)inControler
//{
//	NSView					*accountView;
//	NSEnumerator			*enumerator;
//	NSTabViewItem			*tabViewItem;
//	
//	//Get account view
//	accountViewController = [inControler retain];
//	accountView = [accountViewController view];
//	
//    //Swap in the account details view
//    [view_accountDetails addSubview:accountView];
//	float accountViewHeight = [accountView frame].size.height;
//    [accountView setFrameOrigin:NSMakePoint(0,([view_accountDetails frame].size.height - accountViewHeight))];
//	
//	//Setup the responder chain
//	[self _configureResponderChain:nil];
//	
//	//Swap in the account auxiliary tabs
//    enumerator = [[accountViewController auxiliaryTabs] objectEnumerator];
//    while(tabViewItem = [enumerator nextObject]){
//        [tabView_auxiliary addTabViewItem:tabViewItem];
//    }
//	
//    //There must be a better way to do this.  When moving tabs over, they will stay selected - resulting in multiple
//	//selected tabs.  My quick fix is to manually select each tab in the view.  Not the greatest, but it'll
//	//work for now.
//    [tabView_auxiliary selectLastTabViewItem:nil];
//    int i;
//    for(i = 1;i < [tabView_auxiliary numberOfTabViewItems];i++){
//        [tabView_auxiliary selectPreviousTabViewItem:nil];
//    }
//}
//
////Hook up the responder chain
////Must wait until our view is visible to do this, otherwise our requests to setup the chain will be ignored.
////So, this method waits until our view becomes visible, and then sets up the chain :)
//- (void)_configureResponderChain:(NSTimer *)inTimer
//{
//	[responderChainTimer invalidate];
//	[responderChainTimer release];
//	responderChainTimer = nil;
//	
//	NSLog(@"%@  canDraw:%i  window:%@", view, [view canDraw], [view window]);
//	if([view canDraw]){
//		NSView	*accountView = [accountViewController view];
//		
//		//Name field goes to first control in account view
//		[textField_accountName setNextKeyView:[accountView nextValidKeyView]];
//		
//		//Last control in account view goes to account list
//		NSView	*nextView = [accountView nextKeyView];
//		while([nextView nextKeyView]) nextView = [nextView nextKeyView];
//		[nextView setNextKeyView:tableView_accountList];
//		
//		//Account list goes to service menu
//		[tableView_accountList setNextKeyView:popupMenu_serviceList];
//	}else{
//		responderChainTimer = [[NSTimer scheduledTimerWithTimeInterval:0.001
//																target:self
//															  selector:@selector(_configureResponderChain:)
//															  userInfo:nil
//															   repeats:NO] retain]; 
//	}
//}
//
//






@end
