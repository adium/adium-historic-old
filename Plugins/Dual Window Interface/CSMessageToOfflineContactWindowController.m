//
//  CSMessageToOfflineContactWindowController.m
//  Adium
//
//  Created by Chris Serino on Sat Apr 24 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CSMessageToOfflineContactWindowController.h"
#import "AIMessageViewController.h"

#define OFFLINE_CONTACT_MESSAGE_NIB @"OfflineContactMessage"

@interface CSMessageToOfflineContactWindowController (PRIVATE)

- (id)initWithWindowNibName:(NSString *)windowNibName messageViewController:(AIMessageViewController *)inMessageViewController;

@end

@implementation CSMessageToOfflineContactWindowController

#pragma mark Initialization
+ (void)showSheetInWindow:(NSWindow *)inWindow forMessageViewController:(AIMessageViewController *)inMessageViewController;
{
	CSMessageToOfflineContactWindowController	*windowController = [[self alloc] initWithWindowNibName:OFFLINE_CONTACT_MESSAGE_NIB messageViewController:inMessageViewController];
	
	[NSApp beginSheet:[windowController window]
	   modalForWindow:inWindow
		modalDelegate:windowController
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName messageViewController:(AIMessageViewController *)inMessageViewController
{
	[super initWithWindowNibName:windowNibName];
	
	messageViewController = [inMessageViewController retain];
	return(self);
}

- (void)dealloc
{
	[messageViewController release];
	[super dealloc];
}

#pragma mark Window Handling

//Setup the window before it is displayed
- (void)windowDidLoad
{
	//Configure window
	[[self window] center];
}

//Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
	if([[self window] isSheet]) [NSApp endSheet:[self window]];
	[[self window] close];
}

#pragma mark Actions
//Adds an alert that makes the message get sent when the contact comes online again.
- (IBAction)sendLater:(id)sender
{
	[messageViewController sendMessageLater:nil];
	[self closeWindow:nil];
}

- (IBAction)dontSend:(id)sender
{
	[self closeWindow:nil];
}

- (IBAction)sendNow:(id)sender
{
	[messageViewController setShouldSendMessagesToOfflineContacts:YES]; //don't ask again
	[messageViewController sendMessage:nil];
	
	[self closeWindow:nil];
}

@end
