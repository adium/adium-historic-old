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

// $Id: AIContentController.m,v 1.103 2004/08/11 23:22:47 evands Exp $

#import "AIContentController.h"

@interface AIContentController (PRIVATE)

- (void)finishReceiveContentObject:(AIContentObject *)inObject;
- (void)finishSendContentObject:(AIContentObject *)inObject;
- (void)finishDisplayContentObject:(AIContentObject *)inObject;




- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject usingFilterArray:(NSArray *)inArray;
- (NSString *)_filterString:(NSString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject/* usingFilterArray:(NSArray *)inArray*/;
- (void)_filterContentObject:(AIContentObject *)inObject usingFilterArray:(NSArray *)inArray;

- (NSArray *)_informObserversOfChatStatusChange:(AIChat *)inChat withKeys:(NSArray *)modifiedKeys silent:(BOOL)silent;
- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSArray *)inModifiedKeys;

@end

@implementation AIContentController

static NDRunLoopMessenger   *filterRunLoopMessenger = nil;

//init
- (void)initController
{
    //Text entry filtering and tracking
    textEntryFilterArray = [[NSMutableArray alloc] init];
    textEntryContentFilterArray = [[NSMutableArray alloc] init];
    textEntryViews = [[NSMutableArray alloc] init];
	chatObserverArray = [[NSMutableArray alloc] init];
    defaultFormattingAttributes = nil;
	emoticonPacks = nil;
	emoticonsArray = nil;
	
    //Chat tracking
    chatArray = [[NSMutableArray alloc] init];

    //Emoticons array
    emoticonsArray = nil;
}

//close
- (void)closeController
{

}

//dealloc
- (void)dealloc
{
	[emoticonPacks release]; emoticonPacks = nil;
	[emoticonsArray release]; emoticonsArray = nil;
    [textEntryFilterArray release];
    [textEntryContentFilterArray release];
    [textEntryViews release];
    [chatArray release];
	[chatObserverArray release]; chatObserverArray = nil;
	
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
									   context:(id)filterContext
{
	//Perform the filter in our filter thread to avoid threading conflicts, waiting for a result and then returning it
	attributedString = [[self filterRunLoopMessenger] target:self 
											 performSelector:@selector(thread_filterAttributedString:contentFilter:filterContext:invocation:) 
												  withObject:attributedString
												  withObject:contentFilter[type][direction]
												  withObject:filterContext
												  withObject:nil
												  withResult:YES];
	return (attributedString);
}

//Filters an attributed string.  If the string is associated with a contact or list object, pass that object as context.
//Selector should take two arguments.  The first will be the filtered attributedString; the second is the passed context.
//Filtration occurs in a background thread, sequentially, and will notify target at selector when complete.
- (void)filterAttributedString:(NSAttributedString *)attributedString
			   usingFilterType:(AIFilterType)type
					 direction:(AIFilterDirection)direction
				 filterContext:(id)filterContext
			   notifyingTarget:(id)target
					  selector:(SEL)selector
					   context:(id)context
{
	NSParameterAssert(type >= 0 && type < FILTER_TYPE_COUNT);
	NSParameterAssert(direction >= 0 && direction < FILTER_DIRECTION_COUNT);
	
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	
	[invocation setSelector:selector];
	[invocation setTarget:target];
	[invocation setArgument:&context atIndex:3]; //context, the second argument after the two hidden arguments of every NSInvocation
	[invocation retainArguments];
	
	[[self filterRunLoopMessenger] target:self 
						  performSelector:@selector(thread_filterAttributedString:contentFilter:filterContext:invocation:) 
							   withObject:attributedString
							   withObject:contentFilter[type][direction]
							   withObject:filterContext
							   withObject:invocation];
}

- (NDRunLoopMessenger *)filterRunLoopMessenger
{
	if (!filterRunLoopMessenger){
		[NSThread detachNewThreadSelector:@selector(thread_createFilterRunLoopMessenger) toTarget:self withObject:nil];
		
		while (!filterRunLoopMessenger);
	}
	
	return (filterRunLoopMessenger);
}

- (NSAttributedString *)thread_filterAttributedString:(NSAttributedString *)attributedString 
										contentFilter:(NSArray *)inContentFilterArray
										filterContext:(id)filterContext
										   invocation:(NSInvocation *)invocation
{
	if (attributedString){
		NSEnumerator		*enumerator = [inContentFilterArray objectEnumerator];
		id<AIContentFilter>	filter;

		while((filter = [enumerator nextObject])){
			attributedString = [filter filterAttributedString:attributedString context:filterContext];
		}
	}
	
	if (invocation){
		//Put that attributed string into the invocation as the first argument after the two hidden arguments of every NSInvocation
		[invocation setArgument:&attributedString atIndex:2];
		[invocation retainArguments]; //redundant?
		
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
	}
	
	return(attributedString);
}


//Only called once, the first time a threaded filtering is requested
- (void)thread_createFilterRunLoopMessenger
{
	NSLog(@"thread_createFilterRunLoopMessenger: creation time");
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	filterRunLoopMessenger = [NDRunLoopMessenger runLoopMessengerForCurrentRunLoop];
	[filterRunLoopMessenger setMessageRetryTimeout:3.0];
	NSLog(@"thread_createFilterRunLoopMessenger: Got %@",filterRunLoopMessenger);
	CFRunLoopRun();
	
	[pool release];
	
	filterRunLoopMessenger = nil;
	NSLog(@"thread_createFilterRunLoopMessenger: destroyed it");
}

//Messaging ------------------------------------------------------------------------------------------------------------
#pragma mark Messaging
//Add an incoming content object
- (void)receiveContentObject:(AIContentObject *)inObject
{
    AIChat			*chat = [inObject chat];
    AIListObject 	*object = [inObject source];
	
    if(object){
        //Notify: Will Receive Content
        if([inObject trackContent]){
            [[owner notificationCenter] postNotificationName:Content_WillReceiveContent
													  object:chat
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
        }

		//Run the object through our incoming content filters
        if([inObject filterContent]){
			[self filterAttributedString:[inObject message]
						 usingFilterType:AIFilterContent
							   direction:AIFilterIncoming
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:receivingContext:)
								 context:inObject];
			
        }else{
			[self finishReceiveContentObject:inObject];
		}
    }
}

- (void)didFilterAttributedString:(NSAttributedString *)filteredMessage receivingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredMessage];
	
	[self finishReceiveContentObject:inObject];
}

