/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

// $Id: AIContentController.m,v 1.83 2004/06/13 18:55:56 evands Exp $

#import "AIContentController.h"

@interface AIContentController (PRIVATE)
- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject usingFilterArray:(NSArray *)inArray;
- (NSString *)_filterString:(NSString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject/* usingFilterArray:(NSArray *)inArray*/;
- (void)_filterContentObject:(AIContentObject *)inObject usingFilterArray:(NSArray *)inArray;
@end

@implementation AIContentController

//init
- (void)initController
{
    //Text entry filtering and tracking
    textEntryFilterArray = [[NSMutableArray alloc] init];
    textEntryContentFilterArray = [[NSMutableArray alloc] init];
    textEntryViews = [[NSMutableArray alloc] init];
    defaultFormattingAttributes = nil;
	
    //Chat tracking
    chatArray = [[NSMutableArray alloc] init];

    //Emoticons array
    emoticonsArray = nil;
    
    //Register our event notifications for message sending and receiving
    [owner registerEventNotification:Content_DidReceiveContent displayName:@"Message Received"];
    [owner registerEventNotification:Content_FirstContentRecieved displayName:@"Message Received (New)"]; 
    [owner registerEventNotification:Content_DidSendContent displayName:@"Message Sent"];
}

//close
- (void)closeController
{

}

//dealloc
- (void)dealloc
{
    [textEntryFilterArray release];
    [textEntryContentFilterArray release];
    [textEntryViews release];
    [chatArray release];

    [super dealloc];
}


//Default Formatting -------------------------------------------------------------------------------------------------
#pragma mark Default Formatting
- (void)setDefaultFormattingAttributes:(NSDictionary *)inDict
{
	[defaultFormattingAttributes release];
	defaultFormattingAttributes	= [inDict retain];
}
- (NSDictionary *)defaultFormattingAttributes
{
	return defaultFormattingAttributes;
}


//Text Entry Filtering -------------------------------------------------------------------------------------------------
#pragma mark 
//Text entry filters process content as it is entered by the user.
- (void)registerTextEntryFilter:(id)inFilter
{
	NSParameterAssert([inFilter respondsToSelector:@selector(didOpenTextEntryView:)] &&
					  [inFilter respondsToSelector:@selector(willCloseTextEntryView:)]);
	
	//For performance reasons, we place filters that actually monitor content in a separate array
	if([inFilter respondsToSelector:@selector(stringAdded:toTextEntryView:)] &&
	   [inFilter respondsToSelector:@selector(contentsChangedInTextEntryView:)]){
		[textEntryContentFilterArray addObject:inFilter];
	}else{
		[textEntryFilterArray addObject:inFilter];
	}
}
- (void)unregisterTextEntryFilter:(id)inFilter
{
	[textEntryContentFilterArray removeObject:inFilter];
	[textEntryFilterArray removeObject:inFilter];
}

//A string was added to a text entry view
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id				filter;
	
    //Notify all text entry filters (that are interested in filtering content)
    enumerator = [textEntryContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter stringAdded:inString toTextEntryView:inTextEntryView];
    }
}

//A text entry view's content changed
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id				filter;
	
    //Notify all text entry filters (that are interested in filtering content)
    enumerator = [textEntryContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter contentsChangedInTextEntryView:inTextEntryView];
    }
}

//A text entry view was opened
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id				filter;
	
    //Track the view
    [textEntryViews addObject:inTextEntryView];
    
    //Notify all text entry filters
    enumerator = [textEntryContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter didOpenTextEntryView:inTextEntryView];
    }
    enumerator = [textEntryFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter didOpenTextEntryView:inTextEntryView];
    }
}

//A text entry view was closed
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id				filter;
	
    //Stop tracking the view
    [textEntryViews removeObject:inTextEntryView];
	
    //Notify all text entry filters
    enumerator = [textEntryContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter willCloseTextEntryView:inTextEntryView];
    }
    enumerator = [textEntryFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter willCloseTextEntryView:inTextEntryView];
    }
}

