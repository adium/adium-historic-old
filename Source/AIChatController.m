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
#import "AIMenuController.h"
#import "AdiumChatEvents.h"
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIMetaContact.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

@interface AIChatController (PRIVATE)
- (NSSet *)_informObserversOfChatStatusChange:(AIChat *)inChat withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSSet *)inModifiedKeys;
@end

/*!
 * @class AIChatController
 * @brief Core controller for chats
 *
 * This is the only class which should vend AIChat objects (via openChat... or chatWith:...).
 * AIChat objects should never be created directly.
 */
@implementation AIChatController

/*!
 * @brief Initialize the controller
 */
- (id)init
{	
	if ((self = [super init])) {
		mostRecentChat = nil;
		chatObserverArray = [[NSMutableArray alloc] init];
		adiumChatEvents = [[AdiumChatEvents alloc] init];

		//Chat tracking
		openChats = [[NSMutableSet alloc] init];
	}
	
	return self;
}


/*!
 * @brief Controller loaded
 */
- (void)controllerDidLoad
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
	
	//Ignore menu item for contacts in group chats
	menuItem_ignore = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																		   target:self
																		   action:@selector(toggleIgnoreOfContact:)
																	keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_ignore toLocation:Context_Contact_ChatAction];
	
	[adiumChatEvents controllerDidLoad];	
}


/*!
 * @brief Controller will close
 *
 * Post the Chat_WillClose for each open chat so any closing behavior can be performed
 */
- (void)controllerWillClose
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

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[openChats release];
	[chatObserverArray release]; chatObserverArray = nil;

	[super dealloc];
}
	
/*!
 * @brief Register a chat observer
 *
 * Chat observers are notified when status objects are changed on chats
 *
 * @param inObserver An observer, which must conform to AIChatObserver
 */
- (void)registerChatObserver:(id <AIChatObserver>)inObserver
{
	//Add the observer
    [chatObserverArray addObject:[NSValue valueWithNonretainedObject:inObserver]];
	
    //Let the new observer process all existing chats
	[self updateAllChatsForObserver:inObserver];
}

/*!
 * @brief Unregister a chat observer
 */
- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver
{
    [chatObserverArray removeObject:[NSValue valueWithNonretainedObject:inObserver]];
}

/*!
 * @brief Chat status changed
 *
 * Called by AIChat after it changes one or more status keys.
 */
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

/*!
 * @brief Chat attributes changed
 *
 * Called by -[AIChatController chatStatusChanged:modifiedStatusKeys:silent:] if any observers changed attributes
 */
- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSSet *)inModifiedKeys
{
	//Post an attributes changed message
	[[adium notificationCenter] postNotificationName:Chat_AttributesChanged
											  object:inChat
											userInfo:(inModifiedKeys ? [NSDictionary dictionaryWithObject:inModifiedKeys 
																								   forKey:@"Keys"] : nil)];
}

/*!
 * @brief Send each chat in turn to an observer with a nil modifiedStatusKeys argument
 *
 * This lets an observer use its normal update mechanism to update every chat in some manner
 */
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer
{
	NSEnumerator	*enumerator = [openChats objectEnumerator];
	AIChat			*chat;
	
	while ((chat = [enumerator nextObject])) {
		[self chatStatusChanged:chat modifiedStatusKeys:nil silent:NO];
	}
}

/*!
 * @brief Notify observers of a status change.  Returns the modified attribute keys
 */
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
	
	return attrChange;
}

//Chats -------------------------------------------------------------------------------------------------
#pragma mark Chats
/*!
 * @brief Opens a chat for communication with the contact, creating if necessary.
 *
 * The interface controller will then be asked to open the UI for the new chat.
 */
- (AIChat *)openChatWithContact:(AIListContact *)inContact
{
	AIChat	*chat = [self chatWithContact:inContact];

	if (chat) [[adium interfaceController] openChat:chat]; 

	return chat;	
}

/*!
 * @brief Creates a chat for communication with the contact, but does not make the chat active
 *
 * No window or tab is opened for the chat.
 * If a chat with this contact already exists, it is returned.
 * If a chat with a contact within the same metaContact at this contact exists, it is switched to this contact
 * and then returned.
 */
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

	return chat;
}

/*!
 * @brief Return a pre-existing chat with a contact.
 *
 * @result The chat, or nil if no chat with the contact exists
 */
