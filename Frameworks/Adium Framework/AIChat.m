/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIAccount.h"
#import "AIChat.h"
#import "AIContentMessage.h"
#import "AIListContact.h"
#import "ESFileTransfer.h"
#import "AIHTMLDecoder.h"
#import "AIServiceIcons.h"
#import "AIUserIcons.h"

#import "AIContactController.h"
#import "AIContentController.h"
#import "AIChatController.h"
#import "AIPreferenceController.h"

#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>

@interface AIChat (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount;
- (void)clearUniqueChatID;
- (void)clearListObjectStatuses;
@end

@implementation AIChat

static int nextChatNumber = 0;

+ (id)chatForAccount:(AIAccount *)inAccount
{
    return [[[self alloc] initForAccount:inAccount] autorelease];
}

- (id)initForAccount:(AIAccount *)inAccount
{
    if ((self = [super init])) {
		name = nil;
		account = [inAccount retain];
		participatingListObjects = [[NSMutableArray alloc] init];
		dateOpened = [[NSDate date] retain];
		uniqueChatID = nil;
		ignoredListContacts = nil;
		isOpen = NO;
		isGroupChat = NO;
		expanded = YES;
		customEmoticons = nil;
		hasSentOrReceivedContent = NO;

		pendingOutgoingContentObjects = [[NSMutableArray alloc] init];
		
		contentObjectArray = [[NSMutableArray alloc] init];

		AILog(@"[AIChat: %x initForAccount]",self);
	}

    return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	AILog(@"[%@ dealloc]",self);

	[account release];
	[participatingListObjects release];
	[dateOpened release];
	[ignoredListContacts release];
	[pendingOutgoingContentObjects release];
	[uniqueChatID release]; uniqueChatID = nil;
	[customEmoticons release]; customEmoticons = nil;

	[contentObjectArray release]; contentObjectArray = nil;

	[super dealloc];
}

//Big image
- (NSImage *)chatImage
{
	AIListObject 	*listObject = [self listObject];
	NSImage			*image = nil;
	
	if (listObject) {
		image = [listObject userIcon];
		if (!image) image = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconLarge direction:AIIconNormal];
	}

	return image;
}

//lil image
- (NSImage *)chatMenuImage
{
	AIListObject 	*listObject;
	NSImage			*chatMenuImage = nil;
	
	if ((listObject = [self listObject])) {
		chatMenuImage = [AIUserIcons menuUserIconForObject:listObject];
	}

	return chatMenuImage;
}


//Associated Account ---------------------------------------------------------------------------------------------------
#pragma mark Associated Account
- (AIAccount *)account
{
    return account;
}

- (void)setAccount:(AIAccount *)inAccount
{
	if (inAccount != account) {
		[account release];
		account = [inAccount retain];
		
		//The uniqueChatID may depend upon the account, so clear it
		[self clearUniqueChatID];
		[[adium notificationCenter] postNotificationName:Chat_SourceChanged object:self]; //Notify
	}
}

//Date Opened
#pragma mark Date Opened
- (NSDate *)dateOpened
{
	return dateOpened;
}

- (void)setDateOpened:(NSDate *)inDate
{
	if (dateOpened != inDate) {
	   [dateOpened release]; 
	   dateOpened = [inDate retain];
    }
}

- (BOOL)isOpen
{
	return isOpen;
}
- (void)setIsOpen:(BOOL)flag
{
	isOpen = flag;
}

- (BOOL)hasSentOrReceivedContent
{
	return hasSentOrReceivedContent;
}
- (void)setHasSentOrReceivedContent:(BOOL)flag
{
	hasSentOrReceivedContent = flag;
}

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Status
- (void)didModifyStatusKeys:(NSSet *)keys silent:(BOOL)silent
{
	[[adium chatController] chatStatusChanged:self
						   modifiedStatusKeys:keys
									   silent:silent];	
}

- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	//If our unviewed content changes or typing status changes, and we have a single list object, 
	//apply the change to that object as well so it can be cleanly reflected in the contact list.
	if ([key isEqualToString:KEY_UNVIEWED_CONTENT] ||
		[key isEqualToString:KEY_TYPING]) {
		AIListObject	*listObject = [self listObject];
		
		if (listObject) [listObject setStatusObject:value forKey:key notify:notify];
	}
	
	[super object:inObject didSetStatusObject:value forKey:key notify:notify];
}

