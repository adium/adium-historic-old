//
//  AIChat.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//

#import "AIChat.h"
#import "AIAccount.h"
#import "AIListContact.h"
#import "ESFileTransfer.h"
#import "AIContentMessage.h"

@interface AIChat (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount;
- (void)clearUniqueChatID;
- (void)clearListObjectStatuses;
@end

@implementation AIChat

static int nextChatNumber = 0;

+ (id)chatForAccount:(AIAccount *)inAccount
{
    return([[[self alloc] initForAccount:inAccount] autorelease]);
}

- (id)initForAccount:(AIAccount *)inAccount
{
    [super init];
	AILog(@"[%@ initForAccount]",self);

	name = nil;
    account = [inAccount retain];
    contentObjectArray = [[NSMutableArray alloc] init];
    participatingListObjects = [[NSMutableArray alloc] init];
    dateOpened = [[NSDate date] retain];
	uniqueChatID = nil;
	isOpen = NO;
	expanded = YES;
	
    return(self);
}

- (void)dealloc
{
	AILog(@"[%@ dealloc]",self);
    [account release];
    [contentObjectArray release];
    [participatingListObjects release];
  	[dateOpened release]; 
	[uniqueChatID release]; uniqueChatID = nil;
	
    [super dealloc];
}

//Big image
- (NSImage *)chatImage
{
	AIListObject 	*listObject = [self listObject];
	NSImage			*image = nil;
	
	if(listObject){
		image = [listObject userIcon];
		if(!image) image = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconLarge direction:AIIconNormal];
	}

	return(image);
}

//lil image
- (NSImage *)chatMenuImage
{
	AIListObject 	*listObject;
	NSImage			*chatMenuImage = nil;
	
	if(listObject = [self listObject]){
		chatMenuImage = [AIUserIcons menuUserIconForObject:listObject];
	}

	return(chatMenuImage);
}

    
//Associated Account ---------------------------------------------------------------------------------------------------
#pragma mark Associated Account
- (AIAccount *)account
{
    return(account);
}

- (void)setAccount:(AIAccount *)inAccount
{
	if(inAccount != account){
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
	return(dateOpened);
}

- (void)setDateOpened:(NSDate *)inDate
{
	[dateOpened release]; 
	dateOpened = [inDate retain];
}

- (BOOL)isOpen
{
	return isOpen;
}
- (void)setIsOpen:(BOOL)flag
{
	isOpen = flag;
}

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Status
- (void)didModifyStatusKeys:(NSArray *)keys silent:(BOOL)silent
{
	[[adium contentController] chatStatusChanged:self
							  modifiedStatusKeys:keys
										  silent:silent];	
}

- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	//If our unviewed content changes or typing status changes, and we have a single list object, 
	//apply the change to that object as well so it can be cleanly reflected in the contact list.
	if ([key isEqualToString:KEY_UNVIEWED_CONTENT] ||
		[key isEqualToString:KEY_TYPING]){
		AIListObject	*listObject = [self listObject];
		
		if (listObject) [listObject setStatusObject:value forKey:key notify:notify];
	}
	
	[super object:inObject didSetStatusObject:value forKey:key notify:notify];
}

- (void)clearListObjectStatuses
{
	AIListObject	*listObject = [self listObject];
	
	if (listObject){
		[listObject setStatusObject:nil forKey:KEY_UNVIEWED_CONTENT notify:NotifyLater];
		[listObject setStatusObject:nil forKey:KEY_TYPING notify:NotifyLater];
	
		[listObject notifyOfChangedStatusSilently:NO];
	}
	
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
    return(outName ? outName : (name ? name : [[self listObject] displayName]));
}

//Participating ListObjects --------------------------------------------------------------------------------------------
#pragma mark Participating ListObjects
- (NSArray *)participatingListObjects
{
    return(participatingListObjects);
}

- (void)addParticipatingListObject:(AIListContact *)inObject
{
	if (![participatingListObjects containsObjectIdenticalTo:inObject]){
		[participatingListObjects addObject:inObject]; //Add
		[[adium notificationCenter] postNotificationName:Chat_ParticipatingListObjectsChanged object:self]; //Notify
	}

}

// Invite a list object to join the chat. Returns YES if the chat joins, NO otherwise
- (BOOL)inviteListContact:(AIListContact *)inContact withMessage:(NSString *)inviteMessage
{
	return ([[self account] inviteContact:inContact toChat:self withMessage:inviteMessage]);
}

//
- (void)removeParticipatingListObject:(AIListContact *)inObject
{
    [participatingListObjects removeObject:inObject]; //Remove	
	[[adium notificationCenter] postNotificationName:Chat_ParticipatingListObjectsChanged object:self]; //Notify

}

- (void)setPreferredListObject:(AIListContact *)inObject
{
	preferredListObject = inObject;
}

- (AIListObject *)preferredListObject
{
	return preferredListObject;
}