- (void)finishReceiveContentObject:(AIContentObject *)inObject
{
	AIChat			*chat = [inObject chat];
	NSArray			*contentObjectArray = [chat contentObjectArray];
	
	BOOL			shouldBeFirstMessage = NO;
	
	if([inObject trackContent]) {
		int		contentLength = [contentObjectArray count];
		
		// Dave's patented super-duper-uber-convoluted check for first-message-ness:
		// If (it is literally the first message in this view) OR (the previous message is context AND this one is not context)
		// Then, and only then, should we consider this a first message
		if(contentLength <= 1 || 
		   ([[(AIContentObject *)[contentObjectArray objectAtIndex:0] type] isEqualToString:CONTENT_CONTEXT_TYPE] &&
			![[inObject type] isEqualToString:CONTENT_CONTEXT_TYPE]) ){
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

//Send a content object
- (BOOL)sendContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];    	

    //Run the object through our outgoing content filters
    if([inObject filterContent]){
		[self filterAttributedString:[inObject message]
					 usingFilterType:AIFilterContent
						   direction:AIFilterOutgoing
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:contentSendingContext:)
							 context:inObject];
		
    }else{
		[self finishSendContentObject:inObject];
	}
	
	// XXX
	return YES;
}

-(void)didFilterAttributedString:(NSAttributedString *)filteredString contentSendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	//Special outgoing content filter for AIM away message bouncing.  Used to filter %n,%t,...
	if([inObject isKindOfClass:[AIContentMessage class]] && [(AIContentMessage *)inObject isAutoreply]){
		[self filterAttributedString:[inObject message]
					 usingFilterType:AIFilterAutoReplyContent
						   direction:AIFilterOutgoing
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:autoreplySendingContext:)
							 context:inObject];
	}else{		
		[self finishSendContentObject:inObject];
	}
}

-(void)didFilterAttributedString:(NSAttributedString *)filteredString autoreplySendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	[self finishSendContentObject:inObject];
}

