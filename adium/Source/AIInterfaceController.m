/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id: AIInterfaceController.m,v 1.83 2004/07/19 16:47:12 adamiser Exp $

#import "AIInterfaceController.h"
#import "AIContactListWindowController.h"

#define CLOSE_CHAT_MENU_TITLE			AILocalizedString(@"Close Chat","Title for the close chat menu item")
#define CLOSE_MENU_TITLE				AILocalizedString(@"Close","Title for the close menu item")

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins"
#define ERROR_MESSAGE_WINDOW_TITLE		AILocalizedString(@"Adium : Error","Error message window title")
#define LABEL_ENTRY_SPACING				4.0
#define DISPLAY_IMAGE_ON_RIGHT			NO

#define PREF_GROUP_FORMATTING			@"Formatting"
#define KEY_FORMATTING_FONT				@"Default Font"


#define CONTACT_LIST_WINDOW_MENU_TITLE  AILocalizedString(@"Contact List","Title for the contact list menu item")
#define MESSAGES_WINDOW_MENU_TITLE		AILocalizedString(@"Messages","Title for the messages window menu item")

@interface AIInterfaceController (PRIVATE)
- (void)_resetOpenChatsCache;
- (void)_resortChat:(AIChat *)chat;
- (void)_resortAllChats;
- (NSArray *)_listObjectsForChatsInContainerNamed:(NSString *)containerName;
- (void)_addItemToMainMenuAndDock:(NSMenuItem *)item;
- (NSAttributedString *)_tooltipTitleForObject:(AIListObject *)object;
- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object;
- (void)_pasteWithPreferredSelector:(SEL)preferredSelector sender:(id)sender;
@end

@implementation AIInterfaceController

//init
- (void)initController
{     
    contactListViewArray = [[NSMutableArray alloc] init];
    messageViewArray = [[NSMutableArray alloc] init];
//    interfaceArray = [[NSMutableArray alloc] init];
    contactListTooltipEntryArray = [[NSMutableArray alloc] init];
    contactListTooltipSecondaryEntryArray = [[NSMutableArray alloc] init];
	closeMenuConfiguredForChat = NO;
	_cachedOpenChats = nil;

#warning load from pref
groupChatsByContactGroup = YES;
arrangeChats = YES;

    tooltipListObject = nil;
    tooltipTitle = nil;
    tooltipBody = nil;
    tooltipImage = nil;
    flashObserverArray = nil;
    flashTimer = nil;
    flashState = 0;
	
	windowMenuArray = nil;
	
    //Observe content so we can open chats as necessary
    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) 
									   name:Content_DidReceiveContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:)
									   name:Content_FirstContentRecieved object:nil];

}

- (void)finishIniting
{
    //Load the interface
    [interface openInterface];

    //Configure our dynamic paste menu item
    [menuItem_paste setDynamic:YES];
    [menuItem_pasteFormatted setDynamic:YES];

	//Open the contact list window
    [self showContactList:nil];

	//Contact list menu tem
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE
												   target:self
												   action:@selector(toggleContactList:)
											keyEquivalent:@"/"] autorelease];
	[menuController addMenuItem:item toLocation:LOC_Window_Fixed];
	[menuController addMenuItem:[[item copy] autorelease] toLocation:LOC_Dock_Status];

#warning dont observe if not enabled
	[[owner notificationCenter] addObserver:self 
								   selector:@selector(contactOrderChanged:)
									   name:Contact_OrderChanged 
									 object:nil];
	
	
}

- (void)closeController
{
    if(contactListWindowController) [contactListWindowController close:nil];
    [interface closeInterface]; //Close the interface
}

// Dealloc
- (void)dealloc
{
    [contactListViewArray release]; contactListViewArray = nil;
    [messageViewArray release]; messageViewArray = nil;
    [interfaceArray release]; interfaceArray = nil;
	
    [tooltipListObject release]; tooltipListObject = nil;
	[tooltipTitle release]; tooltipTitle = nil;
	[tooltipBody release]; tooltipBody = nil;
	[tooltipImage release]; tooltipImage = nil;
	
    [super dealloc];
}

//If no windows are visible, show the contact list
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows
{
#warning re-implement
//    if(contactListWindowController == nil && [messageWindowControllerArray count] == 0){
//		[self showContactList:nil];
//		return(NO);
//    }else{
//		return([interface handleReopenWithVisibleWindows:visibleWindows]);    
//	}
	return YES;
}

