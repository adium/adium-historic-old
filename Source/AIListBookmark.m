//
//  AIListBookmark.m
//  Adium
//
//  Created by Erik Beerepoot on 19/07/07.
//  Copyright 2007 Adium Team. All rights reserved.
//

#import "AIListBookmark.h"
#import <Adium/AIUserIcons.h>
#import <AIService.h>

#warning Wrong file location

@implementation AIListBookmark
-(id)init
{
	if((self = [super init])) {
		account = [[AIAccount alloc] init];
		handle = [[NSString alloc] init];
	}
	return self;
}
-(NSString*)name
{
	return name;
}

-(void)setName:(NSString*)newName
{
	if(name != newName) {
		[name release];
		name = [newName retain];
	}
}

- (AIAccount *)account
{
    return account;
}

- (void)setAccount:(AIAccount *)inAccount
{
	if (inAccount != account) {
		[account release];
		account = [inAccount retain];
		
	}
}

//Associated Server
- (NSString*)server
{
	return server;
}

-(void)setServer:(NSString*)newServer
{
	if(server != newServer) {
		[server release];
		server = [newServer retain];
	}
}

//Associated Server
- (NSString*)room
{
	return room;
}

-(void)setRoom:(NSString*)newRoom
{
	if(room != newRoom) {
		[room release];
		room = [newRoom retain];
	}
}

//Associated Server
- (NSString*)handle
{
	return handle;
}

-(void)setHandle:(NSString*)newHandle
{
	if(handle != newHandle) {
		[handle release];
		handle = [newHandle retain];
	}
}


//the password associated with this contact
-(NSString*)password
{
	return password;
}

-(void)setPassword:(NSString*)newPassword
{
	if(password != newPassword) {
		[password release];
		password = [newPassword retain];
	}
}
- (NSImage*)userIcon
{
	return [NSImage imageNamed:@"AddressBook"];
}

- (AIListGroup*)inGroup
{
	return group;
}

- (void)setInGroup:(AIListGroup*)newGroup
{
	if(newGroup != group) {
		[group release];
		group = [newGroup retain];
		}
}

-(NSDictionary*)info
{
	NSLog(@"handle: %@ server: %@ group: %@ account: %@ room: %@",handle, server,group, account,room);
	return [NSDictionary dictionaryWithObjectsAndKeys:handle,@"handle",server,@"server",group,@"group",account,@"account",room,@"room"];
}


@end
