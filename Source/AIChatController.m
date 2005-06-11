//
//  AIChatController.m
//  Adium
//
//  Created by Evan Schoenberg on 6/10/05.
//

#import "AIChatController.h"
#import "AIContentController.h"
#import "AIContactController.h"
#import "AIInterfaceController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIMetaContact.h>
#import <AIUtilities/AIArrayAdditions.h>

@interface AIChatController (PRIVATE)
- (NSSet *)_informObserversOfChatStatusChange:(AIChat *)inChat withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSSet *)inModifiedKeys;
@end

@implementation AIChatController

/*
 * @brief Initialize the controller
 */
- (id)init
{	
	if ((self = [super init])) {
		mostRecentChat = nil;
		chatObserverArray = [[NSMutableArray alloc] init];
		
		//Chat tracking
		openChats = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (void)finishIniting
{	
	//Observe content so we can update the most recent chat
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(didExchangeContent:) 
									   name:CONTENT_MESSAGE_RECEIVED
									 object:nil];
	
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(didExchangeContent:) 
									   name:CONTENT_MESSAGE_SENT
									 object:nil];		
}

- (void)beginClosing
{
	NSEnumerator	*enumerator = [openChats objectEnumerator];
	AIChat			*chat;
	
	//Every open chat is about to close.
	while ((chat = [enumerator nextObject])) {
		[[adium notificationCenter] postNotificationName:Chat_WillClose 
												  object:chat
												userInfo:nil];
	}
}

- (void)closeController
{
}

- (void)dealloc
{
	[openChats release];
	[chatObserverArray release]; chatObserverArray = nil;

	[super dealloc];
}
	
//Registers code to observe handle status changes
- (void)registerChatObserver:(id <AIChatObserver>)inObserver
{
	//Add the observer
    [chatObserverArray addObject:[NSValue valueWithNonretainedObject:inObserver]];
	
    //Let the new observer process all existing chats
	[self updateAllChatsForObserver:inObserver];
}

- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver
{
    [chatObserverArray removeObject:[NSValue valueWithNonretainedObject:inObserver]];
}

- (void)chatStatusChanged:(AIChat *)inChat modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet			*modifiedAttributeKeys;
	
    //Let all observers know the contact's status has changed before performing any further notifications
	modifiedAttributeKeys = [self _informObserversOfChatStatusChange:inChat withKeys:inModifiedKeys silent:silent];
	
    //Post an attributes changed message (if necessary)
    if ([modifiedAttributeKeys count]) {
		[self chatAttributesChanged:inChat modifiedKeys:modifiedAttributeKeys];
    }	
}

- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSSet *)inModifiedKeys
{
	//Post an attributes changed message
	[[adium notificationCenter] postNotificationName:Chat_AttributesChanged
											  object:inChat
											userInfo:(inModifiedKeys ? [NSDictionary dictionaryWithObject:inModifiedKeys 
																								   forKey:@"Keys"] : nil)];
}

//Send a chatStatusChanged message for each open chat with a nil modifiedStatusKeys array
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer
{
	NSEnumerator	*enumerator = [openChats objectEnumerator];
	AIChat			*chat;
	
	while ((chat = [enumerator nextObject])) {
		[self chatStatusChanged:chat modifiedStatusKeys:nil silent:NO];
	}
}

//Notify observers of a status change.  Returns the modified attribute keys
- (NSSet *)_informObserversOfChatStatusChange:(AIChat *)inChat withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent
{
	NSMutableSet	*attrChange = nil;
	NSEnumerator	*enumerator;
	NSValue			*observerValue;
	
	//Let our observers know
	enumerator = [chatObserverArray objectEnumerator];
	while ((observerValue = [enumerator nextObject])) {
		id <AIChatObserver>	observer;
		NSSet				*newKeys;
		
		observer = [observerValue nonretainedObjectValue];
		if ((newKeys = [observer updateChat:inChat keys:modifiedKeys silent:silent])) {
			if (!attrChange) attrChange = [NSMutableSet set];
			[attrChange unionSet:newKeys];
		}
	}
	
	//Send out the notification for other observers
	[[adium notificationCenter] postNotificationName:Chat_StatusChanged
											  object:inChat
											userInfo:(modifiedKeys ? [NSDictionary dictionaryWithObject:modifiedKeys 
																								 forKey:@"Keys"] : nil)];
	
	return(attrChange);
}