// Registers code to handle the interface
- (void)registerInterfaceController:(id <AIInterfaceController>)inController
{
	if(!interface){
		interface = [inController retain];
	}
//    [interfaceArray addObject:inController];
}


//Contact List ---------------------------------------------------------------------------------------------------------
#pragma mark Contact list
#warning contact list hard coded for now.  Merge contact list window with contact list view, move into plugin.
//Registers a view to handle the contact list.  The user may chose from the available views
//The view only needs to be added to the interface, it is entirely self sufficient
- (void)registerContactListViewPlugin:(id <AIContactListViewPlugin>)inPlugin
{
    [contactListViewArray addObject:inPlugin];
}
- (id <AIContactListViewController>)contactListViewController
{
    return([[contactListViewArray objectAtIndex:0] contactListViewController]);
}

//Toggle the contact list
- (IBAction)toggleContactList:(id)sender
{
    if(contactListWindowController && [[contactListWindowController window] isMainWindow]){ //The window is loaded and main
		[self closeContactList:nil];
    }else{
		[self showContactList:nil];
    } 
}

//Show the contact list window
- (IBAction)showContactList:(id)sender
{
    if(!contactListWindowController){ //Load the window
        contactListWindowController = [[AIContactListWindowController contactListWindowController] retain];
    }
    [contactListWindowController makeActive:nil];
}

