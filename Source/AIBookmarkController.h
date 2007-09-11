//
//  AIBookmarkController.h
//  Adium
//
//  Created by Erik Beerepoot on 21/07/07.
//  Copyright 2007 Adium. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <AIListGroup.h>
#import <AIListBookmark.h>

@class AISortController;
@interface AIBookmarkController : AIObject {
	//bookmarks
	NSMutableDictionary*				bookmarks;
	
	//contact list & groups
	AIListGroup*						contactList;
	NSMutableDictionary*				groups;
	
	//sorting
	AISortController*					sortController;
	
	//visibility
	BOOL								contactIsVisible;
	
	//save toolbarItem
	NSToolbarItem*						addBookmark;
	
	//past active chat
	AIChat								*activeChat;
	NSMutableArray						*bookmarksForPlist;
}

-(id)init;

//bookmark storage
-(void)loadBookmarks;
-(void)saveBookmark:(NSDictionary*)info;

//visibility of bookmarks
-(BOOL)bookmarkIsVisible:(AIListBookmark*)bookmark;
-(void)setBookmarkIsVisible:(AIListBookmark*)bookmark:(BOOL)visible;

-(void)promptForNewBookmark;
-(BOOL)verifyToolbarButtonForChat:(AIChat*)inChat;

//setting chat info (name,group)
-(void)createBookmarkWithInfo:(NSDictionary*)chatInfo;



@end
