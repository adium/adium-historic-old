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

#import "AIAccount.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentMessage.h"
#import "AILocalizationButton.h"
#import "AIService.h"
#import "DCJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

#define JOIN_CHAT_NIB		@"JoinChatWindow"

@interface DCJoinChatWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
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
	[label_account setLocalizedString:AILocalizedString(@"Account:",nil)];

	[button_joinChat setLocalizedString:AILocalizedString(@"Join",nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];

    //Center the window
    [[self window] center];
	
	[super windowDidLoad];
}

- (IBAction)selectAccount:(id)sender
{
	AIAccount			*selectedAccount = [sender representedObject];
	[self configureForAccount:selectedAccount];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	sharedJoinChatInstance = nil;
    [self autorelease]; //Close the shared instance
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
