/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id: AIContentController.m,v 1.52 2004/02/22 09:18:42 evands Exp $

#import "AIContentController.h"

@interface AIContentController (PRIVATE)
- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject usingFilterArray:(NSArray *)inArray;
- (void)_filterContentObject:(AIContentObject *)inObject usingFilterArray:(NSArray *)inArray;
@end

@implementation AIContentController

//init
- (void)initController
{
    //Content Filtering
    outgoingContentFilterArray = [[NSMutableArray alloc] init];
    incomingContentFilterArray = [[NSMutableArray alloc] init];
    displayingContentFilterArray = [[NSMutableArray alloc] init];

    //Text entry filtering and tracking
    textEntryFilterArray = [[NSMutableArray alloc] init];
    textEntryContentFilterArray = [[NSMutableArray alloc] init];
    textEntryViews = [[NSMutableArray alloc] init];
    
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
    [outgoingContentFilterArray release];
    [incomingContentFilterArray release];
    [displayingContentFilterArray release];
    [textEntryFilterArray release];
    [textEntryContentFilterArray release];
    [textEntryViews release];
    [chatArray release];

    [super dealloc];
}


//Text Entry Filters ------------------------------------------------------------------------------------
#pragma mark Text Entry Filters
//Register a text entry filter
- (void)registerTextEntryFilter:(id)inFilter
{
    if([inFilter respondsToSelector:@selector(didOpenTextEntryView:)] &&
       [inFilter respondsToSelector:@selector(willCloseTextEntryView:)]){

        //For performance reasons, we place filters that actually monitor content in a separate array
        if([inFilter respondsToSelector:@selector(stringAdded:toTextEntryView:)] &&
           [inFilter respondsToSelector:@selector(contentsChangedInTextEntryView:)]){
            [textEntryContentFilterArray addObject:inFilter];
        }else{
            [textEntryFilterArray addObject:inFilter];
        }

    }else{
        NSLog(@"Invalid AITextEntryFilter");
    }
}

//Returns all currently open text entry views
- (NSArray *)openTextEntryViews
{
    return(textEntryViews);
}

//Called when a string is added to a text entry view
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id			filter;

    //Notify all text entry filters (that are interested in filtering content)
    enumerator = [textEntryContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter stringAdded:inString toTextEntryView:inTextEntryView];
    }
}

//Called when a text entry view's content changes
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id			filter;

    //Notify all text entry filters (that are interested in filtering content)
    enumerator = [textEntryContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter contentsChangedInTextEntryView:inTextEntryView];
    }
}

//Called as a text entry view is opened
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id			filter;

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

//Called as a text entry view is closed
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator	*enumerator;
    id			filter;

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


//Content Filters -----------------------------------------------------------------------------------------
#pragma mark Content Filters

- (void)registerOutgoingContentFilter:(id <AIContentFilter>)inFilter 
{
    [outgoingContentFilterArray addObject:inFilter];
}
- (void)unregisterOutgoingContentFilter:(id <AIContentFilter>)inFilter 
{
    [outgoingContentFilterArray removeObject:inFilter];
}

//
- (void)registerIncomingContentFilter:(id <AIContentFilter>)inFilter
{
    [incomingContentFilterArray addObject:inFilter];
}
- (void)unregisterIncomingContentFilter:(id <AIContentFilter>)inFilter
{
    [incomingContentFilterArray removeObject:inFilter];
}

//
- (void)registerDisplayingContentFilter:(id <AIContentFilter>)inFilter
{
    [displayingContentFilterArray addObject:inFilter];
}

- (void)unregisterDisplayingContentFilter:(id <AIContentFilter>)inFilter
{
    [displayingContentFilterArray removeObject:inFilter];
}

//Modify a contentObject by passing it through the appropriate filters
- (void)filterObject:(AIContentObject *)inObject isOutgoing:(BOOL)isOutgoing
{
    [self _filterContentObject:inObject usingFilterArray:(isOutgoing ? 
                                                          outgoingContentFilterArray : displayingContentFilterArray)];
}

//Return an attributed string which is the result of passing inString through both outgoing and display filters
- (NSAttributedString *)fullyFilteredAttributedString:(NSAttributedString *)inString listObjectContext:(AIListObject *)inListObject
{
    return [self filteredAttributedString:[self filteredAttributedString:inString listObjectContext:inListObject isOutgoing:YES] listObjectContext:inListObject isOutgoing:NO];
}

//Return an attributed string which is the result of passing inString through the specified filter (outgoing or diplay)
- (NSAttributedString *)filteredAttributedString:(NSAttributedString *)inString listObjectContext:(AIListObject *)inListObject isOutgoing:(BOOL)isOutgoing
{
    return ([self _filterAttributedString:inString
                         forContentObject:nil
						 listObjectContext:inListObject
                         usingFilterArray:(isOutgoing ? 
                                           outgoingContentFilterArray : displayingContentFilterArray)]);
}