- (AIChat *)existingChatWithContact:(AIListContact *)inContact
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;

	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		//Search for a chat with any contact within this AIMetaContact
		enumerator = [openChats objectEnumerator];
		while ((chat = [enumerator nextObject])) {
			if ([[(AIMetaContact *)inContact containedObjects] containsObjectIdenticalTo:[chat listObject]]) break;
		}

	} else {
		//Search for a chat with this AIListContact
		enumerator = [openChats objectEnumerator];
		while ((chat = [enumerator nextObject])) {
			if ([chat listObject] == inContact) break;
		}
	}
	
	return chat;
}

/*!
 * @brief Open a group chat
 *
 * @param inName The name of the chat; in general, the chat room name
 * @param account The account on which to create the group chat
 * @param chatCreationInfo A dictionary of information which may be used by the account when joining the chat serverside
 */
- (AIChat *)chatWithName:(NSString *)inName onAccount:(AIAccount *)account chatCreationInfo:(NSDictionary *)chatCreationInfo
{
	AIChat			*chat = nil;
	
	//Search for an existing chat we can use instead of creating a new one
	chat = [self existingChatWithName:inName onAccount:account];
	
	if (!chat) {
		//Create a new chat
		chat = [AIChat chatForAccount:account];
		[chat setName:inName];
		[chat setIsGroupChat:YES];
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
	return chat;
}

/*!
 * @brief Find an existing group chat
 *
 * @result The group AIChat, or nil if no such chat exists
 */
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

/*!
 * @brief Find an existing chat by unique chat ID
 *
 * @result The AIChat, or nil if no such chat exists
 */
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

/*!
 * @brief Close a chat
 *
 * @result YES the chat was removed succesfully; NO if it was not
 */
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
	
	[inChat setIsOpen:NO];

	return shouldRemove;
}

/*!
 * @brief Switch a chat from one account to another
 *
 * The target list contact for the chat is changed to be an 'identical' one on the target account; that is, a contact
 * with the same UID but an account and service appropriate for newAccount.
 */
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
			AIListContact	*newContact = [[adium contactController] contactWithService:[newAccount service]
																				account:newAccount
																					UID:[[chat listObject] UID]];
			[chat setListObject:newContact];
		}

		//Open the chat on account B
		[newAccount openChat:chat];
		
		//Clean up
		[chat release];
	}
}

/*!
 * @brief Switch the list contact of a chat
 *
 * @param chat The chat
 * @param inContact The contact with which the chat will now take place
 * @param useContactAccount If YES, the chat is also set to [inContact account] as its account. If NO, the account and service of chat are unchanged.
 */
- (void)switchChat:(AIChat *)chat toListContact:(AIListContact *)inContact usingContactAccount:(BOOL)useContactAccount
{
	AIAccount		*newAccount = (useContactAccount ? [inContact account] : [chat account]);

	//Switch the inContact over to a contact on the new account so we send messages to the right place.
	AIListContact	*newContact = [[adium contactController] contactWithService:[newAccount service]
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

/*!
 * @brief Find all chats with a contact
 *
 * @param inContact The contact. If inContact is an AIMetaContact, all chats with all contacts within the metaContact will be returned.
 * @result An NSSet with all chats with the contact.  In general, will contain 0 or 1 AIChat objects, though it may contain more.
 */
- (NSSet *)allChatsWithContact:(AIListContact *)inContact
{
    NSMutableSet	*foundChats = nil;
	
	//Scan the objects participating in each chat, looking for the requested object
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		if ([openChats count]) {
			NSEnumerator	*enumerator;
			AIListContact	*listContact;

			enumerator = [[(AIMetaContact *)inContact listContacts] objectEnumerator];
			while ((listContact = [enumerator nextObject])) {
				NSSet		*listContactChats;
				if ((listContactChats = [self allChatsWithContact:listContact])) {
					if (!foundChats) foundChats = [NSMutableSet set];
					[foundChats unionSet:listContactChats];
				}
			}
		}
		
	} else {
		NSEnumerator	*enumerator;
		AIChat			*chat;
		
		enumerator = [openChats objectEnumerator];
		while ((chat = [enumerator nextObject])) {
			if (![chat isGroupChat] &&
				[[[chat listObject] internalObjectID] isEqualToString:[inContact internalObjectID]]) {
				if (!foundChats) foundChats = [NSMutableSet set];
				[foundChats addObject:chat];
			}
		}
	}
	
    return foundChats;
}

/*!
 * @brief All open chats
 *
 * Open chats from the chatController may include chats which are not currently displayed by the interface.
 */
- (NSSet *)openChats
{
    return openChats;
}

/*!
 * @brief Find the chat which most recently received content which has not yet been seen
 *
 * @result An AIChat with unviewed content, or nil if no chats current have unviewed content
 */
- (AIChat *)mostRecentUnviewedChat
{
	AIChat  *mostRecentUnviewedChat = nil;
	
	if (mostRecentChat && [mostRecentChat unviewedContentCount]) {
		//First choice: switch to the chat which received chat most recently if it has unviewed content
		mostRecentUnviewedChat = mostRecentChat;
		
	} else {
		//Second choice: switch to the first chat we can find which has unviewed content
		NSEnumerator	*enumerator = [openChats objectEnumerator];
		AIChat			*chat;
		while ((chat = [enumerator nextObject]) && ![chat unviewedContentCount]);
		
		if (chat) mostRecentUnviewedChat = chat;
	}
	
	return mostRecentUnviewedChat;
}

/*!
 * @brief Gets the total number of unviewed messages
 * 
 * @result The number of unviewed messages
 */
- (int) unviewedContentCount
{
	int				count = 0;
	AIChat			*chat;
	NSEnumerator	*enumerator;

	enumerator = [[self openChats] objectEnumerator];
	while ((chat = [enumerator nextObject])) {
		count += [chat unviewedContentCount];
	}
	return count;
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
		if ([chat isGroupChat] &&
			[[chat participatingListObjects] containsObjectIdenticalTo:listContact]) {
			
			contactIsInGroupChat = YES;
			break;
		}
	}
	
	return contactIsInGroupChat;
}

