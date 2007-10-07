//
//  AIListBookmark.m
//  Adium
//
//  Created by Erik Beerepoot on 19/07/07.
//  Copyright 2007 Adium Team. All rights reserved.
//

#import "AIListBookmark.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>

#warning Wrong file location

@implementation AIListBookmark
-(id)initWithChat:(AIChat *)inChat
{
	if ((self = [self initWithUID:[NSString stringWithFormat:@"Bookmark:%@",[inChat uniqueChatID]]
						   account:[inChat account]
						   service:[[inChat account] service]])) {
		chatCreationDictionary = [[inChat chatCreationDictionary] copy];
		name = [[inChat name] copy];
		AILog(@"Created AIListBookmark %@", self);
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [self initWithUID:[decoder decodeObjectForKey:@"UID"]
						  account:[[adium accountController] accountWithInternalObjectID:[decoder decodeObjectForKey:@"AccountInternalObjectID"]]
						  service:[[adium accountController] firstServiceWithServiceID:[decoder decodeObjectForKey:@"ServiceID"]]])) {
		chatCreationDictionary = [[decoder decodeObjectForKey:@"chatCreationDictionary"] retain];
		name = [[decoder decodeObjectForKey:@"name"] retain];

		AILog(@"Created AIListBookmark from coder with dict %@",chatCreationDictionary);
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[self UID] forKey:@"UID"];
	[encoder encodeObject:[[self account] internalObjectID] forKey:@"AccountInternalObjectID"];
	[encoder encodeObject:[[self service] serviceID] forKey:@"ServiceID"];
	[encoder encodeObject:[self chatCreationDictionary] forKey:@"chatCreationDictionary"];
	[encoder encodeObject:name forKey:@"name"];
}

- (NSString *)formattedUID
{
	//XXX should query chat for its name if we're in it
	return name;
}

- (NSDictionary *)chatCreationDictionary
{
	return chatCreationDictionary;
}

- (NSString *)name
{
	return name;
}

//XXX how to handle passwords
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

- (NSImage *)userIcon
{
	NSLog(@"returning %@, ", [super userIcon]);
	return [super userIcon];
}
//Only visible if our account is online
- (BOOL)visible
{
	return ([super visible] && [[self account] online]);
}

- (BOOL)online
{
	return [[self account] online];
}

- (void)openChat
{
	AIChat *chat = [[adium chatController] existingChatWithName:[self name]
													  onAccount:[self account]];
	if (chat && [[chat chatCreationDictionary] isEqualToDictionary:
				 [self chatCreationDictionary]]) {
		//An existing open chat matches this bookmark. Switch to it!
		[[adium interfaceController] setActiveChat:chat];
		
	} else {
		//Open a new group chat (bookmarked chat)
		[[adium chatController] chatWithName:[self name]
								  identifier:NULL 
								   onAccount:[self account] 
							chatCreationInfo:[self chatCreationDictionary]];
	}	
}	

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%x %@ - %@>",NSStringFromClass([self class]), self, [self formattedUID], [self chatCreationDictionary]];
}

@end