- (void)clearListObjectStatuses
{
	AIListObject	*listObject = [self listObject];
	
	if (listObject) {
		[listObject setStatusObject:nil forKey:KEY_UNVIEWED_CONTENT notify:NotifyLater];
		[listObject setStatusObject:nil forKey:KEY_TYPING notify:NotifyLater];
	
		[listObject notifyOfChangedStatusSilently:NO];
	}
	
}
//Secure chatting ------------------------------------------------------------------------------------------------------
- (void)setSecurityDetails:(NSDictionary *)securityDetails
{
	[self setStatusObject:securityDetails
				   forKey:@"SecurityDetails"
				   notify:NotifyNow];
}
- (NSDictionary *)securityDetails
{
	return [self statusObjectForKey:@"SecurityDetails"];
}

- (BOOL)isSecure
{
	AIEncryptionStatus encryptionStatus = [self encryptionStatus];
	
	return (encryptionStatus != EncryptionStatus_None);
}

- (AIEncryptionStatus)encryptionStatus
{
	AIEncryptionStatus	encryptionStatus = EncryptionStatus_None;

	NSDictionary		*securityDetails = [self securityDetails];
	if (securityDetails) {
		NSNumber *detailsStatus;
		if ((detailsStatus = [securityDetails objectForKey:@"EncryptionStatus"])) {
			encryptionStatus = [detailsStatus intValue];
			
		} else {
			/* If we don't have a specific encryption status, but do have security details, assume
			 * encrypted and verified.
			 */
			encryptionStatus = EncryptionStatus_Verified;
		}
	}

	return encryptionStatus;
}

- (BOOL)supportsSecureMessagingToggling
{
	return (BOOL)[account allowSecureMessagingTogglingForChat:self];
}

//Name  ----------------------------------------------------------------------------------------------------------------
#pragma mark Name
- (NSString *)name
{
	return name;
}
- (void)setName:(NSString *)inName
{
	[name release]; name = [inName retain]; 
}

- (NSString *)displayName
{
    NSString	*outName = [self displayArrayObjectForKey:@"Display Name"];
    return outName ? outName : (name ? name : [[self listObject] displayName]);
}

- (void)setDisplayName:(NSString *)inDisplayName
{
	[[self displayArrayForKey:@"Display Name"] setObject:inDisplayName
											   withOwner:self];
}

//Participating ListObjects --------------------------------------------------------------------------------------------
#pragma mark Participating ListObjects
- (NSArray *)participatingListObjects
{
    return participatingListObjects;
}

- (void)addParticipatingListObject:(AIListContact *)inObject notify:(BOOL)notify
{
	if (![participatingListObjects containsObjectIdenticalTo:inObject]) {
		//Add
		[participatingListObjects addObject:inObject];

		[[adium chatController] chat:self addedListContact:inObject notify:notify];
	}
}
- (void)addParticipatingListObject:(AIListContact *)inObject
{
	[self addParticipatingListObject:inObject notify:YES];
}

// Invite a list object to join the chat. Returns YES if the chat joins, NO otherwise
- (BOOL)inviteListContact:(AIListContact *)inContact withMessage:(NSString *)inviteMessage
{
	return ([[self account] inviteContact:inContact toChat:self withMessage:inviteMessage]);
}

//
- (void)removeParticipatingListObject:(AIListContact *)inObject
{
	if ([participatingListObjects containsObjectIdenticalTo:inObject]) {
		//Remove
		[participatingListObjects removeObject:inObject];
		
		[[adium chatController] chat:self removedListContact:inObject];
	}
}

- (void)setPreferredListObject:(AIListContact *)inObject
{
	preferredListObject = inObject;
}

- (AIListContact *)preferredListObject
{
	return preferredListObject;
}

//If this chat only has one participating list object, it is returned.  Otherwise, nil is returned
- (AIListContact *)listObject
{
    if (([participatingListObjects count] == 1) && ![self isGroupChat]) {
        return [participatingListObjects objectAtIndex:0];
    } else {
        return nil;
    }
}
- (void)setListObject:(AIListContact *)inListObject
{
	if (inListObject != [self listObject]) {
		if ([participatingListObjects count]) {
			[participatingListObjects removeObjectAtIndex:0];
		}
		[self addParticipatingListObject:inListObject];

		//Clear any local caches relying on the list object
		[self clearListObjectStatuses];
		[self clearUniqueChatID];

		//Notify once the destination has been changed
		[[adium notificationCenter] postNotificationName:Chat_DestinationChanged object:self];
	}
}

- (NSString *)uniqueChatID
{
	if (!uniqueChatID) {
		AIListObject	*listObject;
		if ((listObject = [self listObject])) {
			uniqueChatID = [[listObject internalObjectID] retain];
		} else if (name) {
			uniqueChatID = [[NSString alloc] initWithFormat:@"%@.%i",name,nextChatNumber++];
		}
	}
	
	return (uniqueChatID);
}