/*!
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

#pragma mark Ignore
/*!
 * @brief Toggle ignoring of a contact
 *
 * Must be called from the contextual menu for the contact within a chat
 */
- (void)toggleIgnoreOfContact:(id)sender
{
	AIListObject	*listObject = [[adium menuController] currentContextMenuObject];
	AIChat			*chat = [[adium menuController] currentContextMenuChat];
	
	if ([listObject isKindOfClass:[AIListContact class]]) {
		BOOL			isIgnored = [chat isListContactIgnored:(AIListContact *)listObject];
		[chat setListContact:(AIListContact *)listObject isIgnored:!isIgnored];
	}
}

/*!
 * @brief Menu item validation
 *
 * When asked to validate our ignore menu item, set its title to ignore/un-ignore as appropriate for the contact
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_ignore) {
		AIListObject	*listObject = [[adium menuController] currentContextMenuObject];
		AIChat			*chat = [[adium menuController] currentContextMenuChat];
		
		if ([listObject isKindOfClass:[AIListContact class]]) {
			if ([chat isListContactIgnored:(AIListContact *)listObject]) {
				[menuItem setTitle:AILocalizedString(@"Un-ignore","Un-ignore means begin receiving messages from this contact again in a chat")];
				
			} else {
				[menuItem setTitle:AILocalizedString(@"Ignore","Ignore means no longer receive messages from this contact in a chat")];
			}
		}
	}
	
	return YES;
}

#pragma mark Chat contact addition and removal

/*!
 * @brief A chat added a listContact to its participatants list
 *
 * @param chat The chat
 * @param inContact The contact
 * @param notify If YES, trigger the contact joined event if this is a group chat.  Ignored if this is not a group chat.
 */
- (void)chat:(AIChat *)chat addedListContact:(AIListContact *)inContact notify:(BOOL)notify
{
	if (notify && [chat isGroupChat]) {
		/* Prevent triggering of the event when we are informed that the chat's own account entered the chat
		 * If the UID of a contact in a chat differs from a normal UID, such as is the case with Jabber where a chat
		 * contact has the form "roomname@conferenceserver/handle" this will fail, but it's better than nothing.
		 */
		if (![[[inContact account] UID] isEqualToString:[inContact UID]]) {
			[adiumChatEvents chat:chat addedListContact:inContact];

			[[adium contentController] displayStatusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ joined the chat",nil),[inContact displayName]]
													 ofType:@"contact_joined"
													 inChat:chat];
		}
	}

	//Always notify Adium that the list changed so it can be updated, caches can be modified, etc.
	[[adium notificationCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
											  object:chat];
}

/*!
 * @brief A chat removed a listContact from its participants list
 *
 * @param chat The chat
 * @param inContact The contact
 */
- (void)chat:(AIChat *)chat removedListContact:(AIListContact *)inContact
{
	if ([chat isGroupChat]) {
		[adiumChatEvents chat:chat removedListContact:inContact];
		
		[[adium contentController] displayStatusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ left the chat.",nil),[inContact displayName]]
												 ofType:@"contact_left"
												 inChat:chat];		
	}

	[[adium notificationCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
											  object:chat];
}

@end
