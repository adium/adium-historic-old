//
//  DCInviteToChatWindowController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCInviteToChatWindowController.h"

#define INVITE_NIB_NAME		@"InviteToChatWindow"

@interface DCInviteToChatWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
- (void)setChat:(AIChat *)inChat contact:(AIListObject *)inContact service:(NSString *)inService;
@end

@implementation DCInviteToChatWindowController

static DCInviteToChatWindowController *sharedInviteToChatInstance = nil;

//Create a new invite to chat window
+ (void)inviteToChatWindowForChat:(AIChat *)inChat contact:(AIListObject *)inContact service:(NSString *)inService
{
	
    if(!sharedInviteToChatInstance){
        sharedInviteToChatInstance = [[self alloc] initWithWindowNibName:INVITE_NIB_NAME];
    }

	[sharedInviteToChatInstance setChat:inChat contact:inContact service:inService];
    [[sharedInviteToChatInstance window] makeKeyAndOrderFront:nil];

}

+ (void)closeSharedInstance
{
    if(sharedInviteToChatInstance){
        [sharedInviteToChatInstance cancel:nil];
    }
}

- (IBAction)invite:(id)sender
{
	
	// Sanity check: is there really a list object and a chat?
	if( contact && chat ) {
		
		// Sanity check: is it a group chat?
		if( [[chat participatingListObjects] count] > 1 ) {
			BOOL res = [chat inviteListContact:contact withMessage:[textField_message stringValue]];
			NSLog(@"#### Invited %@, result was %d",contact,res);
		} else {
			NSLog(@"#### Inviting %@ to a one-on-one chat?",contact);
		}
		
	}	
	
	[DCInviteToChatWindowController closeSharedInstance];

}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{	
    [super initWithWindowNibName:windowNibName];    
	
    return(self);
}

- (void)setChat:(AIChat *)inChat contact:(AIListObject *)inContact service:(NSString *)inService
{
	contact = inContact;
	service = inService;
	chat = inChat;
	[textField_chatName setStringValue:[chat name]];

}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    //Configure the handle type menu
    [menu_contacts setMenu:[[adium contactController] menuOfContainedContacts:contact forService:service withTarget:self includeOffline:NO]];
	
	if( [contact isKindOfClass:[AIMetaContact class]] ) {
		[menu_contacts selectItemWithRepresentedObject:[(AIMetaContact *)contact preferredContactWithServiceID:service]];
	} else {
		[menu_contacts selectItemAtIndex:0];
	}
	
	contact = [[menu_contacts selectedItem] representedObject];

    //Center the window
    [[self window] center];
}

- (IBAction)selectContainedContact:(id)sender
{
	contact = [[menu_contacts selectedItem] representedObject];
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (BOOL)windowShouldClose:(id)sender
{
    [self autorelease]; sharedInviteToChatInstance = nil; //Close the shared instance
    return(YES);
}

//Close this window
- (IBAction)cancel:(id)sender
{
    if([self windowShouldClose:nil]){
		[DCInviteToChatWindowController closeSharedInstance];
    }
}

//Dealloc
- (void)dealloc
{    
     [super dealloc];
}

@end