//Show the contact list window and bring Adium to the front
- (IBAction)showContactListAndBringToFront:(id)sender
{
    [self showContactList:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

//Close the contact list window
- (IBAction)closeContactList:(id)sender
{
    if(contactListWindowController){
        [[contactListWindowController window] performClose:nil];
    }
}

- (void)contactListDidClose
{
	[contactListWindowController release]; contactListWindowController = nil;
}
	

//Messaging ------------------------------------------------------------------------------------------------------------
//Methods for instructing the interface to provide a representation of chats, and to determine which chat has user focus
#pragma mark Messaging
//Open a window for the chat
- (void)openChat:(AIChat *)inChat
{
	NSArray		*containers = [interface openContainersAndChats];
	NSString	*containerName;
	int			index = -1;
	
	//Determine the correct container for this chat
	if(groupChatsByContactGroup){
		AIListGroup	*group = [[inChat listObject] containingGroup];
		containerName = (group ? [group displayName] : @"Chat"); 
	}else{
		//Open new chats into the first container (if not available, create a new one)
		if([containers count] > 0){
			containerName = [[containers objectAtIndex:0] objectForKey:@"Title"];
		}else{
			containerName = @"Adium_First_Container";
		}
	}

	//Determine the correct placement for this chat withing the container
	if(arrangeChats){
		index = [self indexForInsertingChat:inChat intoContainerNamed:containerName];
	}
	
	[interface openChat:inChat inContainerNamed:containerName atIndex:index];
}

//Set the active chat window
- (void)setActiveChat:(AIChat *)inChat
{
	[interface setActiveChat:inChat];
}

//Close the window for a chat
- (void)closeChat:(AIChat *)inChat
{
    [interface closeChat:inChat];
}

//Active chat
- (AIChat *)activeChat
{
	return(activeChat);
}

//Returns an array of open chats (cached, so call as frequently as desired)
- (NSArray *)openChats
{
	if(!_cachedOpenChats){
		_cachedOpenChats = [[interface openChats] retain];
	}
	
	return(_cachedOpenChats);
}

//
- (NSArray *)openChatsInContainerNamed:(NSString *)containerName
{
	return([interface openChatsInContainerNamed:containerName]);
}

//Resets the cache of open chats
- (void)_resetOpenChatsCache
{
	[_cachedOpenChats release]; _cachedOpenChats = nil;
}

//Allow the user to change chat order?
- (BOOL)allowChatOrdering
{
	return(!arrangeChats);
}


//Interface plugin callbacks -------------------------------------------------------------------------------------------
//These methods are called by the interface to let us know what's going on.  We're informed of chats opening, closing,
//changing order, etc.
#pragma mark Interface plugin callbacks
//A chat window did open: rebuild our window menu to show the new chat
- (void)chatDidOpen:(AIChat *)inChat
{
	[self _resetOpenChatsCache];
	[self buildWindowMenu];
}

//A chat has become active: update our chat closing keys and flag this chat as selected in the window menu
- (void)chatDidBecomeActive:(AIChat *)inChat
{
	NSLog(@"chatDidBecomeActive:%@",inChat);
	[activeChat release]; activeChat = [inChat retain];
	[self clearUnviewedContentOfChat:inChat];
	[self updateCloseMenuKeys];
	[self updateActiveWindowMenuItem];
}

//A chat window did close: rebuild our window menu to remove the chat
- (void)chatDidClose:(AIChat *)inChat
{
	[self _resetOpenChatsCache];
	[self clearUnviewedContentOfChat:inChat];
	[self buildWindowMenu];
}

//The order of chats has changed: rebuild our window menu to reflect the new order
- (void)chatOrderDidChange
{
	[self _resetOpenChatsCache];
	[self buildWindowMenu];
}

//Clear the unviewed content count of the chat.  This is done when chats are made active or closed.
- (void)clearUnviewedContentOfChat:(AIChat *)inChat
{
	NSEnumerator	*enumerator;
    AIListObject	*listObject;
	
    enumerator = [[inChat participatingListObjects] objectEnumerator];
    while(listObject = [enumerator nextObject]){
		if([listObject integerStatusObjectForKey:@"UnviewedContent"]){
			[[owner contentController] clearUnviewedContentOfListObject:listObject];
		}
    }
}

//Content was received, increase the unviewed content count of the chat (if it's not currently active)
- (void)didReceiveContent:(NSNotification *)notification
{
	NSDictionary		*userInfo = [notification userInfo];
	AIContentObject		*object = [userInfo objectForKey:@"Object"];
	
	if([object chat] != activeChat){
		[[owner contentController] increaseUnviewedContentOfListObject:[object source]];
	}
}
#warning possible to simplify interface protocol any?


//Dynamically ordering / grouping tabs ---------------------------------------------------------------------------------
- (void)contactOrderChanged:(NSNotification *)notification
{
	NSLog(@"contactOrderChanged: %@",[notification object]);
	
	if(arrangeChats){
		AIListObject		*changedObject = [notification object];
		
		if(changedObject){
			NSEnumerator	*enumerator = [[self openChats] objectEnumerator];
			AIChat			*chat;
			
			//Check if we have a chat window open with this contact.  If we do, re-sort that chat
			//Unfortunately we need to enumerate all our chats to determine this - Stupid group chats screwing everything up
			while(chat = [enumerator nextObject]){
				if([chat listObject] == changedObject) break;
			}
			if(chat) [self _resortChat:chat];
			
		}else{
			//Entire list was resorted, resort all our chats
			[self _resortAllChats];
		}
	}
	
}

//
- (void)_resortChat:(AIChat *)chat
{
	NSString	*containerName = [interface containerNameForChat:chat];
		
	[interface moveChat:chat toContainerNamed:containerName
				  index:[self indexForInsertingChat:chat intoContainerNamed:containerName]];
	
}

//
- (void)_resortAllChats
{
	AISortController	*sortController = [[owner contactController] activeSortController];
	NSEnumerator		*containerEnumerator = [[interface openContainerNames] objectEnumerator];
	NSString			*containerName;
	
	while(containerName = [containerEnumerator nextObject]){
		NSArray			*chatsInContainer = [self openChatsInContainerNamed:containerName];
		NSMutableArray  *listObjects;
		NSMutableArray  *sortedListObjects;
		NSEnumerator	*objectEnumerator;
		AIListObject	*object;
		int				index = 0;
		
		//Sort the chats in this container
		listObjects = [self _listObjectsForChatsInContainerNamed:containerName];
		sortedListObjects = [listObjects mutableCopy];
		[sortController sortListObjects:sortedListObjects];
		
		//Sync the container with the sorted chats
		objectEnumerator = [listObjects objectEnumerator];
		while(object = [objectEnumerator nextObject]){
			[interface moveChat:[chatsInContainer objectAtIndex:[listObjects indexOfObject:object]]
			   toContainerNamed:containerName
						  index:index++];
		}
	}
}


- (int)indexForInsertingChat:(AIChat *)chat intoContainerNamed:(NSString *)containerName
{
	AISortController	*sortController = [[owner contactController] activeSortController];

	return([sortController indexForInserting:[chat listObject]
								 intoObjects:[self _listObjectsForChatsInContainerNamed:containerName]]);
}

//Build array of list objects to sort
//We can't keep track of this easily since participating list objects may change due to multi-user chat
//Multi-user chats make this so difficult :(
#warning would love to do away with this
- (NSArray *)_listObjectsForChatsInContainerNamed:(NSString *)containerName
{
	NSMutableArray	*listObjects = [NSMutableArray array];
	NSEnumerator	*enumerator;
	AIChat			*chat;
	AIListObject	*listObject;

	enumerator = [[self openChatsInContainerNamed:containerName] objectEnumerator];
	while(chat = [enumerator nextObject]){
		listObject = [chat listObject];
		if(listObject) [listObjects addObject:listObject];
	}
	
	return(listObjects);
}





//Chat close menus -----------------------------------------------------------------------------------------------------
#pragma mark Chat close menus
//Close the active window
- (IBAction)closeMenu:(id)sender
{
    [[[NSApplication sharedApplication] keyWindow] performClose:nil];
}

//Close the active chat
- (IBAction)closeChatMenu:(id)sender
{
	if(activeChat) [self closeChat:activeChat];
}

//Updates the key equivalents on 'close' and 'close chat' (dynamically changed to make cmd-w less destructive)
- (void)updateCloseMenuKeys
{
	if(activeChat && !closeMenuConfiguredForChat){
		NSLog(@"%@ becomes W",menuItem_close);
        [menuItem_close setKeyEquivalent:@"W"];
        [menuItem_closeChat setKeyEquivalent:@"w"];
		closeMenuConfiguredForChat = YES;
	}else if(!activeChat && closeMenuConfiguredForChat){
		NSLog(@"%@ becomes w",menuItem_close);
        [menuItem_close setKeyEquivalent:@"w"];
		[menuItem_closeChat removeKeyEquivalent];		
		closeMenuConfiguredForChat = NO;
	}
}


//Window Menu ----------------------------------------------------------------------------------------------------------
#pragma mark Window Menu
//Make a chat window active (Invoked by a selection in the window menu)
- (IBAction)showChatWindow:(id)sender
{
	[self setActiveChat:[sender representedObject]];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

//Updates the 'check' icon so it's next to the active window
- (void)updateActiveWindowMenuItem
{
    NSEnumerator	*enumerator = [windowMenuArray objectEnumerator];
    NSMenuItem		*item;

    while((item = [enumerator nextObject])){
		if([item representedObject]) [item setState:([item representedObject] == activeChat ? NSOnState : NSOffState)];
    }
}

//Builds the window menu
//This function gets called whenever chats are opened, closed, or re-ordered - so improvements and optimizations here
//would probably be helpful
- (void)buildWindowMenu
{	
    NSMenuItem				*item;
    NSEnumerator			*enumerator;
//    NSEnumerator			*tabViewEnumerator;
//    NSEnumerator			*windowEnumerator;
    int						windowKey = 1;
	BOOL					respondsToSetIndentationLevel = [menuItem_paste respondsToSelector:@selector(setIndentationLevel:)];
	
	
    //Remove any existing menus
    enumerator = [windowMenuArray objectEnumerator];
    while((item = [enumerator nextObject])){
        [menuController removeMenuItem:item];
    }
    [windowMenuArray release]; windowMenuArray = [[NSMutableArray alloc] init];
	
    //Messages window and any open messasges
	NSEnumerator	*containerEnumerator = [[interface openContainersAndChats] objectEnumerator];
	NSDictionary	*containerDict;
	
	while(containerDict = [containerEnumerator nextObject]){
		NSString		*containerName = [containerDict objectForKey:@"Title"];
		NSArray			*contentArray = [containerDict objectForKey:@"Content"];
		NSEnumerator	*contentEnumerator = [contentArray objectEnumerator];
		AIChat			*chat;
		
		//Add a menu item for the container
		if([contentArray count] > 1){
			item = [[[NSMenuItem alloc] initWithTitle:containerName
											   target:nil
											   action:nil
										keyEquivalent:@""] autorelease];
			[self _addItemToMainMenuAndDock:item];
		}
		
		//Add items for the chats it contains
		while(chat = [contentEnumerator nextObject]){
			NSString		*windowKeyString;
			
			//Prepare a key equivalent for the controller
			if(windowKey < 10){
				windowKeyString = [NSString stringWithFormat:@"%i",(windowKey)];
			}else if (windowKey == 10){
				windowKeyString = [NSString stringWithString:@"0"];
			}else{
				windowKeyString = [NSString stringWithString:@""];
			}
			
			item = [[[NSMenuItem alloc] initWithTitle:[chat name]
											   target:self
											   action:@selector(showChatWindow:)
										keyEquivalent:windowKeyString] autorelease];
			if([contentArray count] > 1 && respondsToSetIndentationLevel) [item setIndentationLevel:1];
			[item setRepresentedObject:chat];
			[item setImage:[chat chatMenuImage]];
			[self _addItemToMainMenuAndDock:item];
			
			windowKey++;
		}
	}

	[self updateActiveWindowMenuItem];
}

//Adds a menu item to the internal array, dock menu, and main menu
- (void)_addItemToMainMenuAndDock:(NSMenuItem *)item
{
	//Add to main menu first
	[menuController addMenuItem:item toLocation:LOC_Window_Fixed];
	[windowMenuArray addObject:item];
	
	//Make a copy, and add to the dock
	item = [[item copy] autorelease];
	[item setKeyEquivalent:@""];
	[menuController addMenuItem:item toLocation:LOC_Dock_Status];
	[windowMenuArray addObject:item];
}


//Chat Cycling ---------------------------------------------------------------------------------------------------------
#pragma mark Chat Cycling
//Select the next message
- (IBAction)nextMessage:(id)sender
{
	NSArray	*openChats = [self openChats];

	if([openChats count]){
		if(activeChat){
			int chatIndex = [openChats indexOfObject:activeChat]+1;
			[self setActiveChat:[openChats objectAtIndex:(chatIndex < [openChats count] ? chatIndex : 0)]];
		}else{
			[self setActiveChat:[openChats objectAtIndex:0]];
		}
	}
}

//Select the previous message
- (IBAction)previousMessage:(id)sender
{
	NSArray	*openChats = [self openChats];
	
	if([openChats count]){
		if(activeChat){
			int chatIndex = [openChats indexOfObject:activeChat]-1;
			[self setActiveChat:[openChats objectAtIndex:(chatIndex >= 0 ? chatIndex : [openChats count]-1)]];
		}else{
			[self setActiveChat:[openChats lastObject]];
		}
	}
}


//Message View ---------------------------------------------------------------------------------------------------------
//Message view is abstracted from the containing interface, since they're not directly related to eachother
#pragma mark Message View
//Registers a view to handle the contact list
- (void)registerMessageViewPlugin:(id <AIMessageViewPlugin>)inPlugin
{
    [messageViewArray addObject:inPlugin];
}
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([[messageViewArray objectAtIndex:0] messageViewControllerForChat:inChat]);
}


//Error Display --------------------------------------------------------------------------------------------------------
#pragma mark Error Display
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc
{
    [self handleMessage:inTitle withDescription:inDesc withWindowTitle:ERROR_MESSAGE_WINDOW_TITLE];
}

- (void)handleMessage:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle;
{
    NSDictionary	*errorDict;
    
    //Post a notification that an error was recieved
    errorDict = [NSDictionary dictionaryWithObjectsAndKeys:inTitle,@"Title",inDesc,@"Description",inWindowTitle,@"Window Title",nil];
    [[owner notificationCenter] postNotificationName:Interface_ShouldDisplayErrorMessage object:nil userInfo:errorDict];
}


//Synchronized Flashing ------------------------------------------------------------------------------------------------
#pragma mark Synchronized Flashing
//Register to observe the synchronized flashing
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Setup the timer if we don't have one yet
    if(flashObserverArray == nil){
        flashObserverArray = [[NSMutableArray alloc] init];
        flashTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) 
                                                       target:self 
                                                     selector:@selector(flashTimer:) 
                                                     userInfo:nil
                                                      repeats:YES] retain];
    }
    
    //Add the new observer to the array
    [flashObserverArray addObject:inObserver];
}

