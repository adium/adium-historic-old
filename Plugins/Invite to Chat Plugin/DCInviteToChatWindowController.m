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

#import "AIContactController.h"
#import "DCInviteToChatWindowController.h"
#import <AIutilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIService.h>

#define INVITE_NIB_NAME		@"InviteToChatWindow"

@interface DCInviteToChatWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
- (void)setChat:(AIChat *)inChat contact:(AIListContact *)inContact;
- (void)setContact:(AIListContact *)inContact;
@end

@implementation DCInviteToChatWindowController

static DCInviteToChatWindowController *sharedInviteToChatInstance = nil;

//Create a new invite to chat window
+ (void)inviteToChatWindowForChat:(AIChat *)inChat contact:(AIListContact *)inContact
{
	
    if(!sharedInviteToChatInstance){
        sharedInviteToChatInstance = [[self alloc] initWithWindowNibName:INVITE_NIB_NAME];
    }

	[sharedInviteToChatInstance setChat:inChat contact:inContact];
    [[sharedInviteToChatInstance window] makeKeyAndOrderFront:nil];
}

+ (void)closeSharedInstance
{
    if(sharedInviteToChatInstance){
        [sharedInviteToChatInstance closeWindow:nil];
    }
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{	
    [super initWithWindowNibName:windowNibName];    
	
	contact = nil;
	service = nil;
	chat = nil;
	
    return(self);
}


//Dealloc
- (void)dealloc
{    
	[contact release]; contact = nil;
	[service release]; service = nil;
	[chat release]; chat = nil;
	[super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    //Configure the contact menu (primarily for handling metacontacts)
	//If the contact is not online, we should include offline so it will be shown; if it is, we don't need 'em
    [menu_contacts setMenu:[[adium contactController] menuOfContainedContacts:contact
																   forService:service
																   withTarget:self
															   includeOffline:![contact online]]];
	
	if( [contact isKindOfClass:[AIMetaContact class]] ) {
		[menu_contacts selectItemWithRepresentedObject:[(AIMetaContact *)contact preferredContactWithService:service]];
	} else {
		[menu_contacts selectItemAtIndex:0];
	}
	
	contact = [[menu_contacts selectedItem] representedObject];
	
	// Set the chat's name in the window
	[textField_chatName setStringValue:[chat name]];

    //Center the window
    [[self window] center];
}

- (IBAction)invite:(id)sender
{	
	// Sanity check: is there really a list object and a chat?
	if( contact && [contact isKindOfClass:[AIListContact class]] && chat ) {
		
		// Sanity check: is it a group chat?
		if( [chat name]) {
			[chat inviteListContact:(AIListContact *)contact withMessage:[textField_message stringValue]];
		} else {
			//NSLog(@"#### Inviting %@ to a one-on-one chat?",contact);
		}
		
	}	
	
	[self closeWindow:nil];
}

//Setting methods
#pragma mark Setting methods
- (IBAction)selectContainedContact:(id)sender
{
	[self setContact:[[menu_contacts selectedItem] representedObject]];
}


- (void)setChat:(AIChat *)inChat contact:(AIListContact *)inContact
{
	[self setContact:inContact];
	
	if (chat != inChat){
		[chat release]; chat = [inChat retain];
		[service release]; service = [[[chat account] service] retain];
	}
}

- (void)setContact:(AIListContact *)inContact
{	
	if (contact != inContact){
		[contact release]; contact = [inContact retain];
	}
}

//Window behavior and closing
#pragma mark Window behavior and closing
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (BOOL)windowShouldClose:(id)sender
{
	sharedInviteToChatInstance = nil;
    [self autorelease]; //Close the shared instance
	
    return(YES);
}

//Close this window
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

@end
