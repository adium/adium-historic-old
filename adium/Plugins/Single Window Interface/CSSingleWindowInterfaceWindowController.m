//
//  CSSingleWindowInterfaceWindowController.m
//  Adium XCode
//
//  Created by Chris Serino on Wed Dec 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CSSingleWindowInterfaceWindowController.h"
#import "CSSingleWindowInterfacePlugin.h"
#import "AIMessageViewController.h"

#define SINGLE_WINDOW_NIB @"Single Window Interface"

@interface CSSingleWindowInterfaceWindowController (PRIVATE)

-(id)initWithInterface:(CSSingleWindowInterfacePlugin *)inInterface;
- (BOOL)_messageViewControllerHasBeenCreatedForChat:(AIChat*)inChat;
- (AIMessageViewController*)_messageViewControllerForChat:(AIChat*)inChat;

@end

@implementation CSSingleWindowInterfaceWindowController

#pragma mark Convenient class initialization
+ (CSSingleWindowInterfaceWindowController*)singleWindowInterfaceWindowControllerWithInterface:(CSSingleWindowInterfacePlugin *)inInterface
{
	return([[[self alloc] initWithInterface:inInterface] autorelease]);
}

- (id)initWithInterface:(CSSingleWindowInterfacePlugin *)inInterface
{
	if(self = [super initWithWindowNibName:SINGLE_WINDOW_NIB])
	{
		interface = inInterface;
		messageViewControllerArray = [[NSMutableArray array] retain];
	}
	return self;
}

//dealloc
- (void)dealloc
{   
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Close the contact list view
    [contactListViewController release];
    [contactListView release];
    
	[messageViewControllerArray release];
    [super dealloc];
}

#pragma mark Window Management

- (void)windowDidLoad
{
    [[self window] setDelegate:self];
    
	contactListViewController = [[[adium interfaceController] contactListViewController] retain];
    contactListView = [[contactListViewController contactListView] retain];
    [scrollView_contactList setAndSizeDocumentView:contactListView];
    [scrollView_contactList setUpdateShadowsWhileScrolling:YES];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];
    [scrollView_contactList setBorderType:NSBezelBorder];
    [[self window] makeFirstResponder:contactListView];
    
    [box_messageView setContentView:view_noActiveChat];
	
	//Register for the selection notification
    [[adium notificationCenter] addObserver:self selector:@selector(contactSelectionChanged:) name:Interface_ContactSelectionChanged object:contactListView];
}

#pragma mark Contact Selection

//Called when the user selects a new contact object
- (void)contactSelectionChanged:(NSNotification *)notification
{
    //AIListObject	*object = [[notification userInfo] objectForKey:@"Object"];

    //Configure our toolbar for the new object
}

#pragma mark Chatting

- (void)addChat:(AIChat *)inChat
{
	if (![self _messageViewControllerHasBeenCreatedForChat:inChat]) {
		AIMessageViewController *controller = [[AIMessageViewController messageViewControllerForChat:inChat] retain];
		[messageViewControllerArray addObject:controller];
	} else NSLog(@"AddChat failed");
}

- (void)setChat:(AIChat *)inChat
{
	AIMessageViewController *currentMessageViewController;
	if ([self _messageViewControllerHasBeenCreatedForChat:inChat]) {
		currentMessageViewController = [self _messageViewControllerForChat:inChat];

		[box_messageView setContentView:[currentMessageViewController view]];
		[[self window] setTitle:[NSString stringWithFormat:@"Adium : %@", [[[inChat participatingListObjects] objectAtIndex:0] displayName]]];
		activeChat = inChat;
	}
}
    
- (void)closeChat:(AIChat *)inChat
{
	int index = [messageViewControllerArray indexOfObject:activeChat]; 
	
	NSLog(@"1. index = %d",index);
	
	if(index == [messageViewControllerArray count] - 1 && index > 0) //last chat
		index--; //subtract 1
		
	if([messageViewControllerArray count] <= 1)
	{
	    [messageViewControllerArray removeObject:activeChat];
	    [box_messageView setContentView:view_noActiveChat];
	}
   	else
   	{
        [messageViewControllerArray removeObject:activeChat];
    
        if (index >= 0) //do we need this? we can take it out later
            [[adium interfaceController] setActiveChat:[[messageViewControllerArray objectAtIndex:index] chat]];
    }
}

#pragma mark Private

- (BOOL)_messageViewControllerHasBeenCreatedForChat:(AIChat*)inChat
{
	NSEnumerator *messageViewControllerEnumerator;
	AIMessageViewController *currentMessageViewController;
	
	if ([messageViewControllerArray count] <= 0) return NO;
	
	messageViewControllerEnumerator = [messageViewControllerArray objectEnumerator];
	while (currentMessageViewController = [messageViewControllerEnumerator nextObject]) {
		if ([currentMessageViewController chat] == inChat) return YES;
	}
	return NO;
}

- (AIMessageViewController*)_messageViewControllerForChat:(AIChat*)inChat
{ //loacking the controllers, it was screwing me up!
	AIMessageViewController *currentMessageViewController;
	if ([self _messageViewControllerHasBeenCreatedForChat:inChat]) {
		NSEnumerator *messageViewControllerEnumerator = [messageViewControllerArray objectEnumerator];
		
		while (currentMessageViewController = [messageViewControllerEnumerator nextObject]) {
			if ([currentMessageViewController chat] == inChat) return (currentMessageViewController);
		}
	}
	return nil;
}

#pragma mark Delegate Methods

- (BOOL)windowShouldClose:(id)sender
{
	if([messageViewControllerArray count] > 0) 
	{ 
		[[adium interfaceController] closeChat:activeChat];
		return NO;
	}
    return YES;
}

@end