//Increase unviewed content
- (void)increaseUnviewedContentOfChat:(AIChat *)inChat
{
	int currentUnviewed = [inChat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT];
	[inChat setStatusObject:[NSNumber numberWithInt:(currentUnviewed+1)]
					 forKey:KEY_UNVIEWED_CONTENT
					 notify:YES];
}

//Clear unviewed content
- (void)clearUnviewedContentOfChat:(AIChat *)inChat
{
	[inChat setStatusObject:nil forKey:KEY_UNVIEWED_CONTENT notify:YES];
}

//Chats -------------------------------------------------------------------------------------------------
#pragma mark Chats
//Opens a chat for communication with the contact, creating if necessary.  The new chat will be made active.
- (AIChat *)openChatWithContact:(AIListContact *)inContact
{
	AIChat	*chat = [self chatWithContact:inContact];

	if (chat) [[adium interfaceController] openChat:chat]; 

	return(chat);	
}

//Creates a chat for communication with the contact, but does not make the chat active (Doesn't open a chat window)
//If a chat already exists it will be returned
- (AIChat *)chatWithContact:(AIListContact *)inContact
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	AIListContact	*targetContact = inContact;
		
	/*
	 If we're dealing with a meta contact, open a chat with the preferred contact for this meta contact
	 It's a good idea for the caller to pick the preferred contact for us, since they know the content type
	 being sent and more information - but we'll do it here as well just to be safe.
	 */
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		targetContact = [[adium contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
																   forListContact:inContact];
		
		/*
		 If we have no accounts online, preferredContactForContentType:forListContact will return nil.
		 We'd rather open up the chat window on a useless contact than do nothing, so just pick the 
		 preferredContact from the metaContact.
		 */
		if (!targetContact) {
			targetContact = [(AIMetaContact *)inContact preferredContact];
		}
	}
	
	//If we can't get a contact, we're not going to be able to get a chat... return nil
	if (!targetContact) return nil;
	
	//Search for an existing chat we can switch instead of replacing
	enumerator = [openChats objectEnumerator];
	while ((chat = [enumerator nextObject])) {
		//If a chat for this object already exists
		if ([[chat uniqueChatID] isEqualToString:[targetContact internalObjectID]]) {
			if (!([chat listObject] == targetContact)) {
				[self switchChat:chat toAccount:[targetContact account]];
			}
			
			break;
		}
		
		//If this object is within a meta contact, and a chat for an object in that meta contact already exists
		if ([[targetContact containingObject] isKindOfClass:[AIMetaContact class]] && 
		   [[chat listObject] containingObject] == [targetContact containingObject]) {

			//Switch the chat to be on this contact (and its account) now
			[self switchChat:chat toListContact:targetContact usingContactAccount:YES];
			
			break;
		}
	}

	if (!chat) {
		AIAccount	*account;
		account = [targetContact account];
		
		//Create a new chat
		chat = [AIChat chatForAccount:account];
		[chat addParticipatingListObject:targetContact];
		[openChats addObject:chat];
		AILog(@"chatWithContact: Added <<%@>> [%@]",chat,openChats);

		//Inform the account of its creation and post a notification if successful
		if ([[targetContact account] openChat:chat]) {
			[[adium notificationCenter] postNotificationName:Chat_Created object:chat userInfo:nil];
		} else {
			[openChats removeObject:chat];
			AILog(@"chatWithContact: Immediately removed <<%@>> [%@]",chat,openChats);
			chat = nil;
		}
	}

	return(chat);
}

- (AIChat *)existingChatWithContact:(AIListContact *)inContact
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	AIListContact	*targetContact = inContact;
	
	/*
	 If we're dealing with a meta contact, open a chat with the preferred contact for this meta contact
	 It's a good idea for the caller to pick the preferred contact for us, since they know the content type
	 being sent and more information - but we'll do it here as well just to be safe.
	 */
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		targetContact = [[adium contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
															   forListContact:inContact];
		
		/*
		 If we have no accounts online, preferredContactForContentType:forListContact will return nil.
		 We'd rather open up the chat window on a useless contact than do nothing, so just pick the 
		 preferredContact from the metaContact.
		 */
		if (!targetContact) {
			targetContact = [(AIMetaContact *)inContact preferredContact];
		}
	}
	
	//Search for an existing chat
	enumerator = [openChats objectEnumerator];
	while ((chat = [enumerator nextObject])) {
		//If a chat for this object already exists
		if ([chat listObject] == targetContact) break;
	}
	
	return(chat);
}

