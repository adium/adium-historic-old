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
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

#define NEW_MESSAGE_PROMPT_NIB	@"NewMessagePrompt"

@interface AINewMessagePrompt (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)windowDidLoad;
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
@end


@implementation AINewMessagePrompt

static AINewMessagePrompt *sharedInstance = nil;
+ (void)newMessagePromptWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:NEW_MESSAGE_PROMPT_NIB owner:inOwner];
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

//New Mesasge
- (IBAction)newMessage:(id)sender
{
    AIListContact	*contact;
    AIServiceType	*serviceType;
    NSString		*UID;

    //Get the service type and UID
    serviceType = [[popUp_service selectedItem] representedObject];
    UID = [serviceType filterUID:[textField_handle stringValue]];
        
    //Find the contact
    contact = [[owner contactController] contactInGroup:nil withService:[serviceType identifier] UID:UID];

    //If one does not exist, we need to create it as a temporary handle
    if(!contact){
        AIAccount	*account;
        AIHandle	*handle;
        
        //Find the first available account, and create a temporary handle on it for the new contact
        account = [[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toContact:nil];
        handle = [(AIAccount<AIAccount_Handles> *)account addHandleWithUID:UID serverGroup:nil temporary:YES];
        contact = [handle containingContact];
    }

    if(contact){
        //Close the prompt
        [AINewMessagePrompt closeSharedInstance];

        //Initiate the message
        [[owner notificationCenter] postNotificationName:Interface_InitiateMessage
                                                  object:nil
                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:contact, @"To", nil]];
    }
}

- (IBAction)selectService:(id)sender
{

}



// Private --------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    //init
    [super initWithWindowNibName:windowNibName owner:self];
    owner = [inOwner retain];
    

    return(self);
}

- (void)dealloc
{
    [owner release];
    
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSEnumerator		*enumerator;
    AIListContact		*contact;
    id <AIServiceController>	service;
    NSMenu			*menu = [popUp_service menu];
    
    //Configure the auto-complete view
    enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
    while((contact = [enumerator nextObject])){
        [textField_handle addCompletionString:[contact UID]];
    }

    //Configure the handle type menu
    [popUp_service removeAllItems];

    //Insert a menu item for each available service type
    enumerator = [[[owner accountController] availableServiceArray] objectEnumerator];
    while((service = [enumerator nextObject])){
        AIServiceType	*serviceType = [service handleServiceType];
        NSMenuItem	*menuItem;
        BOOL		menuExists = NO;
        int		i;
        
        //Make sure a menu item for this type doesn't already exist in our menu
        for(i = 0;i < [menu numberOfItems]; i++){
            if([[serviceType identifier] compare:[[[menu itemAtIndex:i] representedObject] identifier]] == 0){
                menuExists = YES;
            }
        }
        
        //Add the menu item
        if(!menuExists){
            menuItem = [[NSMenuItem alloc] initWithTitle:[serviceType description] target:self action:@selector(selectService:) keyEquivalent:@""];
            [menuItem setRepresentedObject:serviceType];

            [[popUp_service menu] addItem:menuItem];
        }
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
