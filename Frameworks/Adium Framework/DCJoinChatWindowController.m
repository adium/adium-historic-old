//
//  DCJoinChatWindowController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
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
	// If there is a controller, it handles all of the join-chat work
	if( controller ) {
		[controller joinChatWithAccount:[[popUp_service selectedItem] representedObject]];
	}
	
	[self closeWindow:nil];
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	NSRect 	windowFrame = [[self window] frame];
	int		diff;
	
	//Remove the previous view controller's view
	[currentView removeFromSuperview];
	[currentView release]; currentView = nil;
	
	//Get a view controller for this account if there is one
	controller = [[[inAccount service] joinChatView] retain];
	currentView = [controller view];
	[controller setDelegate:self];

	//Resize the window to fit the new view
	diff = [view_customView frame].size.height - [currentView frame].size.height;
	windowFrame.size.height -= diff;
	windowFrame.origin.y += diff;
	[[self window] setFrame:windowFrame display:YES animate:YES];

	if(controller && currentView){
		[view_customView addSubview:currentView];
		[controller configureForAccount:inAccount];
	}
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{	
    [super initWithWindowNibName:windowNibName];    
	    		
	if( controller )
		[controller release];
	
	controller = nil;

    return(self);
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	unsigned numberOfServiceMenuItems = [popUp_service numberOfItems];
	
    //Configure the handle type menu
    [popUp_service setMenu:[[adium accountController] menuOfAccountsWithTarget:self
																includeOffline:NO 
											onlyIfCreatingGroupChatIsSupported:YES]];
	if (numberOfServiceMenuItems > 0){
		//Select the last used account / Available online account
		AIAccount   *preferredAccount = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																							   toContact:nil];
		int			serviceIndex = [popUp_service indexOfItemWithRepresentedObject:preferredAccount];
		
		if(serviceIndex < numberOfServiceMenuItems && serviceIndex >= 0){
			[popUp_service selectItemAtIndex:serviceIndex];
		}
		
		AIAccount *account = [[popUp_service selectedItem] representedObject];
		[self configureForAccount:account];
	}

	[[self window] setTitle:AILocalizedString(@"Join Chat",nil)];
	[textField_accountLabel setStringValue:AILocalizedString(@"Account:",nil)];

	[button_joinChat setTitle:AILocalizedString(@"Join",nil)];
	[button_cancel setTitle:AILocalizedString(@"Cancel",nil)];

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
	sharedJoinChatInstance = nil;
    [self autorelease]; //Close the shared instance
	
    return(YES);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
		 [[self window] close];
    }
}

//Dealloc
- (void)dealloc
{    
     [super dealloc];
}

#pragma mark DCJoinChatViewController delegate
- (void)setJoinChatEnabled:(BOOL)enabled
{
	[button_joinChat setEnabled:enabled];
}

- (AIListContact *)contactFromText:(NSString *)text
{
	AIListContact	*contact;
	AIAccount		*account;
	NSString		*UID;
	
	//Get the service type and UID
	account = [[popUp_service selectedItem] representedObject];
	UID = [[account service] filterUID:text removeIgnoredCharacters:YES];
	
	//Find the contact
	contact = [[adium contactController] contactWithService:[account service]
													account:account 
														UID:UID];
	
	return(contact);
}

@end
