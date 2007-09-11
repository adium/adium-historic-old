//
//  AIListBookmark.h
//  Adium
//
//  Created by Chloe Haney on 19/07/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AIListContact.h>
#import <AIAccount.h>
#import <AIListGroup.h>
@interface AIListBookmark : AIListContact {
	NSString			*server;
	NSString			*room;
	NSString			*handle;
	NSString			*password;
	NSString			*name;
	NSImage				*userIcon;
	AIListGroup			*group;

}
//display picture
- (NSImage*)userIcon;

//account
- (AIAccount *)account;
- (void)setAccount:(AIAccount *)inAccount;

//chat name
-(void)setName:(NSString*)newName;
- (NSString*)name;

//set server
- (NSString*)server;
-(void)setServer:(NSString*)newServer;

//room
- (NSString*)room;
-(void)setRoom:(NSString*)newRoom;

//handle/nick
- (NSString*)handle;
-(void)setHandle:(NSString*)newHandle;

//containing group
- (AIListGroup*)inGroup;
- (void)setInGroup:(AIListGroup*)newGroup;

//info
- (NSDictionary*)info;


@end