//If this chat only has one participating list object, it is returned.  Otherwise, nil is returned
- (AIListContact *)listObject
{
    if([participatingListObjects count] == 1){
        return([participatingListObjects objectAtIndex:0]);
    }else{
        return(nil);
    }
}
- (void)setListObject:(AIListContact *)inListObject
{
	if(inListObject != [self listObject]){
		[self clearListObjectStatuses];
		[[adium notificationCenter] postNotificationName:Chat_DestinationChanged object:self]; //Notify

		//The uniqueChatID may depend upon the listObject, so clear it
		[self clearUniqueChatID];
		
		if ([participatingListObjects count]){
			[participatingListObjects removeObjectAtIndex:0];
		}
		
		[self addParticipatingListObject:inListObject];
	}
}

- (NSString *)uniqueChatID
{
	if (!uniqueChatID) {
		AIListObject	*listObject;
		if (listObject = [self listObject]){
			uniqueChatID = [listObject internalObjectID];
		}else{
			uniqueChatID = [NSString stringWithFormat:@"%@.%i",name,nextChatNumber++];
		}
		
		NSAssert(uniqueChatID != nil, @"nil uniqueChatID");
		
		[uniqueChatID retain];
	}
	
	return (uniqueChatID);
}

- (void)clearUniqueChatID
{
	[uniqueChatID release]; uniqueChatID = nil;
}

//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content
//Return our array of content objects
- (NSArray *)contentObjectArray
{
    return(contentObjectArray);
}

- (BOOL)hasContent
{
    return ([contentObjectArray count] != 0);
}

- (void)setContentArray:(NSArray *)inContentArray
{
    if((NSArray *)contentObjectArray != inContentArray){
        [contentObjectArray release];
        contentObjectArray = [inContentArray mutableCopy];
    }
}

//Add a message object to this handle
- (void)addContentObject:(AIContentObject *)inObject
{
    //Add the object
    [contentObjectArray insertObject:inObject atIndex:0];
}

//
- (void)appendContentArray:(NSArray *)inContentArray
{
    [contentObjectArray addObjectsFromArray:inContentArray];
}

//
- (void)removeAllContent
{
    [contentObjectArray release]; contentObjectArray = [[NSMutableArray alloc] init];
}


//Applescript ----------------------------------------------------------------------------------------------------------
#pragma mark Applescript
- (id)sendScriptCommand:(NSScriptCommand *)command {
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*message = [evaluatedArguments objectForKey:@"message"];
	NSString		*filePath = [evaluatedArguments objectForKey:@"filePath"];
	
	//Send any message we were told to send
	if (message && [message length]){
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
	if (filePath && [filePath length]){
		AIAccount		*sourceAccount = [evaluatedArguments objectForKey:@"account"];

		NSEnumerator	*enumerator = [[self participatingListObjects] objectEnumerator];
		AIListContact	*listContact;
		
		while (listContact = [enumerator nextObject]){
			AIListContact   *targetFileTransferContact;
			
			if (sourceAccount){
				//If we were told to use a specific account, insist upon using it no matter what account the chat is on
				targetFileTransferContact = [[adium contactController] contactOnAccount:sourceAccount
																		fromListContact:listContact];
			}else{
				//Make sure we know where we are sending the file by finding the best contact for
				//sending FILE_TRANSFER_TYPE.
				targetFileTransferContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
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
	return([self participatingListObjects]);
}

- (unsigned)containedObjectsCount
{
	return([[self containedObjects] count]);
}

- (BOOL)containsObject:(AIListObject *)inObject
{
	return([[self containedObjects] containsObjectIdenticalTo:inObject]);
}

- (id)objectAtIndex:(unsigned)index
{
	return([[self containedObjects] objectAtIndex:index]);
}

- (int)indexOfObject:(AIListObject *)inObject
{
    return([[self containedObjects] indexOfObject:inObject]);
}

//Retrieve a specific object by service and UID
- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID
{
	NSEnumerator	*enumerator = [[self containedObjects] objectEnumerator];
	AIListObject	*object;
	
	while(object = [enumerator nextObject]){
		if([inUID isEqualToString:[object UID]] && [object service] == inService) break;
	}
	
	return(object);
}
//Enumerator of -[containedObjects]
- (NSEnumerator *)objectEnumerator
{
	return([[self containedObjects] objectEnumerator]);
}

//Should list each list contact only once (for chats, this is the same as the objectEnumerator)
- (NSEnumerator *)listContactsEnumerator
{
	return([self objectEnumerator]);
}

- (BOOL)addObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]]){
		[self addParticipatingListObject:(AIListContact *)inObject];
		
		return YES;
	}else{
		return NO;
	}
}

- (void)removeObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]]){
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
	return([self containedObjectsCount]);
}

//Not used
- (float)smallestOrder { return(0); }
- (float)largestOrder { return(1E10); }
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex {};

@end