//Unregister from observing flashing
- (void)unregisterFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Remove the observer from our array
    [flashObserverArray removeObject:inObserver];
    
    //Release the observer array and uninstall the timer
    if([flashObserverArray count] == 0){
        [flashObserverArray release]; flashObserverArray = nil;
        [flashTimer invalidate];
        [flashTimer release]; flashTimer = nil;
    }
}

//Timer, invoke a flash
- (void)flashTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    id<AIFlashObserver>	observer;
    
    flashState++;
    
    enumerator = [flashObserverArray objectEnumerator];
    while((observer = [enumerator nextObject])){
        [observer flash:flashState];
    }
}

//Current state of flashing.  This is an integer the increases by 1 with every flash.  Mod to whatever range is desired
- (int)flashState
{
    return(flashState);
}


//Tooltips -------------------------------------------------------------------------------------------------------------
#pragma mark Tooltips
//Registers code to display tooltip info about a contact
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary
{
    if (isSecondary)
        [contactListTooltipSecondaryEntryArray addObject:inEntry];
    else
        [contactListTooltipEntryArray addObject:inEntry];
}

//list object tooltips
- (void)showTooltipForListObject:(AIListObject *)object atScreenPoint:(NSPoint)point onWindow:(NSWindow *)inWindow 
{
    if(object){
        if(object == tooltipListObject){ //If we already have this tooltip open
                                         //Move the existing tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
												body:tooltipBody
											   image:tooltipImage 
										imageOnRight:DISPLAY_IMAGE_ON_RIGHT 
											onWindow:inWindow
											 atPoint:point 
										 orientation:TooltipBelow];
            
        }else{ //This is a new tooltip
            NSArray                     *tabArray;
            NSMutableParagraphStyle     *paragraphStyleTitle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            NSMutableParagraphStyle     *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            
            //Hold onto the new object
            [tooltipListObject release]; tooltipListObject = [object retain];
            
            //Buddy Icon
            [tooltipImage release];
			tooltipImage = [[[tooltipListObject displayArrayForKey:KEY_USER_ICON] objectValue] retain];
            
            //Reset the maxLabelWidth for the tooltip generation
            maxLabelWidth = 0;
            
            //Build a tooltip string for the primary information
            [tooltipTitle release]; tooltipTitle = [[self _tooltipTitleForObject:object] retain];
            
            //If there is an image, set the title tab and indentation settings independently
            if (tooltipImage) {
                //Set a right-align tab at the maximum label width and a left-align just past it
                tabArray = [[NSArray alloc] initWithObjects:[[NSTextTab alloc] initWithType:NSRightTabStopType 
                                                                                   location:maxLabelWidth]
                                                            ,[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                   location:maxLabelWidth + LABEL_ENTRY_SPACING]
                                                            ,nil];
                
                [paragraphStyleTitle setTabStops:tabArray];
                [tabArray release];
                tabArray = nil;
                [paragraphStyleTitle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
                
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName 
                                     value:paragraphStyleTitle
                                     range:NSMakeRange(0,[tooltipTitle length])];
                
                //Reset the max label width since the body will be independent
                maxLabelWidth = 0;
            }
            
            //Build a tooltip string for the secondary information
            [tooltipBody release]; tooltipBody = nil;
            tooltipBody = [[self _tooltipBodyForObject:object] retain];
            
            //Set a right-align tab at the maximum label width for the body and a left-align just past it
            tabArray = [[NSArray alloc] initWithObjects:[[[NSTextTab alloc] initWithType:NSRightTabStopType 
                                                                                 location:maxLabelWidth] autorelease]
                                                        ,[[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                location:maxLabelWidth + LABEL_ENTRY_SPACING] autorelease]
                                                        ,nil];
            [paragraphStyle setTabStops:tabArray];
            [tabArray release];
            [paragraphStyle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
            
            [tooltipBody addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipBody length])];
            //If there is no image, also use these settings for the top part
            if (!tooltipImage) {
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipTitle length])];
            }
            
            //Display the new tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
                                                body:tooltipBody 
                                               image:tooltipImage
                                        imageOnRight:DISPLAY_IMAGE_ON_RIGHT
                                            onWindow:inWindow
                                             atPoint:point 
                                         orientation:TooltipBelow];
        }
        
    }else{
        //Hide the existing tooltip
        if(tooltipListObject){
            [AITooltipUtilities showTooltipWithTitle:nil 
                                                body:nil
                                               image:nil 
                                            onWindow:nil
                                             atPoint:point
                                         orientation:TooltipBelow];
            [tooltipListObject release]; tooltipListObject = nil;
			
			[tooltipTitle release]; tooltipTitle = nil;
			[tooltipBody release]; tooltipBody = nil;
			[tooltipImage release]; tooltipImage = nil;
        }
    }
}