- (AIChat *)chatWithName:(NSString *)inName onAccount:(AIAccount *)account chatCreationInfo:(NSDictionary *)chatCreationInfo
{
	AIChat			*chat = nil;
	
	//Search for an existing chat we can use instead of creating a new one
	chat = [self existingChatWithName:inName onAccount:account];
	
	if (!chat) {
		//Create a new chat
		chat = [AIChat chatForAccount:account];
		[chat setName:inName];
		[openChats addObject:chat];
		AILog(@"chatWithName:%@ onAccount:%@ added <<%@>> [%@]",inName,account,chat,openChats);
		
		if (chatCreationInfo) [chat setStatusObject:chatCreationInfo
											 forKey:@"ChatCreationInfo"
											 notify:NotifyNever];
		
		[chat setStatusObject:[NSNumber numberWithBool:YES]
					   forKey:@"AlwaysShowUserList"
					   notify:NotifyNever];
		
		//Inform the account of its creation and post a notification if successful
		if ([account openChat:chat]) {
			[[adium notificationCenter] postNotificationName:Chat_Created object:chat userInfo:nil];
		} else {
			[openChats removeObject:chat];
			AILog(@"chatWithName: Immediately removed <<%@>> [%@]",chat,openChats);
			chat = nil;
		}
	}
	return(chat);
}

- (void)openChat:(AIChat *)chat
{
	if (chat) {		
		[openChats addObject:chat];
		AILog(@"openChat: Added <<%@>> [%@]",chat,openChats);
		[[adium interfaceController] openChat:chat]; 
	}
}

- (AIChat *)existingChatWithName:(NSString *)inName onAccount:(AIAccount *)account
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	
	enumerator = [openChats objectEnumerator];

	while ((chat = [enumerator nextObject])) {
		if (([chat account] == account) &&
		   ([[chat name] isEqualToString:inName])) {
			break;
		}
	}	
	
	return chat;
}

- (AIChat *)existingChatWithUniqueChatID:(NSString *)uniqueChatID
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	
	enumerator = [openChats objectEnumerator];
	
	while ((chat = [enumerator nextObject])) {
		if ([[chat uniqueChatID] isEqualToString:uniqueChatID]) {
			break;
		}
	}	
	
	return chat;
}

//Close a chat
- (BOOL)closeChat:(AIChat *)inChat
{	
	BOOL	shouldRemove;
	
	/* If we are currently passing a content object for this chat through our content filters, don't remove it from
	 * our openChats set as it will become needed soon. If we were to remove it, and a second message came in which was
	 * also before the first message is done filtering, we would otherwise mistakenly think we needed to create a new
	 * chat, generating a duplicate.
	 */
	shouldRemove = ![[adium contentController] chatIsReceivingContent:inChat];

	if (mostRecentChat == inChat) {
		[mostRecentChat release];
		mostRecentChat = nil;
	}
	
	//Notify the account and send out the Chat_WillClose notification
	[[inChat account] closeChat:inChat];
	[[adium notificationCenter] postNotificationName:Chat_WillClose object:inChat userInfo:nil];
	
	//Remove the chat's content (it retains the chat, so this must be done separately)
	[inChat removeAllContent];

	//Remove the chat
	if (shouldRemove) {
		[openChats removeObject:inChat];
		AILog(@"closeChat: Removed <<%@>> [%@]",inChat, openChats);
	}

	return YES;
}

//Switch a chat from one account to another, updating the target list contact to be an 'identical' one on the target account.
- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount
{
	AIAccount	*oldAccount = [chat account];
	if (newAccount != oldAccount) {
		//Hang onto stuff until we're done
		[chat retain];

		//Close down the chat on account A
		[oldAccount closeChat:chat];

		//Set the account and the listObject
		{
			[chat setAccount:newAccount];
			
			//We want to keep the same destination for the chat but switch it to a listContact on the desired account.
			AIListContact	*newContact = [[adium contactController] contactWithService:[[chat listObject] service]
																				account:[chat account]
																					UID:[[chat listObject] UID]];
			[chat setListObject:newContact];
		}
		
		//Open the chat on account B
		[newAccount openChat:chat];
		
		//Clean up
		[chat release];
	}
}

