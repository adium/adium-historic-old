/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AINewMessagePrompt.h"

#define NEW_MESSAGE_PROMPT_NIB	@"NewMessagePrompt"

@interface AINewMessagePrompt (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
@end


@implementation AINewMessagePrompt

static AINewMessagePrompt *sharedInstance = nil;
+ (void)newMessagePrompt
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:NEW_MESSAGE_PROMPT_NIB];
    }
    [[sharedInstance window] makeKeyAndOrderFront:nil];
}

+ (void)closeSharedInstance
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//New Message
- (IBAction)newMessage:(id)sender
{
    AIListContact	*contact;
    AIAccount		*account;
    NSString		*UID;
    AIServiceType	*serviceType;

    //Get the service type and UID
    account = [[popUp_service selectedItem] representedObject];
    serviceType = [[account service] handleServiceType];
    UID = [serviceType filterUID:[textField_handle stringValue]];
        
    //Find the contact
	contact = [[adium contactController] contactWithService:[serviceType identifier] UID:UID];
    if(contact){
        AIChat	*chat;
        
        //Close the prompt
        [AINewMessagePrompt closeSharedInstance];

        //Initiate the message
        chat = [[adium contentController] openChatOnAccount:account withListObject:contact];
        [[adium interfaceController] setActiveChat:chat];
    }
}

- (IBAction)selectAccount:(id)sender
{

}


// Private --------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    //init
    [super initWithWindowNibName:windowNibName];    

    return(self);
}

- (void)dealloc
{
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSEnumerator		*enumerator;
    AIListContact		*contact;
    AIAccount			*account;
    
    //Configure the auto-complete view
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
    while((contact = [enumerator nextObject])){
        [textField_handle addCompletionString:[contact UID]];
    }

    //Configure the handle type menu
    [popUp_service removeAllItems];
    [[popUp_service menu] setAutoenablesItems:NO];

    //Insert a menu item for each available account
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        NSMenuItem	*menuItem;
        
        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:[account displayName] target:self action:@selector(selectAccount:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];

        //Disabled the menu item if the account is offline
        if(![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account]){
            [menuItem setEnabled:NO];
        }else{
            [menuItem setEnabled:YES];
        }

        //add the menu item
        [[popUp_service menu] addItem:menuItem];
    }

    //Select the last used account / Available online account
	int index = [popUp_service indexOfItemWithRepresentedObject:[[adium accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil]];
    if(index < [popUp_service numberOfItems] && index >= 0){
		[popUp_service selectItemAtIndex:index];
	}

    //Center the window
    [[self window] center];
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (BOOL)windowShouldClose:(id)sender
{
    [self autorelease]; sharedInstance = nil; //Close the shared instance
    return(YES);
}

@end
