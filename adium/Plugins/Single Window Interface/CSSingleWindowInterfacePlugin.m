//
//  CSSingleWindowInterfacePlugin.m
//  Adium XCode
//
//  Created by Chris Serino on Wed Dec 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CSSingleWindowInterfacePlugin.h"
#import "CSSingleWindowInterfaceWindowController.h"

#define SINGLE_WINDOW_NIB @"Single Window Interface"

#define SHOW_MAIN_WINDOW    AILocalizedString(@"Show Main Window…",nil)
#define CLOSE		    AILocalizedString(@"Close",nil)
#define HIDE_CONTACT_LIST   AILocalizedString(@"Hide Contact List",nil)

@interface CSSingleWindowInterfacePlugin (PRIVATE)

- (void)_increaseUnviewedContentOfListObject:(AIListObject *)inObject;
- (void)_clearUnviewedContentOfChat:(AIChat *)inChat;

@end

@implementation CSSingleWindowInterfacePlugin

#pragma mark Plugin Setup
- (void)installPlugin
{
	//Register our interface
    [[adium interfaceController] registerInterfaceController:self];
	
	windowController = [[CSSingleWindowInterfaceWindowController singleWindowInterfaceWindowControllerWithInterface:self] retain];
	
	[[adium notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_FirstContentRecieved object:nil];
	
	menuItem_showMainWindow = [[NSMenuItem alloc] initWithTitle:SHOW_MAIN_WINDOW target:self action:@selector(openInterface) keyEquivalent:@"N"];
	[[adium menuController] addMenuItem:menuItem_showMainWindow toLocation:LOC_File_New];
	
	menuItem_close = [[NSMenuItem alloc] initWithTitle:CLOSE target:nil action:@selector(performClose:) keyEquivalent:@"w"];
	[[adium menuController] addMenuItem:menuItem_close toLocation:LOC_File_Close];
	
	menuItem_collapseContactList = [[NSMenuItem alloc] initWithTitle:HIDE_CONTACT_LIST target:windowController action:@selector(collapseContactList:) keyEquivalent:@"/"];
	[[adium menuController] addMenuItem:menuItem_collapseContactList toLocation:LOC_Window_Fixed];
}

- (void)uninstallPlugin
{
	[menuItem_showMainWindow release];
	[windowController release];
	[menuItem_close release];
}

#pragma mark Object Notifications

- (void)didReceiveContent:(NSNotification *)notification
{
    NSDictionary		*userInfo = [notification userInfo];
    AIContentObject		*object;
	
    //Get the content object
    object = [userInfo objectForKey:@"Object"];
	
    //Increase the handle's unviewed count (If it's not the active chat)
    if([object chat] != [windowController activeChat]){
        [self _increaseUnviewedContentOfListObject:[object source]];
    }
}

#pragma mark Interface Protocol
- (void)openInterface
{
	[windowController showWindow:nil];
}

- (void)closeInterface
{
	//[windowController close];
}

- (void)initiateNewMessage
{
}

- (void)openChat:(AIChat *)inChat
{
	NSLog(@"Hit: %@", [inChat participatingListObjects]);
	[windowController addChat:inChat];
}

- (void)closeChat:(AIChat *)inChat
{
	NSLog(@"Close chat: %@", [inChat participatingListObjects]);
	[windowController closeChat:inChat];
	[inChat removeAllContent];
}

- (void)setActiveChat:(AIChat *)inChat
{
	[windowController setChat:inChat];
	[self _clearUnviewedContentOfChat:inChat];
}

- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows
{
	return NO;
}

#pragma mark Private

- (void)_increaseUnviewedContentOfListObject:(AIListObject *)inObject
{
    int			currentUnviewed = [inObject integerStatusObjectForKey:@"UnviewedContent"];

	//'UnviewedContent'++
	[inObject setStatusObject:[NSNumber numberWithInt:(currentUnviewed+1)] forKey:@"UnviewedContent" notify:YES];
}

//Clear unviewed content
- (void)_clearUnviewedContentOfChat:(AIChat *)inChat
{
    NSEnumerator	*enumerator;
    AIListObject	*listObject;
	
    //Clear the unviewed content of each list object participating in this chat
    enumerator = [[inChat participatingListObjects] objectEnumerator];
    while(listObject = [enumerator nextObject]){
		if([listObject integerStatusObjectForKey:@"UnviewedContent"]){
			[listObject setStatusObject:[NSNumber numberWithInt:0] forKey:@"UnviewedContent" notify:YES];
		}
    }
}

@end