//Switch the list contact of the account; this does not change the source account - use switchChat:toAccount: for that.
- (void)switchChat:(AIChat *)chat toListContact:(AIListContact *)inContact usingContactAccount:(BOOL)useContactAccount
{
	AIAccount		*newAccount = (useContactAccount ? [inContact account] : [chat account]);
	
	//Switch the inContact over to a contact on the new account so we send messages to the right place.
	AIListContact	*newContact = [[adium contactController] contactWithService:[inContact service]
																		account:newAccount
																			UID:[inContact UID]];
	if (newContact != [chat listObject]) {
		//Hang onto stuff until we're done
		[chat retain];
		
		//Close down the chat on the account, as the account may need to perform actions such as closing a connection
		[[chat account] closeChat:chat];
		
		//Set to the new listContact and account as needed
		[chat setListObject:newContact];
		if (useContactAccount) [chat setAccount:newAccount];

		//Reopen the chat on the account
		[[chat account] openChat:chat];
		
		//Clean up
		[chat release];
	}
}

//Returns all chats with the object
- (NSSet *)allChatsWithContact:(AIListContact *)inContact
{
    NSMutableSet	*foundChats = nil;
	
	//Scan the objects participating in each chat, looking for the requested object
	if ([inContact isKindOfClass:[AIMetaContact class]]) {

		NSEnumerator	*enumerator;
		AIListContact	*listContact;

		foundChats = [NSMutableSet set];
		
		enumerator = [[(AIMetaContact *)inContact listContacts] objectEnumerator];
		while ((listContact = [enumerator nextObject])) {
			NSSet		*listContactChats;
			if ((listContactChats = [self allChatsWithContact:listContact])) {
				[foundChats unionSet:listContactChats];
			}
		}
		
	} else {
		NSEnumerator	*chatEnumerator = [openChats objectEnumerator];
		AIChat			*chat;
		while ((chat = [chatEnumerator nextObject])) {
			if (![chat name] &&
				[[[chat listObject] internalObjectID] isEqualToString:[inContact internalObjectID]]) {
				if (!foundChats) foundChats = [NSMutableSet set];
				[foundChats addObject:chat];
			}
		}
	}
	
    return(foundChats);
}

- (NSSet *)openChats
{
    return openChats;
}

- (AIChat *)mostRecentUnviewedChat
{
	AIChat  *mostRecentUnviewedChat = nil;
	
	if (mostRecentChat && [mostRecentChat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]) {
		//First choice: switch to the chat which received chat most recently if it has unviewed content
		mostRecentUnviewedChat = mostRecentChat;
		
	} else {
		//Second choice: switch to the first chat we can find which has unviewed content
		NSEnumerator	*enumerator = [openChats objectEnumerator];
		AIChat			*chat;
		while ((chat = [enumerator nextObject]) && ![chat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]);
		
		if (chat) mostRecentUnviewedChat = chat;
	}
	
	return mostRecentUnviewedChat;
}

/*!
* @brief Is the passed contact in a group chat?
 *
 * @result YES if the contact is in an open group chat; NO if not.
 */
- (BOOL)contactIsInGroupChat:(AIListContact *)listContact
{
	NSEnumerator	*chatEnumerator = [openChats objectEnumerator];
	AIChat			*chat;
	BOOL			contactIsInGroupChat = NO;
	
	while ((chat = [chatEnumerator nextObject])) {
		if ([chat name] &&
			[[chat participatingListObjects] containsObjectIdenticalTo:listContact]) {
			
			contactIsInGroupChat = YES;
			break;
		}
	}
	
	return contactIsInGroupChat;
}

/*
 * @brief Called when content is sent or received
 *
 * Update the most recent chat
 */
- (void)didExchangeContent:(NSNotification *)notification
{
	AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"AIContentObject"];

	//Update our most recent chat
	if ([contentObject trackContent]) {
		AIChat	*chat = [contentObject chat];
		
		if (chat != mostRecentChat) {
			[mostRecentChat release];
			mostRecentChat = [chat retain];
		}
	}	
}

@end