- (void)finishSendContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
	
	//Notify: Will Send Content
    if([inObject trackContent]){
        [[owner notificationCenter] postNotificationName:Content_WillSendContent
												  object:chat 
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }
	
    //Send the object
	if ([inObject sendContent]){
		if([(AIAccount <AIAccount_Content> *)[inObject source] sendContentObject:inObject]){
			if([inObject displayContent]){
				//Add the object
				[self displayContentObject:inObject];
			}
			
			if([inObject trackContent]){
				//Did send content
				[[owner notificationCenter] postNotificationName:Content_DidSendContent 
														  object:chat 
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
			}
			
			mostRecentChat = chat;
//			sent = YES;
		}
	}else{
		//We shouldn't send the content, so something was done with it.. clear the text entry view
		[[owner notificationCenter] postNotificationName:Interface_ShouldClearTextEntryView
												  object:chat 
												userInfo:nil];
	}
	
//    return(sent);
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters
{
	if (useContentFilters){
		[self filterAttributedString:[inObject message]
					 usingFilterType:AIFilterContent
						   direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:contentFilterDisplayContext:)
							 context:inObject];
	}else{
		[self displayContentObject:inObject];
	}
}

- (void)didFilterAttributedString:(NSAttributedString *)filteredString contentFilterDisplayContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];
	
	[self displayContentObject:inObject];
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject
{
    //Filter the content object
    if([inObject filterContent]){
		BOOL message = ([inObject isKindOfClass:[AIContentMessage class]] && ![(AIContentMessage *)inObject isAutoreply]);
		[self filterAttributedString:[inObject message]
					 usingFilterType:(message ? AIFilterMessageDisplay : AIFilterDisplay)
						   direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:displayContext:)
							 context:inObject];
    }else{
		[self finishDisplayContentObject:inObject];
	}

}

- (void)didFilterAttributedString:(NSAttributedString *)filteredString displayContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];
	
	[self finishDisplayContentObject:inObject];
}

- (void)finishDisplayContentObject:(AIContentObject *)inObject
{
    //Check if the object should display
    if([inObject displayContent]){
		AIChat		*chat = [inObject chat];

		//Tell the interface to open the chat
		//For incoming messages, we don't open the chat until we're sure that new content is being received.
		//This is only necessary for the first incoming message.  The quickest way to check this is checking whether
		//the chat already has content or not.  If there is content, this is not the first message.
		if(![chat hasContent]) [[owner interfaceController] openChat:chat]; 
		
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



//Chat Status -------------------------------------------------------------------------------------------------
#pragma mark Chat Status

//Registers code to observe handle status changes
- (void)registerChatObserver:(id <AIChatObserver>)inObserver
{
	//Add the observer
    [chatObserverArray addObject:inObserver];
	
    //Let the new observer process all existing chats
	[self updateAllChatsForObserver:inObserver];
}

- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver
{
    [chatObserverArray removeObject:inObserver];
}

- (void)chatStatusChanged:(AIChat *)inChat modifiedStatusKeys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	NSArray			*modifiedAttributeKeys;
	
    //Let all observers know the contact's status has changed before performing any further notifications
	modifiedAttributeKeys = [self _informObserversOfChatStatusChange:inChat withKeys:inModifiedKeys silent:silent];

    //Post an attributes changed message (if necessary)
    if([modifiedAttributeKeys count]){
		[self chatAttributesChanged:inChat modifiedKeys:modifiedAttributeKeys];
    }	
}

- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSArray *)inModifiedKeys
{
	//Post an attributes changed message
	[[owner notificationCenter] postNotificationName:Chat_AttributesChanged
											  object:inChat
											userInfo:(inModifiedKeys ? [NSDictionary dictionaryWithObject:inModifiedKeys 
																								   forKey:@"Keys"] : nil)];
}

//Send a chatStatusChanged message for each open chat with a nil modifiedStatusKeys array
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer
{
	NSEnumerator	*enumerator = [chatArray objectEnumerator];
	AIChat			*chat;
	
	while (chat = [enumerator nextObject]){
		[self chatStatusChanged:chat modifiedStatusKeys:nil silent:NO];
	}
}