//Returns all currently open text entry views
- (NSArray *)openTextEntryViews
{
    return(textEntryViews);
}


//Content Filtering ----------------------------------------------------------------------------------------------------
#pragma mark 
//Register a content filter.  If the particular filter wants to apply to multiple types or directions, it should
//register multiple times.  Be careful that incoming content is always contained (aka: Don't feed incoming content
//to a shell script or something silly like that).
- (void)registerContentFilter:(id <AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction
{
	NSParameterAssert(inFilter != nil);
	NSParameterAssert(type >= 0 && type < FILTER_TYPE_COUNT);
	NSParameterAssert(direction >= 0 && direction < FILTER_DIRECTION_COUNT);

	if(!contentFilter[type][direction]) contentFilter[type][direction] = [[NSMutableArray alloc] init];
	[contentFilter[type][direction] addObject:inFilter];
}

//Unregister all instances of filter.
- (void)unregisterContentFilter:(id <AIContentFilter>)inFilter
{
	NSParameterAssert(inFilter != nil);

	int i, j;
	for(i = 0; i < FILTER_TYPE_COUNT; i++){
		for(j = 0; j < FILTER_DIRECTION_COUNT; j++){
			[contentFilter[i][j] removeObject:inFilter];
		}
	}
}

//Filters an attributed string.  If the string is associated with a contact or list object, pass that object as context.
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)attributedString
							   usingFilterType:(AIFilterType)type
									 direction:(AIFilterDirection)direction
									   context:(id)context
{
	if(attributedString){
		NSParameterAssert(type >= 0 && type < FILTER_TYPE_COUNT);
		NSParameterAssert(direction >= 0 && direction < FILTER_DIRECTION_COUNT);
		
		NSEnumerator		*enumerator = [contentFilter[type][direction] objectEnumerator];
		id<AIContentFilter>	filter;
    	
		while((filter = [enumerator nextObject])){
			attributedString = [filter filterAttributedString:attributedString context:context];
		}
	}
    
    return(attributedString);
}


