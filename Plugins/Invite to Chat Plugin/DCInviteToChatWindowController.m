//
//  DCInviteToChatWindowController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCInviteToChatWindowController.h"

#define INVITE_NIB_NAME		@"InviteToChatWindow"

@interface DCInviteToChatWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
- (void)setChat:(AIChat *)inChat contact:(AIListContact *)inContact service:(NSString *)inService;
@end

@implementation DCInviteToChatWindowController

static DCInviteToChatWindowController *sharedInviteToChatInstance = nil;

//Create a new invite to chat window
+ (void)inviteToChatWindowForChat:(AIChat *)inChat contact:(AIListContact *)inContact service:(NSString *)inService
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
	if( contact && [contact isKindOfClass:[AIListContact class]] && chat ) {
		
		// Sanity check: is it a group chat?
		if( [chat name]) {
			BOOL res = [chat inviteListContact:(AIListContact *)contact withMessage:[textField_message stringValue]];
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

- (void)setChat:(AIChat *)inChat contact:(AIListContact *)inContact service:(NSString *)inService
{
	contact = inContact;
	service = inService;
	chat = inChat;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    //Configure the handle type menu
    [menu_contacts setMenu:[[adium contactController] menuOfContainedContacts:contact
																   forService:service
																   withTarget:self
															   includeOffline:NO]];
	
	if( [contact isKindOfClass:[AIMetaContact class]] ) {
#warning Dave: This fails to select anyone for some reason
		[menu_contacts selectItemWithRepresentedObject:[(AIMetaContact *)contact preferredContactWithServiceID:service]];
	} else {
		[menu_contacts selectItemAtIndex:0];
	}
	
	contact = [[menu_contacts selectedItem] representedObject];
	
	// Set the chat's name in the window
	[textField_chatName setStringValue:[chat name]];

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
