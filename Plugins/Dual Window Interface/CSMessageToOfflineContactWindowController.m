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

#import "AIMessageViewController.h"
#import "CSMessageToOfflineContactWindowController.h"

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