//Messaging ------------------------------------------------------------------------------------------------------------
#pragma mark Messaging
//Add an incoming content object
- (void)receiveContentObject:(AIContentObject *)inObject
{
    AIChat			*chat = [inObject chat];
    AIListObject 	*object = [inObject source];
	NSArray			*contentObjectArray = [chat contentObjectArray];
	
	BOOL			shouldBeFirstMessage = NO;
	
    if(object){
        //Notify: Will Receive Content
        if([inObject trackContent]){
            [[owner notificationCenter] postNotificationName:Content_WillReceiveContent
													  object:chat
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
        }

		//Run the object through our incoming content filters
        if([inObject filterContent]){
			[inObject setMessage:[self filterAttributedString:[inObject message]
											  usingFilterType:AIFilterContent
													direction:AIFilterIncoming
													  context:inObject]];
        }
		
		if([inObject trackContent]) {
			int		contentLength = [contentObjectArray count];
			
			if(contentLength <= 1 || 
			   ![[(AIContentObject *)[contentObjectArray objectAtIndex:0] type] isEqualToString:[inObject type]]){
			
				shouldBeFirstMessage = YES;
			}
		}

		//Display the content
		[self displayContentObject:inObject];

		//Notify: Did Receive Content
        if([inObject trackContent]){
            if([contentObjectArray count] > 1 && !shouldBeFirstMessage){
                [[owner notificationCenter] postNotificationName:Content_DidReceiveContent
														  object:chat
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject, @"Object", nil]];
            }else{
                [[owner notificationCenter] postNotificationName:Content_FirstContentRecieved 
														  object:chat
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
            }
            mostRecentChat = chat;
        }
    }
}

//Send a content object
- (BOOL)sendContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
    BOOL		sent = NO;
    	
    //Notify: Will Send Content
    if([inObject trackContent]){
        [[owner notificationCenter] postNotificationName:Content_WillSendContent
												  object:chat 
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }

    //Run the object through our outgoing content filters
    if([inObject filterContent]){
		[inObject setMessage:[self filterAttributedString:[inObject message]
										  usingFilterType:AIFilterContent
												direction:AIFilterOutgoing
												  context:inObject]];
    }

    //Send the object
    if([(AIAccount <AIAccount_Content> *)[inObject source] sendContentObject:inObject]){
        if([inObject displayContent]){
            //Add the object
            [self displayContentObject:inObject];
        }

        if([inObject trackContent]){
            //Did send content
            [[owner notificationCenter] postNotificationName:Content_DidSendContent object:chat 
						    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
        }

        mostRecentChat = chat;
        sent = YES;
    }

    return(sent);
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters
{
	if (useContentFilters){
		[inObject setMessage:[self filterAttributedString:[inObject message]
										  usingFilterType:AIFilterContent
												direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
												  context:inObject]];
	}
	
	//Add the object
	[self displayContentObject:inObject];
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject
{
    //Filter the content object
    if([inObject filterContent]){
		BOOL message = ([inObject isKindOfClass:[AIContentMessage class]] && ![(AIContentMessage *)inObject isAutoreply]);
		[inObject setMessage:[self filterAttributedString:[inObject message]
										  usingFilterType:(message ? AIFilterMessageDisplay : AIFilterDisplay)
												direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
												  context:inObject]];
    }
    
    //Check if the object should display
    if([inObject displayContent]){
		AIChat		*chat = [inObject chat];

		//Tell the interface to open the chat
		if(![chat hasContent]){
			[[owner interfaceController] openChat:chat]; 
		}
		
		//Add this content to the chat
		[chat addContentObject:inObject];
		
		//Notify: Content Object Added
		[[owner notificationCenter] postNotificationName:Content_ContentObjectAdded object:chat
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }
}

//Returns YES if the account/chat is available for sending content
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject onAccount:(AIAccount *)inAccount 
{
    if([inAccount conformsToProtocol:@protocol(AIAccount_Content)]){
        return([(AIAccount <AIAccount_Content> *)inAccount availableForSendingContentType:inType toListObject:inListObject]);
    }else{
        return(NO);
    }
}



//Chats -------------------------------------------------------------------------------------------------
#pragma mark Chats
//Opens a chat for communication with the contact, creating if necessary.  The new chat will be made active.
- (AIChat *)openChatWithContact:(AIListContact *)inContact
{
	AIChat	*chat = [self chatWithContact:inContact initialStatus:nil];
	if(chat) [[owner interfaceController] openChat:chat]; 

	return(chat);	
}

//Creates a chat for communication with the contact, but does not make the chat active (Doesn't open a chat window)
//If desired, the chat's initial status can be set during creation.  Pass nil for default initial status.
//If a chat already exists it will be returned (and initialStatus will be ignored).
- (AIChat *)chatWithContact:(AIListContact *)inContact initialStatus:(NSDictionary *)initialStatus
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	
	//If we're dealing with a meta contact, open a chat with the preferred contact for this meta contact
	//It's a good idea for the caller to pick the preferred contact for us, since they know the content type
	//being sent and more information - but we'll do it here as well just to be safe.
	if ([inContact isKindOfClass:[AIMetaContact class]]){
		inContact = [[owner contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
															   forListContact:inContact];
	}
	
	//Search for an existing chat we can switch instead of replacing
	enumerator = [chatArray objectEnumerator];
	while(chat = [enumerator nextObject]){
		//If a chat for this object already exists
		if([[chat uniqueChatID] isEqualToString:[inContact uniqueObjectID]]) break;
		
		//If this object is within a meta contact, and a chat for and object in that meta contact already exists
		if([[inContact containingGroup] isKindOfClass:[AIMetaContact class]] && 
		   [[chat listObject] containingGroup] == [inContact containingGroup]){

			//If we're on a different account now, switch the chat over
			if(![[inContact accountID] isEqualToString:[(AIListContact *)[chat listObject] accountID]]){
				[self switchChat:chat
					   toAccount:[[owner accountController] accountWithObjectID:[inContact accountID]]];
			}
			
			break;
		}
	}
	if(!chat){
		
		AIAccount *account = [[owner accountController] accountWithObjectID:[inContact accountID]];
	
		if([account conformsToProtocol:@protocol(AIAccount_Content)]){
			//Create a new chat
			chat = [AIChat chatForAccount:account initialStatusDictionary:initialStatus];
			[chat addParticipatingListObject:inContact];
			[chatArray addObject:chat];

			//Inform the account of its creation and post a notification if successful
			if([(AIAccount<AIAccount_Content> *)account openChat:chat]){
				[[owner notificationCenter] postNotificationName:Chat_DidOpen object:chat userInfo:nil];
			}else{
				[chatArray removeObject:chat];
				chat = nil;
			}
			
			
		}
	}
	
	return(chat);
}

- (AIChat *)chatWithName:(NSString *)inName onAccount:(AIAccount *)account initialStatus:(NSDictionary *)initialStatus
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	NSString		*uniqueChatID;
	
	//Search for an existing chat we can use instead of creating a new one
	enumerator = [chatArray objectEnumerator];
	uniqueChatID = [AIChat uniqueChatIDForChatWithName:inName onAccount:account];
	while(chat = [enumerator nextObject]){
		
		//If the chat we want already exists
		if([[chat uniqueChatID] isEqualToString:uniqueChatID]) break;
	}

	if (!chat){
		if([account conformsToProtocol:@protocol(AIAccount_Content)]){
			//Create a new chat
			chat = [AIChat chatForAccount:account initialStatusDictionary:initialStatus];
			[chat setName:inName];
			[chatArray addObject:chat];
			
			//Inform the account of its creation and post a notification if successful
			if([(AIAccount<AIAccount_Content> *)account openChat:chat]){
				[[owner notificationCenter] postNotificationName:Chat_DidOpen object:chat userInfo:nil];
			}else{
				[chatArray removeObject:chat];
				chat = nil;
			}
		}
	}
	return(chat);
}

//Close a chat
- (BOOL)closeChat:(AIChat *)inChat
{
	AIListObject	*listObject;

    if (mostRecentChat == inChat)
        mostRecentChat = nil;
    
	//Lower the chat count for this contact
	if(listObject = [inChat listObject]){
        int currentCount = [[listObject numberStatusObjectForKey:@"ChatsCount"] intValue];
        if(currentCount > 0) {
			[listObject setStatusObject:[NSNumber numberWithInt:(currentCount - 1)]
								 forKey:@"ChatsCount"
								 notify:YES];
		}
	}
	
    //Notify the account and send out the Chat_WillClose notification
    [(AIAccount<AIAccount_Content> *)[inChat account] closeChat:inChat];
    [[owner notificationCenter] postNotificationName:Chat_WillClose object:inChat userInfo:nil];
    
    //Remove the chat
    [chatArray removeObject:inChat];

    //Remove all content from the chat
    [inChat removeAllContent];

    return(YES);
}

//Switch a chat from one account to another
- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount
{
	AIListContact	*oldContact = (AIListContact *)[chat listObject];
	AIListContact	*newContact = [[owner contactController] contactWithService:[oldContact serviceID] accountID:[newAccount uniqueObjectID] UID:[oldContact UID]];

	//Hang onto stuff until we're done
	[chat retain];
	[oldContact retain];
	
	//Close down the chat on account A
	[chat removeParticipatingListObject:oldContact];
	[(AIAccount<AIAccount_Content> *)[chat account] closeChat:chat];
	
	//Open the chat on account B 
	[chat addParticipatingListObject:newContact];
	[(AIAccount<AIAccount_Content> *)newAccount openChat:chat];
	[chat setAccount:newAccount];
	
	//Let everyone else know we switched the account of this chat
	[[owner notificationCenter] postNotificationName:Content_ChatAccountChanged object:chat];
	
	//Clean up
	[chat release];
	[oldContact release];
}

//Returns all chats with the object
- (NSArray *)allChatsWithListObject:(AIListObject *)inObject
{
    NSMutableArray	*foundChats = [NSMutableArray array];
    NSEnumerator	*chatEnumerator;
    AIChat		*chat;

    //Scan all the open chats
    chatEnumerator = [chatArray objectEnumerator];
    while((chat = [chatEnumerator nextObject])){
        NSEnumerator	*objectEnumerator;
        AIListObject	*object;

        //Scan the objects participating in this chat, looking for the requested object
        objectEnumerator = [[chat participatingListObjects] objectEnumerator];
        while((object = [objectEnumerator nextObject])){
            if(object == inObject){
                [foundChats addObject:chat];
            }
        }
    }

    return(foundChats);
}

- (NSArray *)chatArray
{
    return chatArray;
}

//Switch to a chat with the most recent unviewed content.  Returns YES if one existed
- (BOOL)switchToMostRecentUnviewedContent
{
    if(mostRecentChat && [mostRecentChat listObject] && [[[mostRecentChat listObject] numberStatusObjectForKey:@"UnviewedContent"] intValue]){
		[[owner interfaceController] setActiveChat:mostRecentChat];
		return(YES);
    }else{
		return(NO);
    }
}

//Content Source & Destination -----------------------------------------------------------------------------------------
#pragma mark Content Source & Destination
//Returns the available account for sending content to a specified contact
- (NSArray *)sourceAccountsForSendingContentType:(NSString *)inType
									toListObject:(AIListObject *)inObject
									   preferred:(BOOL)inPreferred
{
	NSMutableArray	*sourceAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[owner accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while(account = [enumerator nextObject]){
		if([[inObject serviceID] isEqualToString:[[[account service] handleServiceType] identifier]]){
			BOOL			knowsObject = NO;
			BOOL			couldSendContent = NO;
			AIListContact	*contactForAccount = [[owner contactController] existingContactWithService:[inObject serviceID]
																							 accountID:[account UID]
																								   UID:[inObject UID]];
			//Does the account know this object?
			if(contactForAccount){
				knowsObject = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType
														 toListObject:contactForAccount];
			}
			
			//Could the account send this
			couldSendContent = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType
														  toListObject:nil];
			
			if((inPreferred && knowsObject) || (!inPreferred && !knowsObject && couldSendContent)){
				[sourceAccounts addObject:account];
			}
		}
	}
	
	return(sourceAccounts);
}

//Returns the available contacts for receiving content to a specific contact
- (NSArray *)destinationObjectsForContentType:(NSString *)inType
								 toListObject:(AIListObject *)inObject
									preferred:(BOOL)inPreferred
{
	//meta contact special case here, return any contacts in the user defined meta contact
	return([NSArray arrayWithObject:inObject]);
}


//Emoticons (In the core?) ---------------------------------------------------------------------------------------------
#pragma mark Emoticons (In the core?) - Yes, the core, for all us access hoes ;)
//emoticonPacks is an array of all AIEmoticonPack objects that are active, maintained by the Emoticons plugin
// primary use: emoticon menu for grouping by pack, if you find another, congrats!
- (void)setEmoticonPacks:(NSArray *)inEmoticonPacks
{
    emoticonPacks = inEmoticonPacks;
}
- (NSArray *)emoticonPacks
{
    return emoticonPacks;   
}
//emoticonsArray is an array of all AIEmoticon objects in the active emoticon set, maintained by the Emoticons plugin
- (void)setEmoticonsArray:(NSArray *)inEmoticonsArray
{
    emoticonsArray = inEmoticonsArray;
}
- (NSArray *)emoticonsArray
{
    return emoticonsArray;   
}

@end
