//
//  AIBookmarkController.m
//  Adium
//
//  Created by Erik Beerepoot on 21/07/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AIBookmarkController.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <AIUtilities/MVMenuButton.h>
#import <AIChat.h>
#import <AIPreferenceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIStandardToolbarItemsPlugin.h"
#import <Adium/AIToolbarControllerProtocol.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <AIListBookmark.h>
#import <AINewBookmarkWindowController.h>

#define BOOKMARKS_KEY					@"bookmarks"			//bookmark save & load key
#define PREF_GROUP_BOOKMARKS			@"Bookmarks"			//Contact list preference group
#define TOOLBAR_ITEM_IDENTIFIER			@"Bookmark Chat"		//bookmark chat item identifier
#define BOOKMARK						@"Bookmark Chat"
#define CONTACT_DEFAULT_PREFS			@"ContactPrefs"

//temp
#define PREF_GROUP_CONTACT_LIST		@"Contact List"
#define KEY_FLAT_METACONTACTS			@"FlatMetaContacts"		//Metacontact objectID storage

#warning This class is incomplete

@implementation AIBookmarkController
-(id)init
{
	if((self = [super init])){
		//init containers
		bookmarks = [[NSMutableDictionary alloc] init];
		//	[self loadBookmarks];
	}
	return self;
}

/* @name	loadBookmarks
 * @brief	Load bookmarks from the preferenceController
 *			with the correct key, store this in the bookmakrs
 *			dictionary
 */
-(void)loadBookmarks
{
	NSLog(@"%@", bookmarks);
	bookmarks = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/bookmarks.plist"];
}

/* @name	saveBookmarks
 * @brief	Save bookmarks for the correct key to the
 *			preference controller, from the bookmarks dictionary.
 */
-(void)saveBookmark:(NSDictionary*)info
{
	bookmarksForPlist = [[NSMutableArray alloc] init];
	[bookmarksForPlist addObject:info];
	NSLog(@"%d",[bookmarksForPlist writeToFile:@"/Documents/bookmarks.plist" atomically:YES]);
}


/* @name	contactIsVisible
 * @param	bookmark - An AIListBookmark; the bookmark of which the visibility
 *			status has to be determined
 * @brief	This method returns a BOOLEAN value which represents the visiblity 
 *			status of the bookmark. 
 *			YES - Visible
 *			NO	- Not Visible
 *			default is visible.
 */
 
-(BOOL)bookmarkIsVisible:(AIListBookmark*)bookmark
{
	return contactIsVisible;
}

/* @name deallc
 * @brief deallocation of objects
 */
-(void)dealloc
{
	[super dealloc];
}

/* @name	setBookmarkIsVisible
 * @param	bookmark	- the bookmark whose visibilty status will be changed 
 * 			visible		- the BOOLEAN value representing the visiblity status (YES - Visible, NO - not visible)
 * @brief	accessor method to set the visiblity status for a given bookmark
 */
-(void)setBookmarkIsVisible:(AIListBookmark*)bookmark:(BOOL)visible
{
}

/* @name	addBookmark
 * @brief	This method bookmarks the currently active chat.
 *			the bookmark will be added to the contact list.
 */  
-(void)promptForNewBookmark
{	
	//save active chat
	activeChat = [[adium interfaceController] activeChat];

	//prompt user for alias & group name
	AINewBookmarkWindowController *newBookmarkController = [AINewBookmarkWindowController promptForNewBookmarkOnWindow:nil];
	[newBookmarkController setDelegate:self];

}



/* @name  createBookmarkWithInfo
 * @param (NSDictionary*)chatInfo - dictionary with info about the chat, such as the servername, room, & handle.
 * @brief Creates a new bookmark with info from the chat which the user wants to bookmark. (which is not the active chat)
 * adds this bookmark to the userlist & notifies observers that the contaclist has changed. In addition, this method
 * saves the bookmark in an array which is then saved by calling saveBookmarks:
 */
 
-(void)createBookmarkWithInfo:(NSDictionary*)chatInfo
{
	NSLog(@"active chat: %@", activeChat);
	NSString* bookmarkName = [chatInfo objectForKey:@"bookmark name"];
	AIListGroup *bookmarkGroup = [chatInfo objectForKey:@"bookmark group"];
	
	//get chat information
	AIAccount	*account = [activeChat account];
	AIService	*service = [account service];


	
	/*! create a bookmark
	 * NOTE: Since the UID is generated using the bookmarkName, this could turn out to be a problem when 
	 * a user uses the same name for multiple bookmarks. 
	 */
	AIListBookmark *bookmark = [[AIListBookmark alloc] initWithUID:bookmarkName account:account service:service];
	
	//set bookmark properties
	[bookmark setAccount:[activeChat account]];
	[bookmark setServer:[activeChat server]];
	[bookmark setRoom:[activeChat room]];
	[bookmark setHandle:[activeChat handle]];
	[bookmark setName:[activeChat name]];
	[bookmark setGroup:bookmarkGroup];
	//add the bookmark to the contact list
	contactList = [[adium contactController] contactList];
	[contactList addObject:bookmark];
	
	//set UI data
	[bookmark setVisible:YES];
	
	//move bookmark to the desired group
	[[adium contactController] addContacts:[NSArray arrayWithObjects:bookmark,nil] toGroup:bookmarkGroup];
	
	//notify observers that the contact list has changed
	[[adium notificationCenter] postNotificationName:Contact_ListChanged
											  object:bookmark
											userInfo:(contactList ? [NSDictionary dictionaryWithObject:contactList forKey:@"ContainingGroup"] : nil)];
	
	[bookmark setIdle:YES sinceDate:[NSDate date] notify:NotifyNow];


	//save bookmark
	NSLog(@"info: %@", [bookmark info]);
	[self saveBookmark:[bookmark info]];
}


@end