- (NSAttributedString *)_tooltipTitleForObject:(AIListObject *)object
{
    NSMutableAttributedString           *titleString = [[NSMutableAttributedString alloc] init];
    
    id <AIContactListTooltipEntry>		tooltipEntry;
    NSEnumerator						*enumerator;
    NSEnumerator                        *labelEnumerator;
    NSMutableArray                      *labelArray = [NSMutableArray array];
    NSMutableArray                      *entryArray = [NSMutableArray array];
    NSMutableAttributedString           *entryString;
    float                               labelWidth;
    BOOL                                isFirst = YES;
    
    NSString                            *displayName = [object displayName];
    NSString                            *formattedUID = [object formattedUID];
    
    //Configure fonts and attributes
    NSFontManager                       *fontManager = [NSFontManager sharedFontManager];
    NSFont                              *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary                 *titleDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:12] toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil];
    NSMutableDictionary                 *labelDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSMutableDictionary                 *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:2] , NSFontAttributeName, nil];
    NSMutableDictionary                 *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    
    //"<DisplayName>" (or) "<DisplayName> (<UID>)"
    if([[displayName compactedString] isEqualToString:[formattedUID compactedString]]){
        [titleString appendString:[NSString stringWithFormat:@"%@", displayName] withAttributes:titleDict];
    }else{
        [titleString appendString:[NSString stringWithFormat:@"%@ (%@)", displayName, formattedUID] withAttributes:titleDict];
    }
    
    //Add the serviceID, three spaces away
    if ([object isKindOfClass:[AIListContact class]]){
        [titleString appendString:[NSString stringWithFormat:@"   %@",[object displayServiceID]]
                   withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                       [fontManager convertFont:[NSFont toolTipsFontOfSize:9] 
                                    toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil]];
    }
    
    if ([object isKindOfClass:[AIListGroup class]]){
        [titleString appendString:[NSString stringWithFormat:@" (%i/%i)",[(AIListGroup *)object visibleCount],[(AIListGroup *)object count]] 
                   withAttributes:titleDict];
    }
    
    //Entries from plugins
    
    //Calculate the widest label while loading the arrays
    enumerator = [contactListTooltipEntryArray objectEnumerator];
    
    while (tooltipEntry = [enumerator nextObject]){
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
																						 attributes:labelDict];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                [labelAttribString release];
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
        [entryString release];
    }
    
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    
    while((entryString = [enumerator nextObject])){        
        NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
																				 attributes:labelDict];
        
        //Add a carriage return
        [titleString appendString:@"\r" withAttributes:labelEndLineDict];
        
        if (isFirst) {
            //skip a line
            [titleString appendString:@"\r" withAttributes:labelEndLineDict];
            isFirst = NO;
        }
        
        //Add the label (with its spacing)
        [titleString appendAttributedString:labelAttribString];
		[labelAttribString release];
        [titleString appendAttributedString:[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])]];
    }
    return [titleString autorelease];
}

- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object
{
    NSMutableAttributedString       *tipString = [[NSMutableAttributedString alloc] init];
    
    //Configure fonts and attributes
    NSFontManager                   *fontManager = [NSFontManager sharedFontManager];
    NSFont                          *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary             *labelDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSMutableDictionary             *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:1], NSFontAttributeName, nil];
    NSMutableDictionary             *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    
    //Entries from plugins
    id <AIContactListTooltipEntry>  tooltipEntry;
    NSEnumerator                    *enumerator;
    NSEnumerator                    *labelEnumerator; 
    NSMutableArray                  *labelArray = [NSMutableArray array];
    NSMutableArray                  *entryArray = [NSMutableArray array];    
    NSMutableAttributedString       *entryString;
    float                           labelWidth;
    BOOL                            firstEntry = YES;
    
    //Calculate the widest label while loading the arrays
    enumerator = [contactListTooltipSecondaryEntryArray objectEnumerator];
    
    while (tooltipEntry = [enumerator nextObject]){
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
                                                                                         attributes:labelDict];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                [labelAttribString release];
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
        [entryString release];
    }
    
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    while((entryString = [enumerator nextObject])){
        NSMutableAttributedString *labelString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
                                                                                         attributes:labelDict] autorelease];
        
        if (firstEntry) {
            firstEntry = NO;
        } else {
            //Add a carriage return and skip a line
            [tipString appendString:@"\r\r" withAttributes:labelEndLineDict];
        }
        
        //Add the label (with its spacing)
        [tipString appendAttributedString:labelString];
        
        NSRange fullLength = NSMakeRange(0, [entryString length]);
        
        //remove any background coloration
        [entryString removeAttribute:NSBackgroundColorAttributeName range:fullLength];
        
        //adjust foreground colors for the tooltip background
        [entryString adjustColorsToShowOnBackground:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.800 alpha:1.0]];

        //headIndent doesn't apply to the first line of a paragraph... so when new lines are in the entry, we need to tab over to the proper location
        if ([entryString replaceOccurrencesOfString:@"\r" withString:@"\r\t\t" options:NSLiteralSearch range:fullLength])
            fullLength = NSMakeRange(0, [entryString length]);
        if ([entryString replaceOccurrencesOfString:@"\n" withString:@"\n\t\t" options:NSLiteralSearch range:fullLength])
            fullLength = NSMakeRange(0, [entryString length]);
		
        //Run the entry through the filters and add it to tipString
		entryString = [[[[owner contentController] filterAttributedString:entryString
														usingFilterType:AIFilterDisplay
															  direction:AIFilterIncoming
																context:object] mutableCopy] autorelease];

		[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])];

        [tipString appendAttributedString:entryString];
    }

    return([tipString autorelease]);
}

