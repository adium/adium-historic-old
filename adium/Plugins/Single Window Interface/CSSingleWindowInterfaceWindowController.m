//
//  CSSingleWindowInterfaceWindowController.m
//  Adium XCode
//
//  Created by Chris Serino on Wed Dec 31 2003.
//

#import "CSSingleWindowInterfaceWindowController.h"
#import "CSSingleWindowInterfacePlugin.h"
#import "CSCurrentChatsListViewController.h"
#import "AIMessageViewController.h"

#define SINGLE_WINDOW_NIB @"Single Window Interface"
#define	KEY_SINGLE_WINDOW_INTERFACE_FRAME	@"Single Window Interface Frame"

@interface CSSingleWindowInterfaceWindowController (PRIVATE)

-(id)initWithInterface:(CSSingleWindowInterfacePlugin *)inInterface;

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
		currentChatsController = [[CSCurrentChatsListViewController alloc] init];
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
	
	//Close the current chats view
	[currentChatsController release];
    
    [super dealloc];
}

#pragma mark Window Management

- (void)windowDidLoad
{
	NSString	*savedFrame;
    
    //Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_SINGLE_WINDOW_INTERFACE_FRAME];
    if(savedFrame){
        [[self window] setFrame:NSRectFromString(savedFrame) display:YES];            
    }
	
    [[self window] setDelegate:self];
    
	contactListViewController = [[[adium interfaceController] contactListViewController] retain];
    contactListView = [[contactListViewController contactListView] retain];
    [scrollView_contactList setAndSizeDocumentView:contactListView];
    [scrollView_contactList setUpdateShadowsWhileScrolling:YES];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];
    [scrollView_contactList setBorderType:NSBezelBorder];
    [[self window] makeFirstResponder:contactListView];
    
	[scrollView_currentChatsList setAndSizeDocumentView:[currentChatsController view]];
	[scrollView_currentChatsList setAutoScrollToBottom:NO];
    [scrollView_currentChatsList setAutoHideScrollBar:YES];
    [scrollView_currentChatsList setBorderType:NSBezelBorder];
	
    [box_messageView setContentView:view_noActiveChat];
}

- (void)collapseContactList:(id)sender
{
	NSMenuItem *item = (NSMenuItem*)sender;
	if (item) {
		NSRect newFrame = [scrollView_contactList frame];
		if ([[item title] isEqualToString:HIDE_CONTACT_LIST]) {
			[item setTitle:SHOW_CONTACT_LIST];
			[item setRepresentedObject:[NSNumber numberWithInt:newFrame.size.width]];
			newFrame.size.width = 0;
			[scrollView_contactList setFrame:newFrame];
		} else {
			[item setTitle:HIDE_CONTACT_LIST];
			newFrame.size.width = [[item representedObject] intValue];
			[scrollView_contactList setFrame:newFrame];
		}
	}
}

#pragma mark Chatting

- (void)addChat:(AIChat *)inChat
{
	[currentChatsController openChat:inChat];
}

- (void)setChat:(AIChat *)inChat
{
	AIMessageViewController *currentMessageViewController;
	
	currentMessageViewController = [currentChatsController messageViewControllerForChat:inChat];
	[currentChatsController setChat:inChat];
	
	[box_messageView setContentView:[currentMessageViewController view]];
	[[self window] setTitle:[NSString stringWithFormat:@"Adium : %@", [[[inChat participatingListObjects] objectAtIndex:0] displayName]]];
}
    
- (void)closeChat:(AIChat *)inChat
{
	[currentChatsController closeChat:inChat];
	
	[box_messageView setContentView:view_noActiveChat];
}

- (AIChat*)activeChat
{
	return [currentChatsController activeChat];
}

- (CSCurrentChatsListViewController*)currentChatsController
{
	return currentChatsController;
}

#pragma mark Delegate Methods

- (BOOL)windowShouldClose:(id)sender
{
	if([currentChatsController count] > 0) 
	{ 
		[currentChatsController tableViewDeleteSelectedRows:nil];
		return NO;
	}
    
	[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_SINGLE_WINDOW_INTERFACE_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
	return YES;
}

@end