- (void)clearUniqueChatID
{
	[uniqueChatID release]; uniqueChatID = nil;
}

//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content

/*
 * @brief Informs the chat that the core and the account are ready to begin filtering and sending a content object
 *
 * If there is only one object in pendingOutgoingContentObjects after adding inObject, we should send immedaitely.
 * However, if other objects are in it, we should wait for them to be removed, as they are chronologically first.
 * If we are asked if we should begin sending the earliest object in pendingOutgoingContentObjects, the answer is YES.
 *
 * @param inObject The object being sent
 * @result YES if the object should be sent immediately; NO if another object is in process so we should wait
 */
- (BOOL)willBeginSendingContentObject:(AIContentObject *)inObject
{
	int	currentIndex = [pendingOutgoingContentObjects indexOfObjectIdenticalTo:inObject];

	//Don't add the object twice when we are called from -[AIChat finishedSendingContentObject]
	if (currentIndex == NSNotFound) {
		[pendingOutgoingContentObjects addObject:inObject];		
	}

	return (([pendingOutgoingContentObjects count] == 1) ||
			(currentIndex == 0));
}

/*
 * @brief Informs the chat that an outgoing content object was sent and dispalyed.
 *
 * It is no longer pending, so we remove it from that array.
 * If there are more pending objects, trigger sending the next.
 *
 * @param inObject The object with which we are finished
 */
- (void)finishedSendingContentObject:(AIContentObject *)inObject
{
	[pendingOutgoingContentObjects removeObjectIdenticalTo:inObject];
	
	if ([pendingOutgoingContentObjects count]) {
		[[adium contentController] sendContentObject:[pendingOutgoingContentObjects objectAtIndex:0]];
	}
}

//
- (void)removeAllContent
{
    [contentObjectArray release]; contentObjectArray = [[NSMutableArray alloc] init];
}

- (BOOL)canSendMessages
{
	BOOL canSendMessages;
	if ([self isGroupChat]) {
		canSendMessages = YES;

	} else {
		AIListContact *listObject = [self listObject];

		canSendMessages = ([listObject online] ||
						   [listObject isStranger] ||
						   [[self account] canSendOfflineMessageToContact:listObject]);
	}
	
	return canSendMessages;
}

- (BOOL)canSendImages
{
	return [[self account] canSendImagesForChat:self];
}

- (int)unviewedContentCount
{
	return [self integerStatusObjectForKey:KEY_UNVIEWED_CONTENT];
}

- (void)incrementUnviewedContentCount
{
	int currentUnviewed = [self integerStatusObjectForKey:KEY_UNVIEWED_CONTENT];
	[self setStatusObject:[NSNumber numberWithInt:(currentUnviewed+1)]
					 forKey:KEY_UNVIEWED_CONTENT
					 notify:NotifyNow];
}

- (void)clearUnviewedContentCount
{
	[self setStatusObject:nil forKey:KEY_UNVIEWED_CONTENT notify:NotifyNow];
}

//Applescript ----------------------------------------------------------------------------------------------------------
#pragma mark Applescript
/*
 * @brief Applescript command to send a message in this chat
 */
- (id)sendScriptCommand:(NSScriptCommand *)command {
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*message = [evaluatedArguments objectForKey:@"message"];
	NSString		*filePath = [evaluatedArguments objectForKey:@"filePath"];
	
	//Send any message we were told to send
	if (message && [message length]) {
		BOOL			autoreply = [[evaluatedArguments objectForKey:@"autoreply"] boolValue];

		//Take the string and turn it into an attributed string (in case we were passed HTML)
		NSAttributedString  *attributedMessage = [AIHTMLDecoder decodeHTML:message];
		AIContentMessage	*messageContent;
		messageContent = [AIContentMessage messageInChat:self
											  withSource:[self account]
											 destination:[self listObject]
													date:nil
												 message:attributedMessage
											   autoreply:autoreply];
		
		[[adium contentController] sendContentObject:messageContent];
	}
	
	//Send any file we were told to send to every participating list object (anyone remember the AOL mass mailing zareW scene?)
	if (filePath && [filePath length]) {
		AIAccount		*sourceAccount = [evaluatedArguments objectForKey:@"account"];

		NSEnumerator	*enumerator = [[self participatingListObjects] objectEnumerator];
		AIListContact	*listContact;
		
		while ((listContact = [enumerator nextObject])) {
			AIListContact   *targetFileTransferContact;
			
			if (sourceAccount) {
				//If we were told to use a specific account, insist upon using it no matter what account the chat is on
				targetFileTransferContact = [[adium contactController] contactOnAccount:sourceAccount
																		fromListContact:listContact];
			} else {
				//Make sure we know where we are sending the file by finding the best contact for
				//sending CONTENT_FILE_TRANSFER_TYPE.
				targetFileTransferContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																					   forListContact:listContact];
			}
			
			[[adium fileTransferController] sendFile:filePath toListContact:targetFileTransferContact];
		}
	}
	
	return nil;
}

