//
//  AIChat.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//

#import "AIChat.h"

@interface AIChat (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary;
@end

@implementation AIChat

+ (id)chatForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary
{
    return([[[self alloc] initForAccount:inAccount initialStatusDictionary:inDictionary] autorelease]);
}

- (id)initForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary
{
    [super init];

	name = nil;
    account = [inAccount retain];
    statusDictionary = (inDictionary ? [inDictionary mutableCopy] : [[NSMutableDictionary alloc] init]);
    contentObjectArray = [[NSMutableArray alloc] init];
    participatingListObjects = [[NSMutableArray alloc] init];
    dateOpened = [[NSDate date] retain];
	uniqueChatID = nil;
	_serviceImage = nil;
	_cachedImage = nil;
	_cachedMiniImage = nil;

    return(self);
}

- (void)dealloc
{
    [account release];
    [statusDictionary release];
    [contentObjectArray release];
    [participatingListObjects release];
  	[dateOpened release]; 
	[uniqueChatID release]; uniqueChatID = nil;
  	[_serviceImage release]; 
  	[_cachedImage release]; 
  	[_cachedMiniImage release]; 
	
    [super dealloc];
}

//Big image
- (NSImage *)chatImage
{
	AIListObject 	*listObject = [self listObject];
	NSImage			*image = nil;
	
	if(listObject){
		//Use the contact's image
		image = [listObject userIcon];
		if(!image){
			//If that is not available, use the contact's service image (cached, since it's a lot of work to look up)
			if(!_serviceImage){
				_serviceImage = [[[[adium accountController] accountWithObjectID:[(AIListContact *)listObject accountID]] menuImage] retain];
			}
			image = _serviceImage;
		}
	}

	return(image);
}

//lil image
- (NSImage *)chatMenuImage
{
	AIListObject 	*listObject = [self listObject];
	
	if(listObject){
		//If the image has changed, re-render our mini image
		if(_cachedImage != [self chatImage]){
			//Hold onto the new image, we'll need it later to know when the image has changed :)
			[_cachedImage release];
			_cachedImage = [[self chatImage] retain];

			//Flush the old mini image, and render a new one
			[_cachedMiniImage release];
			_cachedMiniImage = [[_cachedImage imageByScalingToSize:NSMakeSize(16,16)] retain];
		}
	}

	return(_cachedMiniImage);
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
		[[adium notificationCenter] postNotificationName:Content_ChatAccountChanged object:self]; //Notify
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


//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Status
- (NSMutableDictionary *)statusDictionary
{
    return(statusDictionary);
}
- (NSString *)name
{
	return (name ? name : [[self listObject] displayName]);
}
- (void)setName:(NSString *)inName
{
	[name release]; name = [inName retain]; 
}


//Participating ListObjects --------------------------------------------------------------------------------------------
#pragma mark Participating ListObjects
- (NSArray *)participatingListObjects
{
    return(participatingListObjects);
}

- (void)addParticipatingListObject:(AIListObject *)inObject
{
    [participatingListObjects addObject:inObject]; //Add
    [[adium notificationCenter] postNotificationName:Content_ChatParticipatingListObjectsChanged object:self]; //Notify

}

// Invite a list object to join the chat. Returns YES if the chat joins, NO otherwise
- (BOOL)inviteListObject:(AIListObject *)inObject
{
	[self addParticipatingListObject:inObject];
	return [[self account] inviteContact:inObject toChat:self];
}

//
- (void)removeParticipatingListObject:(AIListObject *)inObject
{
    [participatingListObjects removeObject:inObject]; //Remove	
	[[adium notificationCenter] postNotificationName:Content_ChatParticipatingListObjectsChanged object:self]; //Notify

}

- (void)setPreferredListObject:(AIListObject *)inObject
{
	preferredListObject = inObject;
}

- (AIListObject *)preferredListObject
{
	return preferredListObject;
}

//If this chat only has one participating list object, it is returned.  Otherwise, nil is returned
- (AIListObject *)listObject
{
    if([participatingListObjects count] == 1){
        return([participatingListObjects objectAtIndex:0]);
    }else{
        return(nil);
    }
}

- (NSString *)uniqueChatID
{
	if (!uniqueChatID) {
		AIListObject	*listObject;
		if (listObject = [self listObject]){
			uniqueChatID = [listObject uniqueObjectID];
		}else{
			uniqueChatID = [NSString stringWithFormat:@"%@.%@",name,[account uniqueObjectID]];
		}
		
		//If things go horribly awry, we can end up with no uniqueChatID here.  Simple guard so code elsewhere can work.
		if (!uniqueChatID){
			uniqueChatID = [NSString stringWithFormat:@"%@.%@",[NSString randomStringOfLength:4],[account uniqueObjectID]];
		}
		
		[uniqueChatID retain];
	}
	
	return (uniqueChatID);
}

+ (NSString *)uniqueChatIDForChatWithName:(NSString *)inName onAccount:(AIAccount *)inAccount
{
	return [NSString stringWithFormat:@"%@.%@", inName, [inAccount uniqueObjectID]];
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

#pragma mark Applescript Commands
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


@end
