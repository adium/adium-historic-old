/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIDualWindowInterface.h"
#import "AIAdium.h"
#import "AIContactListWindowController.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"

#define CONTACT_LIST_WINDOW_MENU_TITLE		@"Contact List"		//Title for the contact list menu item
#define MESSAGES_WINDOW_MENU_TITLE		@"Messages"		//Title for the messages window menu item
#define CLOSE_TAB_MENU_TITLE			@"Close Tab"		//Title for the close tab menu item
#define PREVIOUS_MESSAGE_MENU_TITLE		@"Previous Message"
#define NEXT_MESSAGE_MENU_TITLE			@"Next Message"

@interface AIDualWindowInterface (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)dealloc;
- (void)buildWindowMenu;
- (AIMessageViewController *)messageViewControllerWithHandle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent;
- (void)loadMessageWindow;
- (void)unloadMessageWindow;
@end

@implementation AIDualWindowInterface

+ (id)newInstanceOfInterfaceWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Show the contact list window
- (IBAction)showContactList:(id)sender
{
    if(!contactListWindowController){
        contactListWindowController = [[AIContactListWindowController contactListWindowControllerWithOwner:owner] retain];
    }
    [contactListWindowController showWindow:nil];
}

//Show the message window (if any messages are open)
- (IBAction)showMessageWindow:(id)sender
{
    if(messageWindow){ //Show the message window only if it already exists (otherwise it would be empty)
        [messageWindow showWindow:nil];
    
        //Select the tab if called in response to a menu selectiob
        if([sender isKindOfClass:[NSMenuItem class]]){
            id	controller = [(NSMenuItem *)sender representedObject];
            
            if([controller conformsToProtocol:@protocol(AIMessageView)]){
                [messageWindow selectMessageViewController:(id<AIMessageView>)controller];
            }
        }
    }
}

//Close a message view controller
- (void)closeMessageViewController:(id <AIMessageView>)controller
{
    if(messageWindow){
        //Remove the message from the message window
        [messageWindow removeMessageViewController:controller];
    }
}

//Notifications ------------------------------------------------------------------------------------------------
//Called when a message object is added to a handle
- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContactHandle 	*handle = [notification object];
    NSDictionary	*userInfo = [notification userInfo];
    
    if([[userInfo objectForKey:@"Incoming"] boolValue] == YES){
        id <AIContentObject>	object = [userInfo objectForKey:@"Object"];
        AIMessageViewController	*controller;
    
        //Ensure a message window/view is open for this contact
        controller = [self messageViewControllerWithHandle:handle account:[object destination] content:nil];

        //new message?
        //[messageWindow selectMessageViewController:controller];
    }
}

//Called when the user requests to initiate a message
- (void)initiateMessage:(NSNotification *)notification
{
    AIMessageViewController		*controller;
    NSDictionary			*userInfo;
    AIContactHandle			*to;
    AIAccount				*from;
    NSAttributedString			*content;

    //Get the information from the notification
    userInfo = [notification userInfo];
    to = [userInfo objectForKey:@"To"];
    from = [userInfo objectForKey:@"From"];
    content = [userInfo objectForKey:@"Content"];

    //Create the message window
    controller = [self messageViewControllerWithHandle:to account:from content:content];
    [messageWindow selectMessageViewController:controller];
    [controller setAccountMenuVisible:YES]; //show/reshow the account selector
    [messageWindow showWindow:nil];
}

//Called when the user requests to close a message
- (void)closeMessage:(NSNotification *)notification
{
    if(messageWindow){
        AIMessageViewController	*controller;
        AIContactHandle		*handle;
        NSEnumerator		*enumerator;

        //Get the information from the notification
        handle = [notification object];
    
        //Find the message controller for this handle
        enumerator = [[messageWindow messageViewArray] objectEnumerator];
        while((controller = [enumerator nextObject])){
            if([controller handle] == handle){
                //Close it
                [self closeMessageViewController:controller];
                break;
            }
        }
    }
}

- (IBAction)closeTab:(id)sender
{
    if(messageWindow){
        [self closeMessageViewController:[messageWindow selectedMessageView]];
    }
}

