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
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>

#warning Wrong file location

#define	KEY_CONTAINING_OBJECT_ID	@"ContainingObjectInternalObjectID"
#define	OBJECT_STATUS_CACHE			@"Object Status Cache"

@interface AIListBookmark (PRIVATE)
- (void)restoreGrouping;
@end

@implementation AIListBookmark
- (void)_initListBookmark
{
	[self setVisible:YES];
	[self restoreGrouping];
}

-(id)initWithChat:(AIChat *)inChat
{
	if ((self = [self initWithUID:[NSString stringWithFormat:@"Bookmark:%@",[inChat uniqueChatID]]
						   account:[inChat account]
						   service:[[inChat account] service]])) {
		chatCreationDictionary = [[inChat chatCreationDictionary] copy];
		name = [[inChat name] copy];
		[self _initListBookmark];
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
		[self _initListBookmark];
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

//When called, cache the internalObjectID of the new group so we can restore it immediately next time.
- (void)setContainingObject:(AIListObject <AIContainingObject> *)inGroup
{
	NSString	*inGroupInternalObjectID = [inGroup internalObjectID];
	
	//Save the change of containing object so it can be restored on launch next time if we are using groups.
	//We don't save if we are not using groups as this set will be for the contact list root and probably not desired permanently.
	if ([[adium contactController] useContactListGroups] &&
		inGroupInternalObjectID &&
		![inGroupInternalObjectID isEqualToString:[self preferenceForKey:KEY_CONTAINING_OBJECT_ID
																   group:OBJECT_STATUS_CACHE
												   ignoreInheritedValues:YES]] &&
		(inGroup != [[adium contactController] offlineGroup])) {
		
		[self setPreference:inGroupInternalObjectID
					 forKey:KEY_CONTAINING_OBJECT_ID
					  group:OBJECT_STATUS_CACHE];
	}
	
	[super setContainingObject:inGroup];
}

/*!
 * @brief Restore the AIListGroup grouping into which this object was last manually placed
 */
- (void)restoreGrouping
{
	AIListGroup		*targetGroup = nil;

	if ([[adium contactController] useContactListGroups]) {
		NSString		*oldContainingObjectID;
		AIListObject	*oldContainingObject;

		oldContainingObjectID = [self preferenceForKey:KEY_CONTAINING_OBJECT_ID
												 group:OBJECT_STATUS_CACHE];
		//Get the group's UID out of the internal object ID by taking the substring after "Group."
		oldContainingObject = ((oldContainingObjectID  && [oldContainingObjectID hasPrefix:@"Group."]) ?
							   [[adium contactController] groupWithUID:[oldContainingObjectID substringFromIndex:6]] :
							   nil);

		if (oldContainingObject &&
			[oldContainingObject isKindOfClass:[AIListGroup class]] &&
			oldContainingObject != [[adium contactController] contactList]) {
			//A previous grouping (to a non-root group) is saved; restore it
			targetGroup = (AIListGroup *)oldContainingObject;
		}
	}

	[[adium contactController] _moveContactLocally:self
										   toGroup:(targetGroup ? [[adium contactController] contactList] : nil)];
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
