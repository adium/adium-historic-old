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

@implementation CSSingleWindowInterfacePlugin

#pragma mark Plugin Setup
- (void)installPlugin
{
	//Register our interface
    [[adium interfaceController] registerInterfaceController:self];
	
	windowController = [[CSSingleWindowInterfaceWindowController singleWindowInterfaceWindowControllerWithInterface:self] retain];
	
	menuItem_showMainWindow = [[NSMenuItem alloc] initWithTitle:@"Show Main Window…" target:self action:@selector(openInterface) keyEquivalent:@"N"];
	[[adium menuController] addMenuItem:menuItem_showMainWindow toLocation:LOC_File_New];
	
	menuItem_close = [[NSMenuItem alloc] initWithTitle:@"Close" target:nil action:@selector(performClose:) keyEquivalent:@"w"];
	[[adium menuController] addMenuItem:menuItem_close toLocation:LOC_File_Close];
	
	menuItem_collapseContactList = [[NSMenuItem alloc] initWithTitle:@"Hide Contact List" target:windowController action:@selector(collapseContactList:) keyEquivalent:@"/"];
	[[adium menuController] addMenuItem:menuItem_collapseContactList toLocation:LOC_Window_Fixed];
}

- (void)uninstallPlugin
{
	[menuItem_showMainWindow release];
	[windowController release];
	[menuItem_close release];
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
	NSLog(@"Set Active Chat: %@", [inChat participatingListObjects]);
	[windowController setChat:inChat];
}

- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows
{
	return NO;
}

@end