//Notify observers of a status change.  Returns the modified attribute keys
- (NSArray *)_informObserversOfChatStatusChange:(AIChat *)inChat withKeys:(NSArray *)modifiedKeys silent:(BOOL)silent
{
	NSMutableArray				*attrChange = nil;
	NSEnumerator				*enumerator;
    id <AIChatObserver>	observer;

	//Let our observers know
	enumerator = [chatObserverArray objectEnumerator];
	while((observer = [enumerator nextObject])){
		NSArray	*newKeys;
		
		if(newKeys = [observer updateChat:inChat keys:modifiedKeys silent:silent]){
			if (!attrChange) attrChange = [NSMutableArray array];
			[attrChange addObjectsFromArray:newKeys];
		}
	}
	
	//Send out the notification for other observers
	[[owner notificationCenter] postNotificationName:Chat_StatusChanged
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

	if(chat) [[owner interfaceController] openChat:chat]; 

	return(chat);	
}

//Creates a chat for communication with the contact, but does not make the chat active (Doesn't open a chat window)
//If a chat already exists it will be returned
- (AIChat *)chatWithContact:(AIListContact *)inContact
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	
	//If we're dealing with a meta contact, open a chat with the preferred contact for this meta contact
	//It's a good idea for the caller to pick the preferred contact for us, since they know the content type
	//being sent and more information - but we'll do it here as well just to be safe.
#warning WRONG
	if ([inContact isKindOfClass:[AIMetaContact class]]){
		inContact = [[owner contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
															   forListContact:inContact];
	}
	
	//Search for an existing chat we can switch instead of replacing
	enumerator = [chatArray objectEnumerator];
	while(chat = [enumerator nextObject]){
		//If a chat for this object already exists
		if([[chat uniqueChatID] isEqualToString:[inContact uniqueObjectID]]) {
			if (!([chat listObject] == inContact)){
				[self switchChat:chat
					   toAccount:[[owner accountController] accountWithObjectID:[inContact accountID]]];
			}
			
			break;
		}
		
		//If this object is within a meta contact, and a chat for and object in that meta contact already exists
		if([[inContact containingObject] isKindOfClass:[AIMetaContact class]] && 
		   [[chat listObject] containingObject] == [inContact containingObject]){

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
			chat = [AIChat chatForAccount:account];
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

- (AIChat *)existingChatWithContact:(AIListContact *)inContact
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
	
	//Search for an existing chat
	enumerator = [chatArray objectEnumerator];
	while(chat = [enumerator nextObject]){
		//If a chat for this object already exists
		if([chat listObject] == inContact) break;
	}
	
	return chat;
}

- (AIChat *)chatWithName:(NSString *)inName onAccount:(AIAccount *)account chatCreationInfo:(NSDictionary *)chatCreationInfo
{
	AIChat			*chat = nil;
	
	//Search for an existing chat we can use instead of creating a new one
	chat = [self existingChatWithName:inName onAccount:account];
	
	if (!chat){
		if([account conformsToProtocol:@protocol(AIAccount_Content)]){
			//Create a new chat
			chat = [AIChat chatForAccount:account];
			[chat setName:inName];
			[chatArray addObject:chat];
			
			if (chatCreationInfo) [chat setStatusObject:chatCreationInfo
												 forKey:@"ChatCreationInfo"
												 notify:NotifyNever];
			
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

- (AIChat *)existingChatWithName:(NSString *)inName onAccount:(AIAccount *)account
{
	NSEnumerator	*enumerator;
	AIChat			*chat = nil;
	NSString		*uniqueChatID;
	
	enumerator = [chatArray objectEnumerator];
	uniqueChatID = [AIChat uniqueChatIDForChatWithName:inName onAccount:account];
	while(chat = [enumerator nextObject]){
		
		//If the chat we want already exists
		if([[chat uniqueChatID] isEqualToString:uniqueChatID]) break;
	}	
	
	return chat;
}

//Close a chat
- (BOOL)closeChat:(AIChat *)inChat
{
    if(mostRecentChat == inChat)
        mostRecentChat = nil;
    
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
	AIChat  *newActiveChat = nil;
	
    if(mostRecentChat && [mostRecentChat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]){
		//First choice: switch to the chat which received chat most recently if it has unviewed content
		newActiveChat = mostRecentChat;
		
	}else{
		//Second choice: switch to the first chat we can find which has unviewed content
		NSEnumerator	*enumerator = [chatArray objectEnumerator];
		AIChat			*chat;
		while ((chat = [enumerator nextObject]) && ![chat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]);
		
		if (chat) newActiveChat = chat;
	}

	if (newActiveChat){
		//If either the first or second choice was made, set the new active chat and return YES
		[[owner interfaceController] setActiveChat:newActiveChat];
		return(YES);
		
    }else{
		//Third choice: don't switch, returning NO
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
	[emoticonPacks release];
    emoticonPacks = [inEmoticonPacks retain];
}
- (NSArray *)emoticonPacks
{
    return emoticonPacks;   
}
//emoticonsArray is an array of all AIEmoticon objects in the active emoticon set, maintained by the Emoticons plugin
- (void)setEmoticonsArray:(NSArray *)inEmoticonsArray
{
	[emoticonsArray release];
    emoticonsArray = [inEmoticonsArray retain];
}
- (NSArray *)emoticonsArray
{
    return emoticonsArray;   
}

@end