// Send the specified attributed string and possibly a contentObject through the specified filters, returning the modified
// string if one is generated (or the original string if one is not).  Filters get the contentObject and can modify it,
// but should not expect its "message" member to be accurate.
- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject usingFilterArray:(NSArray *)inArray
{
    NSEnumerator                *enumerator;
    id<AIContentFilter>         filter;
    NSAttributedString          *filteredString = inString;
    
    if (inString){
        enumerator = [inArray objectEnumerator];
        while((filter = [enumerator nextObject])){
            filteredString = [filter filterAttributedString:filteredString forContentObject:inObject listObjectContext:inListObject];
        }
    }
    
    return filteredString;
}

- (void)_filterContentObject:(AIContentObject *)inObject usingFilterArray:(NSArray *)inArray
{
    // All contentObjects should be passed through the filters
    if ([[inObject type] isEqualToString:CONTENT_MESSAGE_TYPE]){
        //AIContentMessages have an attributed string for a message
        [(AIContentMessage *)inObject setMessage:[self _filterAttributedString:[(AIContentMessage *)inObject message]
                                                              forContentObject:inObject
															  listObjectContext:nil
                                                              usingFilterArray:inArray]];
    } else if  ([[inObject type] isEqualToString:CONTENT_STATUS_TYPE]){
		//AIContentStatus have a string for a message
        [(AIContentStatus *)inObject setMessage:[[self _filterAttributedString:[[[NSAttributedString alloc] initWithString:[(AIContentStatus *)inObject message]] autorelease]
                                                              forContentObject:inObject
															  listObjectContext:nil
                                                              usingFilterArray:inArray] string]];
	} else {
        [self _filterAttributedString:nil
                     forContentObject:inObject
					listObjectContext:nil
                     usingFilterArray:inArray];
    }
    
}
//Messaging -----------------------------------------------------------------------------------------------
#pragma mark Messaging
//Add an incoming content object
- (void)addIncomingContentObject:(AIContentObject *)inObject
{
    AIChat			*chat = [inObject chat];
    AIListObject 	*object = [inObject source];

    if(object){
        //Will receive content
        if([inObject trackContent]){
            [[owner notificationCenter] postNotificationName:Content_WillReceiveContent object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
        }

        //Filter the object
        if([inObject filterContent]){
            [self _filterContentObject:inObject usingFilterArray:incomingContentFilterArray];
        }

        //Add/Display the object
        if([inObject displayContent]){
			[self displayContentObject:inObject];
        }
		
        if([inObject trackContent]){
            //Did receive content
            if ([[chat contentObjectArray] count] > 1) {
                [[owner notificationCenter] postNotificationName:Content_DidReceiveContent object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject, @"Object", nil]];
            }else{
                //The content was the first recieved
                [[owner notificationCenter] postNotificationName:Content_FirstContentRecieved object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
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
    BOOL		trackContent = [inObject trackContent];		//Should Adium track this content?
    BOOL		filterContent = [inObject filterContent];   //Should Adium filter this content?
    BOOL		displayContent = [inObject displayContent]; //Should Adium display this content?
    	
    //Will send content
    if(trackContent){
        [[owner notificationCenter] postNotificationName:Content_WillSendContent
												  object:chat 
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }

    //Filter the content object
    if(filterContent){
        [self filterObject:inObject isOutgoing:YES];
    }

    //Send the object
    if([(AIAccount <AIAccount_Content> *)[inObject source] sendContentObject:inObject]){
        if(displayContent){
            //Add the object
            [self displayContentObject:inObject];
        }

        if(trackContent){
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
- (void)displayContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
    BOOL		filterContent = [inObject filterContent]; //Adium should filter this content

    //Filter the content object
    if(filterContent){
        [self filterObject:inObject isOutgoing:NO];
    }
    
    //Check if the object should display
    if ([inObject displayContent]) {
		//If the chat doesn't have content yet, open it
		if(![chat hasContent]){
			[[owner interfaceController] openChat:chat]; 
		}
		
		//Add the content to the chat
		[chat addContentObject:inObject];
		
		//Content object added
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
	AIChat			*chat;
	
	//If we're dealing with a meta contact, open a chat with the preferred contact for this meta contact
	//It's a good idea for the caller to pick the preferred contact for us, since they know the content type
	//being sent and more information - but we'll do it here as well just to be safe.
	if([inContact isKindOfClass:[AIMetaContact class]]){
		inContact = [[owner contactController] preferredContactForReceivingContentType:CONTENT_MESSAGE_TYPE
																		 forListObject:inContact];
	}
	//Search for an existing chat we can switch instead of replacing
	enumerator = [chatArray objectEnumerator];
	while(chat = [enumerator nextObject]){
		//If a chat for this object already exists
		if([chat listObject] == inContact) break;
		
		//If this object is within a meta contact, and a chat for and object in that meta contact already exists
		if([[inContact containingGroup] isKindOfClass:[AIMetaContact class]] && 
		   [[chat listObject] containingGroup] == [inContact containingGroup]){

			//If we're on a different account now, switch the chat over
			if([[inContact accountUID] compare:[(AIListContact *)[chat listObject] accountUID]] != 0){
				[self switchChat:chat
					   toAccount:[[owner accountController] accountWithServiceID:[inContact serviceID]
																			 UID:[inContact accountUID]]];
			}
			
			break;
		}
	}
	if(!chat){
		
		//evands - this is returning nil when the stress test Command listobject gets here.
		AIAccount *account = [[owner accountController] accountWithServiceID:[inContact serviceID] 
																		 UID:[inContact accountUID]];
	
		if([account conformsToProtocol:@protocol(AIAccount_Content)]){
			//Create a new chat
			chat = [AIChat chatForAccount:account];
			[chat addParticipatingListObject:inContact];
			
			//Inform the account of it's creation
			if(![(AIAccount<AIAccount_Content> *)account openChat:chat]){
				chat = nil;
			}
			
			if (chat)
				[chatArray addObject:chat];
		}
	}
	
	return(chat);
}

//Note a chat (Called by account code only, after creating a chat)
//- (void)noteChat:(AIChat *)inChat forAccount:(AIAccount *)inAccount
//{
//	AIListObject	*listObject;
//
//    //Track the chat
//    [chatArray addObject:inChat];
//	
//	//Up the chat count for this contact
//	if(listObject = [inChat listObject]){
//        int currentCount = [listObject integerStatusObjectForKey:@"ChatsCount"];
//        [listObject setStatusObject:[NSNumber numberWithInt:(currentCount + 1)]
//                             forKey:@"ChatsCount"
//                             notify:YES];
//	}
//}
//	



//Open a chat on the specified account, or returns an existing chat
//- (AIChat *)openChatOnAccount:(AIAccount *)inAccount withListObject:(AIListObject *)inListObject
//{
//    NSEnumerator	*enumerator;
//    AIChat		*chat;
//    
//    //Search for an existing chat
//    enumerator = [chatArray objectEnumerator];
//    while(chat = [enumerator nextObject]){
//        if([chat listObject] == inListObject) break;
//    }
//	
//    if(!chat || (inAccount != nil && [chat account] != inAccount) ){
//        //If no account is passed, use the default
//        if(!inAccount){
//            inAccount = [[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:inListObject];
//        }
//		
//        //Instruct the account to create a new chat
//        chat = [(id <AIAccount_Content>)inAccount openChatWithListObject:inListObject];
//		
//		//Have the interface open this chat
//		[[owner interfaceController] openChat:chat]; 
//		
//    }else{
//        //Have the interface re-open this chat
//        [[owner interfaceController] openChat:chat];    
//		
//    }
//	
//    return(chat);
//}


//Close a chat
- (BOOL)closeChat:(AIChat *)inChat
{
	AIListObject	*listObject;

    if (mostRecentChat == inChat)
        mostRecentChat = nil;
    
	//Lower the chat count for this contact
	if(listObject = [inChat listObject]){
        int currentCount = [listObject integerStatusObjectForKey:@"ChatsCount"];
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
	AIListContact	*newContact = [[owner contactController] contactWithService:[oldContact serviceID] accountUID:[newAccount UID] UID:[oldContact UID]];
	NSLog(@"Switch chat to %@",[newAccount UID]);
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
    if(mostRecentChat && [mostRecentChat listObject] && [[mostRecentChat listObject] integerStatusObjectForKey:@"UnviewedContent"]){
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
		if([account conformsToProtocol:@protocol(AIAccount_Content)]){
			if([[inObject serviceID] compare:[[[account service] handleServiceType] identifier]] == 0){
				BOOL			knowsObject = NO;
				BOOL			canFindObject = NO;
				AIListContact	*contactForAccount = [[owner contactController] existingContactWithService:[inObject serviceID]
																								accountUID:[account UID]
																									   UID:[inObject UID]];
				//Does the account know this object?
				if(contactForAccount){
					knowsObject = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:CONTENT_MESSAGE_TYPE
																							 toListObject:contactForAccount];
				}
				
				//Could the account find this object?
				canFindObject = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:CONTENT_MESSAGE_TYPE
																						   toListObject:nil];

				if((inPreferred && knowsObject) || (!inPreferred && !knowsObject && canFindObject)){
					[sourceAccounts addObject:account];
				}
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
#pragma mark Emoticons (In the core?)
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