//Custom pasting ----------------------------------------------------------------------------------------------------
#pragma mark Custom Pasting
//Paste, stripping formatting
- (IBAction)paste:(id)sender
{
	[self _pasteWithPreferredSelector:@selector(pasteAsPlainText:) sender:sender];
}

//Paste with formatting
- (IBAction)pasteFormatted:(id)sender
{
	[self _pasteWithPreferredSelector:@selector(pasteAsRichText:) sender:sender];
}

- (void)_pasteWithPreferredSelector:(SEL)preferredSelector sender:(id)sender
{
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSResponder	*responder = [keyWindow firstResponder];
	SEL			pasteSelector = nil;
	
	//First, walk down the responder chain looking for a responder which can handle the preferred selector
	while(responder && !([responder respondsToSelector:preferredSelector])){
		responder = [responder nextResponder];
	}
	
	if (responder){
		pasteSelector = preferredSelector;
		
	}else{
		//No responder found.  Try again, looking for one which will respond to paste:
		responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		while(responder && !([responder respondsToSelector:@selector(paste:)])){
			responder = [responder nextResponder];
		}
		
		if (responder) pasteSelector = @selector(paste:);
	}
	
	if (pasteSelector){
		[keyWindow makeFirstResponder:responder];
		[responder performSelector:pasteSelector
						withObject:sender];
	}
}