- (void)messageWindowControllersChanged:(NSNotification *)notification
{
    //Close (and release) the message window if it's empty
    if([messageWindow count] == 0){
        [self unloadMessageWindow];
    }

    //Rebuild the window menu
    [self buildWindowMenu]; 

}

- (void)messageWindowControllerOrderChanged:(NSNotification *)notification
{
    [self buildWindowMenu]; //Rebuild the window menu
    
}

- (void)messageWindowSelectedControllerChanged:(NSNotification *)notification
{

}

//Select the next message
- (IBAction)nextMessage:(id)sender
{    
    if(messageWindow && [[messageWindow window] isKeyWindow]){
        if(![messageWindow selectNextController]){
            //Move: message window -> contact list
            [contactListWindowController showWindow:nil];
        }
    }else{
        //Move:  contact list -> message window
        [messageWindow selectFirstController];
        [messageWindow showWindow:nil];
    }
}

- (IBAction)previousMessage:(id)sender
{
    if(messageWindow && [[messageWindow window] isKeyWindow]){
        if(![messageWindow selectPreviousController]){
            //Move:  contact list <- message window
            [contactListWindowController showWindow:nil];
        }
    }else{
        //Move:  message window <- contact list
        [messageWindow selectLastController];
        [messageWindow showWindow:nil];
    }
}



//Private ------------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    NSMenuItem	*menuItem;

    [super init];

    //init
    owner = [inOwner retain];
    messageWindow = nil;
    windowMenuArray = [[NSMutableArray alloc] init];

    //Open the contact list window
    [self showContactList:nil];

    //Register for the necessary notifications
    [[[owner contentController] contentNotificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:nil];
    [[[owner interfaceController] interfaceNotificationCenter] addObserver:self selector:@selector(initiateMessage:) name:Interface_InitiateMessage object:nil];
    [[[owner interfaceController] interfaceNotificationCenter] addObserver:self selector:@selector(closeMessage:) name:Interface_CloseMessage object:nil];

    //Add our windows to the window menu
    menuItem = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE target:self action:@selector(showContactList:) keyEquivalent:@"1"];
    [[owner menuController] addMenuItem:[menuItem autorelease] toLocation:LOC_Window_Fixed];

    menuItem_closeTab = [[NSMenuItem alloc] initWithTitle:CLOSE_TAB_MENU_TITLE target:self action:@selector(closeTab:) keyEquivalent:@"r"];
    [[owner menuController] addMenuItem:menuItem_closeTab toLocation:LOC_File_Close];

    //Add our other menu items
    menuItem_previousMessage = [[NSMenuItem alloc] initWithTitle:PREVIOUS_MESSAGE_MENU_TITLE target:self action:@selector(previousMessage:) keyEquivalent:@"["];
    [[owner menuController] addMenuItem:menuItem_previousMessage toLocation:LOC_Window_Commands];

    menuItem_nextMessage = [[NSMenuItem alloc] initWithTitle:NEXT_MESSAGE_MENU_TITLE target:self action:@selector(nextMessage:) keyEquivalent:@"]"];
    [[owner menuController] addMenuItem:menuItem_nextMessage toLocation:LOC_Window_Commands];


    return(self);
}

//dealloc
- (void)dealloc
{
    [self unloadMessageWindow];

    [[[owner contentController] contentNotificationCenter] removeObserver:self];
    [[[owner interfaceController] interfaceNotificationCenter] removeObserver:self];

    [windowMenuArray release];
    [contactListWindowController release];
    [owner release];

    [super dealloc];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL enabled = YES;
    
    if(menuItem == menuItem_closeTab){
        if(![[messageWindow window] isKeyWindow]) enabled = NO;
    }else if(menuItem == menuItem_nextMessage){
        if(!messageWindow) enabled = NO;
    }else if(menuItem == menuItem_previousMessage){
        if(!messageWindow) enabled = NO;
    }

    return(enabled);
}

