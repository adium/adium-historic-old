//
//  AIAccountSetupOverviewView.m
//  Adium
//
//  Created by Adam Iser on 12/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIAccountSetupOverviewView.h"
#import "AIAccountSetupServiceView.h"
#import "AIAccountSetupWindowController.h"
#import "AIViewGridView.h"

@implementation AIAccountSetupOverviewView

//View will load
- (void)viewDidLoad
{
	NSArray			*activeServices;
	NSMutableArray	*inactiveServices; 
	NSEnumerator	*enumerator;
	AIService		*service;
	
	//Get active/inactive service lists
	activeServices = [[adium accountController] activeServicesIncludingCompatibleServices:NO];
	inactiveServices = [[[[adium accountController] availableServices] mutableCopy] autorelease];
	[inactiveServices removeObjectsInArray:activeServices];
	
	//If there are no active services, show the new user info header
	[box_newUserHeader setHidden:([activeServices count] != 0)];
	
	//Build views for active services
	enumerator = [activeServices objectEnumerator];
	while(service = [enumerator nextObject]){
		AIAccountSetupServiceView	*serviceView = [[AIAccountSetupServiceView alloc] initWithService:service delegate:self];
		[serviceView setFrame:NSMakeRect(0, 0, 240, 110)];
		[serviceView setAccounts:[[adium accountController] accountsWithService:service]];
		[serviceView setServiceIconSize:NSMakeSize(48,48)];
		[grid_activeServices addView:serviceView];		
		[serviceView release];
	}
	[grid_activeServices setHidden:([activeServices count] == 0)];
	
	//Service divider
	[box_serviceDivider setHidden:([activeServices count] == 0 || [inactiveServices count] == 0)];
	
	//Build views for inactive services
	enumerator = [inactiveServices objectEnumerator];
	while(service = [enumerator nextObject]){
		AIAccountSetupServiceView	*serviceView = [[AIAccountSetupServiceView alloc] initWithService:service delegate:self];
		[serviceView setFrame:NSMakeRect(0, 0, 164, 34)];
		[serviceView setAccounts:[[adium accountController] accountsWithService:service]];
		//[serviceView setServiceIconSize:NSMakeSize(32,32)];
		[grid_inactiveServices addView:serviceView];
		[serviceView release];
	}
	[grid_inactiveServices setHidden:([inactiveServices count] == 0 || ! [button_inactiveServicesToggle state])];
}

//View will close
- (void)viewWillClose
{
	[grid_activeServices removeAllViews];
	[grid_inactiveServices removeAllViews];
}

//Desired size for this view
//Also positions elements correctly within the view, method name a bit misleading
- (NSSize)desiredSize
{
	NSSize	contentSize = [self frame].size;
	int 	windowHeight = 0;
	
	//New user header
	if(![box_newUserHeader isHidden]){
		windowHeight += [box_newUserHeader frame].size.height;
	}else{
		windowHeight += 16;
	}
	
	//Active services
	if(![grid_activeServices isHidden]){
		[grid_activeServices setFrameOrigin:NSMakePoint([grid_activeServices frame].origin.x, contentSize.height - [grid_activeServices frame].size.height - windowHeight)];
		windowHeight += [grid_activeServices frame].size.height;
	}
	
	//Service divider
	if(![box_serviceDivider isHidden]){
		[box_serviceDivider setFrameOrigin:NSMakePoint([box_serviceDivider frame].origin.x, contentSize.height - [box_serviceDivider frame].size.height - windowHeight)];
		windowHeight += [box_serviceDivider frame].size.height;
	}
	
	//Inactive services
	if(![grid_inactiveServices isHidden]){
		[grid_inactiveServices setFrameOrigin:NSMakePoint([grid_inactiveServices frame].origin.x, contentSize.height - [grid_inactiveServices frame].size.height - windowHeight)];
		windowHeight += [grid_inactiveServices frame].size.height;
		windowHeight += 16;
	}
	
	return(NSMakeSize(550, windowHeight));
}

//Toggle display of inactive services
- (IBAction)toggleInactiveServices:(id)sender
{
	BOOL	visible = [button_inactiveServicesToggle state];
	
	[textField_inactiveServicesToggle setStringValue:(visible ? @"Hide additional services" : @"Show additional services")];
	[grid_inactiveServices setHidden:!visible];
	[controller sizeWindowForContent];
}

//New account
- (void)newAccountOnService:(AIService *)service
{
	[controller newAccountOnService:service];
}

//Edit account
- (void)editExistingAccount:(AIAccount *)account
{
	[controller editExistingAccount:account];
}

@end