//Custom Dimming menu items --------------------------------------------------------------------------------------------
#pragma mark Custom Dimming menu items
//The standard ones do not dim correctly when unavailable
- (IBAction)toggleFontTrait:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    
    if([fontManager traitsOfFont:[fontManager selectedFont]] & [sender tag]){
        [fontManager removeFontTrait:sender];
    }else{
        [fontManager addFontTrait:sender];
    }
}

- (void)toggleToolbarShown:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window toggleToolbarShown:sender];
}

- (void)runToolbarCustomizationPalette:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window runToolbarCustomizationPalette:sender];
}

//Menu item validation
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow];
	NSResponder *responder = [window firstResponder]; 

    if(menuItem == menuItem_bold || menuItem == menuItem_italic){
		NSFont			*selectedFont = [[NSFontManager sharedFontManager] selectedFont];
		
		//We must be in a text view, have text on the pasteboard, and have a font that supports bold or italic
		if([responder isKindOfClass:[NSTextView class]]){
#warning Evan: This should be cached by the font manager additions.
			return (menuItem == menuItem_bold ? [selectedFont supportsBold] : [selectedFont supportsItalics]);
		}
		return(NO);
		
	}else if(menuItem == menuItem_paste || menuItem == menuItem_pasteFormatted){
		return([[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, NSTIFFPboardType,nil]] != nil);
	
	}else if(menuItem == menuItem_showToolbar){
		[menuItem_showToolbar setTitle:([[window toolbar] isVisible] ? @"Hide Toolbar" : @"Show Toolbar")];
		return([window toolbar] != nil);
	
	}else if(menuItem == menuItem_customizeToolbar){
		return([window toolbar] != nil && [[window toolbar] isVisible]);

	}else if(menuItem == menuItem_closeChat){
		return(activeChat != nil);
#warning && [activeChat contaningWindow] numberOfTabs > 1
		
	}else{
		return(YES);
	}
}

@end