//Build the contents of the 'window' menu
- (void)buildWindowMenu
{
    NSMenuItem		*item;
    id <AIMessageView>	controller;
    NSEnumerator	*enumerator;
    int 		windowKey = 2;

    //Remove any existing menus
    enumerator = [windowMenuArray objectEnumerator];
    while((item = [enumerator nextObject])){
        [[owner menuController] removeMenuItem:item];
    }
    [windowMenuArray release]; windowMenuArray = [[NSMutableArray alloc] init];
    
    //Add items for the message window and any open messasge
    if(messageWindow != nil){    
        //Add a 'Messages' menu item
        item = [[NSMenuItem alloc] initWithTitle:MESSAGES_WINDOW_MENU_TITLE target:self action:@selector(showMessageWindow:) keyEquivalent:@""];
        [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
        [windowMenuArray addObject:[item autorelease]];

        //Add a menu item for each open message controller
        enumerator = [[messageWindow messageViewArray] objectEnumerator];
        while((controller = [enumerator nextObject])){
            AIContactHandle	*handle = [controller handle];
            NSString		*windowKeyString;
            
            //Prepare a key equivalent for the controller
            if(windowKey < 10){
                windowKeyString = [NSString stringWithFormat:@"%i",windowKey];
            }else{
                windowKeyString = [NSString stringWithString:@""];
            }
            
            //Create the menu item
            if(handle){
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"     %@",[handle displayName]] target:self action:@selector(showMessageWindow:) keyEquivalent:windowKeyString];
                //Do some other fancy stuff here, like adding icons to the menu
            }else{
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"     %@",[[controller title] string]] target:self action:@selector(showMessageWindow:) keyEquivalent:windowKeyString];
            }
            [item setRepresentedObject:controller]; //associate this item with a tab

            //Add it to the menu and array
            [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
            [windowMenuArray addObject:[item autorelease]];
            
            windowKey++;
        }
    }
}

//Returns (creating if necessary) a message view controller for the specified handle
- (AIMessageViewController *)messageViewControllerWithHandle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent
{
    AIMessageViewController	*controller = nil;
    AIMessageViewController	*object;
    NSEnumerator		*enumerator;

    if(!messageWindow){
        //Ensure that our message window is loaded
        [self loadMessageWindow];

    }else{
        //Search for an existing controller for this handle
        enumerator = [[messageWindow messageViewArray] objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object handle] == inHandle){
                controller = object;
            }
        }
    }

    //If the view doesn't exist, create it
    if(!controller){
        //Create the new message view controller and add it to our window
        controller = [AIMessageViewController messageViewControllerWithHandle:inHandle account:inAccount content:inContent owner:owner interface:self];
        [messageWindow addMessageViewController:controller];

        //
        [messageWindow showWindow:nil];
    }
    
    return(controller);
}

//loads (if necessary) the tabbed message window
- (void)loadMessageWindow
{
    if(!messageWindow){
        //Create the window
        messageWindow = [[AIMessageWindowController messageWindowControllerWithOwner:owner interface:self] retain];
        
        //Observe for the tab order changed notification
        [[[owner interfaceController] interfaceNotificationCenter] addObserver:self
                                                             selector:@selector(messageWindowControllersChanged:)
                                                                 name:AIMessageWindow_ControllersChanged
                                                               object:messageWindow];
        [[[owner interfaceController] interfaceNotificationCenter] addObserver:self
                                                             selector:@selector(messageWindowControllerOrderChanged:)
                                                                 name:AIMessageWindow_ControllerOrderChanged
                                                               object:messageWindow];
        [[[owner interfaceController] interfaceNotificationCenter] addObserver:self
                                                             selector:@selector(messageWindowSelectedControllerChanged:)
                                                                 name:AIMessageWindow_SelectedControllerChanged
                                                               object:messageWindow];

        //Rebuild the window menu
        [self buildWindowMenu];
    }
}

//unloads the tabbed message window
- (void)unloadMessageWindow
{
    //stop observing
    [[[owner interfaceController] interfaceNotificationCenter] removeObserver:self name:AIMessageWindow_ControllersChanged object:messageWindow];
    [[[owner interfaceController] interfaceNotificationCenter] removeObserver:self name:AIMessageWindow_ControllerOrderChanged object:messageWindow];
    [[[owner interfaceController] interfaceNotificationCenter] removeObserver:self name:AIMessageWindow_SelectedControllerChanged object:messageWindow];

    //close the window
    [messageWindow closeWindow:nil];
    [messageWindow release]; messageWindow = nil;

    //Rebuild the window menu
    [self buildWindowMenu];
}

@end