#pragma mark AIContainingObject protocol
//AIContainingObject protocol
- (NSArray *)containedObjects
{
	return [self participatingListObjects];
}

- (unsigned)containedObjectsCount
{
	return [[self containedObjects] count];
}

- (BOOL)containsObject:(AIListObject *)inObject
{
	return [[self containedObjects] containsObjectIdenticalTo:inObject];
}

- (id)objectAtIndex:(unsigned)index
{
	return [[self containedObjects] objectAtIndex:index];
}

- (int)indexOfObject:(AIListObject *)inObject
{
    return [[self containedObjects] indexOfObject:inObject];
}

//Retrieve a specific object by service and UID
- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID
{
	NSEnumerator	*enumerator = [[self containedObjects] objectEnumerator];
	AIListObject	*object;
	
	while ((object = [enumerator nextObject])) {
		if ([inUID isEqualToString:[object UID]] && [object service] == inService) break;
	}
	
	return object;
}

- (NSArray *)listContacts
{
	return [self containedObjects];
}

- (BOOL)addObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]]) {
		[self addParticipatingListObject:(AIListContact *)inObject];
		
		return YES;
	} else {
		return NO;
	}
}

- (void)removeObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]]) {
		[self removeParticipatingListObject:(AIListContact *)inObject];
	}
}

- (void)removeAllObjects {};

- (void)setExpanded:(BOOL)inExpanded
{
	expanded = inExpanded;
}
- (BOOL)isExpanded
{
	return expanded;
}

- (unsigned)visibleCount
{
	return [self containedObjectsCount];
}

//Not used
- (float)smallestOrder { return 0; }
- (float)largestOrder { return 1E10; }
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex {};


#pragma mark Ignore list (group chat)
/*!
 * @brief Set the ignored state of a contact
 *
 * @param inContact The contact whose state is to be changed
 * @param isIgnored YES to ignore the contact; NO to not ignore the contact
 */
- (void)setListContact:(AIListContact *)inContact isIgnored:(BOOL)isIgnored
{
	//Create ignoredListContacts if needed
	if (isIgnored && !ignoredListContacts) {
		ignoredListContacts = [[NSMutableSet alloc] init];	
	}

	if (isIgnored) {
		[ignoredListContacts addObject:inContact];
	} else {
		[ignoredListContacts removeObject:inContact];		
	}	
}

/*
 * @brief Is the passed object ignored?
 *
 * @param inContact The contact to check
 * @result YES if the contact is ignored; NO if it is not
 */
- (BOOL)isListContactIgnored:(AIListObject *)inContact
{
	return [ignoredListContacts containsObject:inContact];
}

#pragma mark Comparison
- (BOOL)isEqual:(id)inChat
{
	return (inChat == self);
}

#pragma mark Debugging
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@:%@",
		[super description],
		(uniqueChatID ? uniqueChatID : @"<new>")];
}

#pragma mark Group Chat

- (void)setIsGroupChat:(BOOL)flag
{
	isGroupChat = flag;
}

- (BOOL)isGroupChat
{
	return isGroupChat;
}

#pragma mark Custom emoticons

- (void)addCustomEmoticon:(AIEmoticon *)inEmoticon
{
	if (!customEmoticons) customEmoticons = [[NSMutableSet alloc] init];
	[customEmoticons addObject:inEmoticon];
}

- (NSSet *)customEmoticons;
{
	return customEmoticons;
}

#pragma mark Errors

/*
 * @brief Inform the chat that an error occurred
 *
 * @param type An NSNumber containing an AIChatErrorType
 */
- (void)receivedError:(NSNumber *)type
{
	//Notify observers
	[self setStatusObject:type forKey:KEY_CHAT_ERROR notify:NotifyNow];

	//No need to continue to store the NSNumber
	[self setStatusObject:nil forKey:KEY_CHAT_ERROR notify:NotifyNever];
}

#pragma mark Content array (deprecated?)
- (NSArray *)contentObjectArray
{
    return(contentObjectArray);
}

- (void)addContentObject:(AIContentObject *)inObject
{
	[contentObjectArray insertObject:inObject atIndex:0];
}

@end
