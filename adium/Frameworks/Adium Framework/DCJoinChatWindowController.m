//
//  DCJoinChatWindowController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCJoinChatWindowController.h"

#define JOIN_CHAT_NIB		@"JoinChatWindow"

@interface DCJoinChatWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
@end

@implementation DCJoinChatWindowController

static DCJoinChatWindowController *sharedJoinChatInstance = nil;

//Create a new join chat window
+ (void)joinChatWindow
{
    if(!sharedJoinChatInstance){
        sharedJoinChatInstance = [[self alloc] initWithWindowNibName:JOIN_CHAT_NIB];
    }

    [[sharedJoinChatInstance window] makeKeyAndOrderFront:nil];

}

+ (void)closeSharedInstance
{
    if(sharedJoinChatInstance){
        [sharedJoinChatInstance closeWindow:nil];
    }
}

- (IBAction)joinChat:(id)sender
{
	
	if( controller ) {
		[controller joinChatWithAccount:[[popUp_service selectedItem] representedObject]];
	}
	
	[controller release];
	[DCJoinChatWindowController closeSharedInstance];

}

- (void)configureForAccount:(AIAccount *)inAccount
{
	
	NSView  *currentView;
	NSEnumerator *enumerator = [[view_customView subviews] objectEnumerator];
	NSRect frame, existingViewFrame;
	int diff;
	
	// Remove the previous view controller's view (even if there is no new controller)
	while( currentView = [enumerator nextObject] ) {
		[currentView removeFromSuperview];
		[currentView release];
	}
	
	// Get a view controller for this account if there is one
	controller = [[[inAccount service] joinChatView] retain];
	existingViewFrame = [view_customView frame];

	if( controller ) {
		currentView = [controller view];
		frame = [currentView frame];
		diff = (NSHeight(existingViewFrame) - NSHeight(frame));
		[view_customView addSubview:currentView];
		frame.origin=[view_customView frame].origin;
		[view_customView setFrame:frame];
	} else {
		currentView = nil;
		frame = NSMakeRect(0,0,0,0);
		diff = NSHeight(existingViewFrame);
		[view_customView setFrame:NSMakeRect(0,0,0,0)];
	}
	
	NSRect windowFrame = [[self window] frame];
	windowFrame.size.height -= diff;
	[[self window] setFrame:windowFrame display:YES animate:YES];

	// Get the old frames
	NSRect labelFrame = [textField_accountLabel frame];
	NSRect accountFrame = [popUp_service frame];
	NSRect cancelFrame = [button_cancel frame];
	NSRect joinFrame = [button_joinChat frame];

	// Get sizes for the new view
	//windowFrame.origin.y += diff;
	labelFrame.origin.y -= diff;
	accountFrame.origin.y -= diff;
	cancelFrame.origin.y += diff;
	joinFrame.origin.y += diff;
		
	// Actually do the resizing
	[textField_accountLabel setFrame:labelFrame];
	[popUp_service setFrame:accountFrame];
	[button_cancel setFrame:cancelFrame];
	[button_joinChat setFrame:joinFrame];
	
	[textField_accountLabel setNeedsDisplay:YES];
	[popUp_service setNeedsDisplay:YES];
	[button_joinChat setNeedsDisplay:YES];
	[button_cancel setNeedsDisplay:YES];

	[[self window] display];
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{	
    [super initWithWindowNibName:windowNibName];    
	    		
	controller = nil;

    return(self);
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	
    //Configure the handle type menu
    [popUp_service setMenu:[[adium accountController] menuOfAccountsWithTarget:self]];
	
    //Select the last used account / Available online account
	AIAccount   *preferredAccount = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																						toListObject:nil];
	int			serviceIndex = [popUp_service indexOfItemWithRepresentedObject:preferredAccount];
	
    if(serviceIndex < [popUp_service numberOfItems] && serviceIndex >= 0){
		[popUp_service selectItemAtIndex:serviceIndex];
	}
	
	[self configureForAccount:[[popUp_service selectedItem] representedObject]];
	
    //Center the window
    [[self window] center];
}

- (IBAction)selectAccount:(id)sender
{
	AIAccount			*selectedAccount = [sender representedObject];
	[self configureForAccount:selectedAccount];
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (BOOL)windowShouldClose:(id)sender
{
    [self autorelease]; sharedJoinChatInstance = nil; //Close the shared instance
    return(YES);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
		[DCJoinChatWindowController closeSharedInstance];
    }
}

//Dealloc
- (void)dealloc
{    
     [super dealloc];
}

@end
