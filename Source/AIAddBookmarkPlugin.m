//
//  AIAddBookmarkPlugin.m
//  Adium
//
//  Created by Erik Beerepoot on 30/07/07.
//  Copyright 2007 Adium. Licensed under the GNU GPL.
//

#import "AIAddBookmarkPlugin.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>

#define TOOLBAR_ITEM_IDENTIFIER		@"AddBookmark"
#define ADD_BOOKMARK				@"Add Bookmark"

@implementation AIAddBookmarkPlugin
/*!
 * @name installPlugin
 * @brief initializes the plugin - installs toolbaritem
 */
-(void)installPlugin
{
	bookmarkController = [[AIBookmarkController alloc] init];
	[self setDelegate:bookmarkController];
	
	NSToolbarItem	*chatItem = [AIToolbarUtilities toolbarItemWithIdentifier:TOOLBAR_ITEM_IDENTIFIER
																		  label:ADD_BOOKMARK
																   paletteLabel:ADD_BOOKMARK
																		toolTip:@"Bookmark the current chat"
																  		 target:self
																settingSelector:@selector(setImage:)
																	itemContent:[NSImage imageNamed:@"AddressBook" forClass:[self class]]
																		action:@selector(addBookmark:)
																		  menu:nil];
	
	[[adium toolbarController] registerToolbarItem:chatItem forToolbarType:@"MessageWindow"];
	
}
/*!
 * @name dealloc
 * @brief cleanup
 */
-(void)dealloc
{
	[bookmarkController release];
	[super dealloc];
}


-(void)uninstallPlugin
{
}

/*!
 * @name addBookmark
 * @brief ask delegate to prompt the user with a create bookmark window
 */
-(void)addBookmark:(id)sender
{
	[delegate promptForNewBookmark];
}

/*!
 * @name setDelegate
 * @brief sets delegate object
 */

-(void)setDelegate:(id)newDelegate
{
	if(newDelegate != delegate)
	{
		[delegate release];
		delegate = [newDelegate retain];
	}
}

/*! 
 * @name delegate
 * @brief returns delegate object
 */
-(id)delegate
{
	return delegate;
}
	

@end
