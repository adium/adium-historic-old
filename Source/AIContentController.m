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

// $Id$

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AdiumTyping.h"
#import "ESContactAlertsController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/ESExpandedRecursiveLock.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/NDRunLoopMessenger.h>

@interface AIContentController (PRIVATE)

- (void)finishReceiveContentObject:(AIContentObject *)inObject;
- (void)finishSendContentObject:(AIContentObject *)inObject;
- (void)finishDisplayContentObject:(AIContentObject *)inObject;

- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject usingFilterArray:(NSArray *)inArray;
- (NSString *)_filterString:(NSString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject/* usingFilterArray:(NSArray *)inArray*/;
- (void)_filterContentObject:(AIContentObject *)inObject usingFilterArray:(NSArray *)inArray;
- (NSAttributedString *)thread_filterAttributedString:(NSAttributedString *)attributedString contentFilter:(NSArray *)inContentFilterArray filterContext:(id)filterContext invocation:(NSInvocation *)invocation;
- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)attributedString contentFilter:(NSArray *)inContentFilterArray filterContext:(id)filterContext usingLock:(NSRecursiveLock *)inLock;

- (NSAttributedString *)thread_filterAttributedString:(NSAttributedString *)attributedString 
										contentFilter:(NSArray *)inContentFilterArray
								threadedContentFilter:(NSArray *)inThreadedContentFilterArray
										filterContext:(id)filterContext
										   invocation:(NSInvocation *)invocation;
@end

/*
 * @class AIContentController
 * @brief Controller to manage incoming and outgoing content and chats.
 *
 * This controller handles default formatting and text entry filters, which can respond as text is entered in a message
 * window.  It the center for content filtering, including registering/unregistering of content filters.
 * It handles sending and receiving of content objects.  It manages chat observers, which are objects notified as
 * status objects are set and removed on AIChat objects.  It manages chats themselves, tracking open ones, closing
 * them when needed, etc.  Finally, it provides Events related to sending and receiving content, such as Message Received.
 */
@implementation AIContentController

static NDRunLoopMessenger   *filterRunLoopMessenger = nil;
static NSLock				*filterCreationLock = nil;
static NSRecursiveLock		*mainFilterLock = nil;
static ESExpandedRecursiveLock	*threadedFilterLock = nil;

//The autorelease pool presently in use; it will be periodically released and recreated
static NSAutoreleasePool *currentAutoreleasePool = nil;
#define	AUTORELEASE_POOL_REFRESH	5.0

/*
 * @brief Initialize the controller
 */
- (id)init
{
	if ((self = [super init])) {
		adiumTyping = [[AdiumTyping alloc] init];
		adiumFormatting = [[AdiumFormatting alloc] init];
		
		
		//Text entry filtering and tracking
		textEntryFilterArray = [[NSMutableArray alloc] init];
		textEntryContentFilterArray = [[NSMutableArray alloc] init];
		textEntryViews = [[NSMutableArray alloc] init];
		emoticonPacks = nil;
		emoticonsArray = nil;
		
		objectsBeingReceived = [[NSMutableSet alloc] init];
		stringsRequiringPolling = [[NSMutableSet alloc] init];
	
		//Emoticons array
		emoticonsArray = nil;
		
	}
	
	return self;
}

- (void)controllerDidLoad
{
	//Message events
	messageEvents = [[AdiumMessageEvents alloc] init];

	[adiumFormatting controllerDidLoad];
}

/*
 * @brief Close the controller
 */
- (void)controllerWillClose
{
	[adiumTyping release];
	[adiumFormatting release];
	
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	
	[emoticonPacks release]; emoticonPacks = nil;
	[emoticonsArray release]; emoticonsArray = nil;
    [textEntryFilterArray release];
    [textEntryContentFilterArray release];
    [textEntryViews release];
	[objectsBeingReceived release];

    [super dealloc];
}




#pragma mark Typing
- (void)userIsTypingContentForChat:(AIChat *)chat hasEnteredText:(BOOL)hasEnteredText {
	[adiumTyping userIsTypingContentForChat:chat hasEnteredText:hasEnteredText];
}

#pragma mark Formatting
- (NSDictionary *)defaultFormattingAttributes {
	return [adiumFormatting defaultFormattingAttributes];
}








//Content Filtering ----------------------------------------------------------------------------------------------------
#pragma mark Content Filtering
//Register a content filter.  If the particular filter wants to apply to multiple types or directions, it should
//register multiple times.  Be careful that incoming content is always contained (aka: Don't feed incoming content
//to a shell script or something silly like that).
- (void)registerContentFilter:(id<AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction
{
	[self registerContentFilter:inFilter
						 ofType:type
					  direction:direction
					   threaded:NO];
}

int filterSort(id<AIContentFilter> filterA, id<AIContentFilter> filterB, void *context) {
	float filterPriorityA = [filterA filterPriority];
	float filterPriorityB = [filterB filterPriority];
	
	if (filterPriorityA < filterPriorityB)
		return NSOrderedAscending;
	else if (filterPriorityA > filterPriorityB)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

- (void)registerContentFilter:(id<AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction
					 threaded:(BOOL)threaded
{
	NSParameterAssert(inFilter != nil);
	NSParameterAssert(type >= 0 && type < FILTER_TYPE_COUNT);
	NSParameterAssert(direction >= 0 && direction < FILTER_DIRECTION_COUNT);

	if (!(threaded ? threadedContentFilter : contentFilter)[type][direction]) {
		(threaded ? threadedContentFilter : contentFilter)[type][direction] = [[NSMutableArray alloc] init];
	}
	
	NSMutableArray	*currentContentFilter = (threaded ? threadedContentFilter : contentFilter)[type][direction];
	[currentContentFilter addObject:inFilter];
	[currentContentFilter sortUsingFunction:filterSort context:nil];
}

//Unregister all instances of filter.
- (void)unregisterContentFilter:(id<AIContentFilter>)inFilter
{
	NSParameterAssert(inFilter != nil);

	int i, j;
	for (i = 0; i < FILTER_TYPE_COUNT; i++) {
		for (j = 0; j < FILTER_DIRECTION_COUNT; j++) {
			[contentFilter[i][j] removeObject:inFilter];
			[threadedContentFilter[i][j] removeObject:inFilter];
		}
	}
}

//Register a string which, if present when filtering for a potentiall autorefreshing string, requires polling to be updated
- (void)registerFilterStringWhichRequiresPolling:(NSString *)inPollString
{
	[stringsRequiringPolling addObject:inPollString];
}

//Is polling required to update the passed string?
- (BOOL)shouldPollToUpdateString:(NSString *)inString
{
	NSEnumerator	*enumerator;
	NSString		*stringRequiringPolling;
	BOOL			shouldPoll = NO;
	
	enumerator = [stringsRequiringPolling objectEnumerator];
	while ((stringRequiringPolling = [enumerator nextObject])) {
		if ([inString rangeOfString:stringRequiringPolling].location != NSNotFound) {
			shouldPoll = YES;
			break;
		}
	}
	
	return shouldPoll;
}

#define THREADED_FILTERING TRUE

//Filters an attributed string.  If the string is associated with a contact or list object, pass that object as context.
//This only performs main thread filters.
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)attributedString
							   usingFilterType:(AIFilterType)type
									 direction:(AIFilterDirection)direction
									   context:(id)filterContext
{
	//Perform the filter (in the main thread)
	attributedString = [self _filterAttributedString:attributedString
									   contentFilter:contentFilter[type][direction]
									   filterContext:filterContext
										   usingLock:mainFilterLock];
	
	return (attributedString);
}


//Perform the filtering of an attributedString on the specified content filter. Pass filterContext while filtering.
//Either thread may use this function, but no two threads should be using filters from the same content array at once.
- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)attributedString
								  contentFilter:(NSArray *)inContentFilterArray
								  filterContext:(id)filterContext
									  usingLock:(NSRecursiveLock *)inLock
{
	NSEnumerator		*enumerator = [inContentFilterArray objectEnumerator];
	id<AIContentFilter>	filter;
	
	[inLock lock];
	while ((filter = [enumerator nextObject])) {
		attributedString = [filter filterAttributedString:attributedString context:filterContext];
	}
	[inLock unlock];
	
	return(attributedString);
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

#if THREADED_FILTERING
	//Now request the asynchronous filtering
	[[self filterRunLoopMessenger] target:self 
						  performSelector:@selector(thread_filterAttributedString:contentFilter:threadedContentFilter:filterContext:invocation:) 
							   withObject:attributedString
							   withObject:contentFilter[type][direction]
							   withObject:threadedContentFilter[type][direction]
							   withObject:filterContext
							   withObject:invocation];
#else
	//Synchronous filtering
	[self thread_filterAttributedString:attributedString
						  contentFilter:contentFilter[type][direction]
				  threadedContentFilter:threadedContentFilter[type][direction]
						  filterContext:filterContext
							 invocation:invocation];
#endif
}

- (NDRunLoopMessenger *)filterRunLoopMessenger
{
	if (!filterRunLoopMessenger) {
		if (!filterCreationLock) filterCreationLock = [[NSLock alloc] init];
		[filterCreationLock lock];
		
		[NSThread detachNewThreadSelector:@selector(thread_createFilterRunLoopMessenger) toTarget:self withObject:nil];
		
		[filterCreationLock lockBeforeDate:[NSDate distantFuture]];
		[filterCreationLock release]; filterCreationLock = nil;
	}
	
	return (filterRunLoopMessenger);
}

- (NSAttributedString *)thread_filterAttributedString:(NSAttributedString *)attributedString 
										contentFilter:(NSArray *)inContentFilterArray
										threadedContentFilter:(NSArray *)inThreadedContentFilterArray
										filterContext:(id)filterContext
										   invocation:(NSInvocation *)invocation
{
	if (attributedString) {
		//Perform the main filters
		attributedString = [self _filterAttributedString:attributedString
										   contentFilter:inContentFilterArray
										   filterContext:filterContext
											   usingLock:mainFilterLock];
		
		/*
		 Now perform the threaded-only filters.
		 
		 The threadedFilterLock also serves as a way to know if a filtering operation is currently in progress.
		 Running a filter may take multiple run loops (e.g. applescript execution).
		 It is not acceptable for our autorelease pool to be released between these loops
		 as we have autoreleased objects upon which we are depending; we can check against the lock
		 using isUnlocked (non-blocking) to know if it is safe.
		 */
		attributedString = [self _filterAttributedString:attributedString
										   contentFilter:inThreadedContentFilterArray
										   filterContext:filterContext
											   usingLock:threadedFilterLock];
	}
	
	if (invocation) {
		//Put that attributed string into the invocation as the first argument after the two hidden arguments of every NSInvocation
		[invocation setArgument:&attributedString atIndex:2];
		[invocation retainArguments]; //redundant?
		
		//Send the filtered attributedString back via invocation, on the main thread
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
	}
	
	return(attributedString);
}

//Only called once, the first time a threaded filtering is requested
- (void)thread_createFilterRunLoopMessenger
{
	NSTimer				*autoreleaseTimer;
	
	//Create an initial autorelease pool
	currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	//We will want to periodically release and recreate the autorelease pool to avoid collecting memory usage
	autoreleaseTimer = [[NSTimer scheduledTimerWithTimeInterval:AUTORELEASE_POOL_REFRESH
														target:self
													  selector:@selector(refreshAutoreleasePool:)
													  userInfo:nil
													   repeats:YES] retain];
	
	//Initialize the lock used to coordinate threading the main vs. the filter thread
	threadedFilterLock = [[ESExpandedRecursiveLock alloc] init];
	mainFilterLock = [[NSRecursiveLock alloc] init];
	
	//Create and configure our messenger to the filter thread (in which we are at present)
	filterRunLoopMessenger = [[NDRunLoopMessenger runLoopMessengerForCurrentRunLoop] retain];
	[filterRunLoopMessenger setMessageRetryTimeout:3.0];

	//The run loop messenger has now been created
	[filterCreationLock unlock];

	//CFRunLoop() will not exit until Adium does
	CFRunLoopRun();

	[autoreleaseTimer invalidate]; [autoreleaseTimer release];
	[filterRunLoopMessenger release]; filterRunLoopMessenger = nil;
	[threadedFilterLock release]; threadedFilterLock = nil;
	[mainFilterLock release]; mainFilterLock = nil;
	[currentAutoreleasePool release];
}

//Our autoreleased objects will only be released when the outermost autorelease pool is released.
//This is handled automatically in the main thread, but we need to do it manually here.
//Release the current pool, then create a new one.
- (void)refreshAutoreleasePool:(NSTimer *)inTimer
{
	if ([threadedFilterLock isUnlocked]) {
		[currentAutoreleasePool release];
		currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
	}
}

//Messaging ------------------------------------------------------------------------------------------------------------
#pragma mark Messaging
//Receiving step 1: Add an incoming content object - entry point
- (void)receiveContentObject:(AIContentObject *)inObject
{
	if (inObject) {
		AIChat			*chat = [inObject chat];

		//Only proceed if the contact is not ignored
		if (![chat isListContactIgnored:[inObject source]]) {
			//Notify: Will Receive Content
			if ([inObject trackContent]) {
				[[adium notificationCenter] postNotificationName:Content_WillReceiveContent
														  object:chat
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
			}
			
			//Track that we are in the process of receiving this object
			[objectsBeingReceived addObject:inObject];
			
			//Run the object through our incoming content filters
			if ([inObject filterContent]) {
				[self filterAttributedString:[inObject message]
							 usingFilterType:AIFilterContent
								   direction:AIFilterIncoming
							   filterContext:inObject
							 notifyingTarget:self
									selector:@selector(didFilterAttributedString:receivingContext:)
									 context:inObject];
				
			} else {
				[self finishReceiveContentObject:inObject];
			}
		}
    }
}

//Receiving step 2: filtering callback
- (void)didFilterAttributedString:(NSAttributedString *)filteredMessage receivingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredMessage];
	
	[self finishReceiveContentObject:inObject];
}

//Receiving step 3: Display the content
- (void)finishReceiveContentObject:(AIContentObject *)inObject
{
	//Display the content
	[self displayContentObject:inObject];
}

//Sending step 1: Entry point for any method in Adium which sends content
- (BOOL)sendContentObject:(AIContentObject *)inObject
{
    //Run the object through our outgoing content filters
    if ([inObject filterContent]) {
		[self filterAttributedString:[inObject message]
					 usingFilterType:AIFilterContent
						   direction:AIFilterOutgoing
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:contentSendingContext:)
							 context:inObject];
		
    } else {
		[self finishSendContentObject:inObject];
	}
	
	// XXX
	return YES;
}

//Sending step 2: Sending filter callback
-(void)didFilterAttributedString:(NSAttributedString *)filteredString contentSendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	//Special outgoing content filter for AIM away message bouncing.  Used to filter %n,%t,...
	if ([inObject isKindOfClass:[AIContentMessage class]] && [(AIContentMessage *)inObject isAutoreply]) {
		[self filterAttributedString:[inObject message]
					 usingFilterType:AIFilterAutoReplyContent
						   direction:AIFilterOutgoing
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:autoreplySendingContext:)
							 context:inObject];
	} else {		
		[self finishSendContentObject:inObject];
	}
}

//Sending step 3, applicable only when sending an autreply: Filter callback
-(void)didFilterAttributedString:(NSAttributedString *)filteredString autoreplySendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	[self finishSendContentObject:inObject];
}

//Sending step 4: Post notifications and ask the account to actually send the content.
- (void)finishSendContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
	
	//Notify: Will Send Content
    if ([inObject trackContent]) {
        [[adium notificationCenter] postNotificationName:Content_WillSendContent
												  object:chat 
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }
	
    //Send the object
	if ([inObject sendContent]) {
		if ([(AIAccount *)[inObject source] sendContentObject:inObject]) {
			if ([inObject displayContent]) {
				//Add the object
				[self displayContentObject:inObject];
			}
			
			if ([inObject trackContent]) {
				//Did send content
				[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_SENT
												 forListObject:[chat listObject]
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:chat,@"AIChat",inObject,@"AIContentObject",nil]
								  previouslyPerformedActionIDs:nil];				
			}

			//			sent = YES;
		}
	} else {
		//We shouldn't send the content, so something was done with it.. clear the text entry view
		//XXX - Nobody is observing this notification... -ai
		[[adium notificationCenter] postNotificationName:Interface_ShouldClearTextEntryView
												  object:chat 
												userInfo:nil];
	}
	
//    return(sent);
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters
{
	[self displayContentObject:inObject usingContentFilters:useContentFilters immediately:NO];
}

//Immediately YES means the main thread will halt until the content object is displayed;
//Immediately NO shuffles it off into the filtering thread, which will handle content sequentially but allows the main
//thread to continue operation.  
//This facility primarily exists for message history, which needs to put its display in before the first message;
//without this, the use of threaded filtering means that message history shows up after the first message.
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters immediately:(BOOL)immediately
{
	if (useContentFilters) {
		
		if (immediately) {
			//Filter in the main thread, set the message, and continue
			[inObject setMessage:[self filterAttributedString:[inObject message]
											  usingFilterType:AIFilterContent
													direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
													  context:inObject]];
			[self displayContentObject:inObject immediately:YES];
			
			
		} else {
			//Filter in the filter thread
			[self filterAttributedString:[inObject message]
						 usingFilterType:AIFilterContent
							   direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:contentFilterDisplayContext:)
								 context:inObject];
		}
	} else {
		//Just continue
		[self displayContentObject:inObject immediately:immediately];
	}
}

- (void)didFilterAttributedString:(NSAttributedString *)filteredString contentFilterDisplayContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];
	
	//Continue
	[self displayContentObject:inObject immediately:NO];
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject
{
	[self displayContentObject:inObject immediately:NO];
}

- (void)displayContentObject:(AIContentObject *)inObject immediately:(BOOL)immediately
{
    //Filter the content object
    if ([inObject filterContent]) {
		BOOL				message = ([inObject isKindOfClass:[AIContentMessage class]] && ![(AIContentMessage *)inObject isAutoreply]);
		AIFilterType		filterType = (message ? AIFilterMessageDisplay : AIFilterDisplay);
		AIFilterDirection	direction = ([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming);
		
		if (immediately) {
			
			//Set it after filtering in the main thread, then display it
			[inObject setMessage:[self filterAttributedString:[inObject message]
											  usingFilterType:filterType
													direction:direction
													  context:inObject]];
			[self finishDisplayContentObject:inObject];		
			
		} else {
			//Filter in the filtering thread
			[self filterAttributedString:[inObject message]
						 usingFilterType:filterType
							   direction:direction
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:displayContext:)
								 context:inObject];
		}
		
    } else {
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
    if ([inObject displayContent] && ([[inObject message] length] > 0)) {
		AIChat			*chat = [inObject chat];
		NSDictionary	*userInfo;
		BOOL			contentReceived, shouldPostContentReceivedEvents, chatIsOpen;

		//If the chat of the content object has been cleared, we can't do anything with it, so simply return
		if (!chat) return;
		
		chatIsOpen = [chat isOpen];
		contentReceived = (([inObject isMemberOfClass:[AIContentMessage class]]) &&
						   (![inObject isOutgoing]));
		shouldPostContentReceivedEvents = contentReceived && [inObject trackContent];
		
		if (!chatIsOpen) {
			/*
			 Tell the interface to open the chat
			 For incoming messages, we don't open the chat until we're sure that new content is being received.
			 */
			[[adium interfaceController] openChat:chat];
		}

		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:chat, @"AIChat", inObject, @"AIContentObject", nil];

		if (shouldPostContentReceivedEvents) {
			NSSet			*previouslyPerformedActionIDs = nil;
			AIListObject	*listObject = [chat listObject];
			
			if (!chatIsOpen) {
				//If the chat wasn't open before, generate CONTENT_MESSAGE_RECEIVED_FIRST
				previouslyPerformedActionIDs = [[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED_FIRST
																				forListObject:listObject
																					 userInfo:userInfo
																 previouslyPerformedActionIDs:nil];	
			}
			
			if (chat != [[adium interfaceController] activeChat]) {
				//If the chat is not currently active, generate CONTENT_MESSAGE_RECEIVED_BACKGROUND
				previouslyPerformedActionIDs = [[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED_BACKGROUND
																				forListObject:listObject
																					 userInfo:userInfo
																 previouslyPerformedActionIDs:previouslyPerformedActionIDs];
			}
			
			[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED
											 forListObject:listObject
												  userInfo:userInfo
							  previouslyPerformedActionIDs:previouslyPerformedActionIDs];
		}
		
		//Add this content to the chat
		[chat addContentObject:inObject];

		//Notify: Content Object Added
		[[adium notificationCenter] postNotificationName:Content_ContentObjectAdded
												  object:chat
												userInfo:userInfo];		
    }

	//We are no longer in the process of receiving this object
	[objectsBeingReceived removeObject:inObject];
	AILog(@"objectsBeingReceived: %@",([objectsBeingReceived count] ? [objectsBeingReceived description] : @"(empty)"));
}

/*
 * @brief Is the passed chat currently receiving content?
 *
 * Note: This may be irrelevent if threaded filtering is removed.
 */
- (BOOL)chatIsReceivingContent:(AIChat *)inChat
{
	BOOL isReceivingContent = NO;

	NSEnumerator	*objectsBeingReceivedEnumerator = [objectsBeingReceived objectEnumerator];
	AIContentObject	*contentObject;
	while ((contentObject = [objectsBeingReceivedEnumerator nextObject])) {
		if ([contentObject chat] == inChat) {
			isReceivingContent = YES;
			break;
		}
	}

	return isReceivingContent;
}

- (void)displayStatusMessage:(NSString *)message ofType:(NSString *)type inChat:(AIChat *)inChat
{
	AIContentStatus		*content;
	NSAttributedString	*attributedMessage;
	
	//Create our content object
	attributedMessage = [[NSAttributedString alloc] initWithString:message
														attributes:[self defaultFormattingAttributes]];
	content = [AIContentStatus statusInChat:inChat
								 withSource:[inChat listObject]
								destination:[inChat account]
									   date:[NSDate date]
									message:attributedMessage
								   withType:type];
	[attributedMessage release];

	//Add the object
	[self receiveContentObject:content];
}

//Returns YES if the account/chat is available for sending content
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact onAccount:(AIAccount *)inAccount 
{
	return([inAccount availableForSendingContentType:inType toContact:inContact]);
}

//Content Source & Destination -----------------------------------------------------------------------------------------
#pragma mark Content Source & Destination
//Returns the available contacts for receiving content to a specific contact
- (NSArray *)destinationObjectsForContentType:(NSString *)inType
								 toListObject:(AIListObject *)inObject
									preferred:(BOOL)inPreferred
{
	//meta contact special case here, return any contacts in the user defined meta contact
	return([NSArray arrayWithObject:inObject]);
}

/*! 
* @brief Generate a menu of encryption preference choices
*/
- (NSMenu *)encryptionMenuNotifyingTarget:(id)target withDefault:(BOOL)withDefault
{
	NSMenu		*encryptionMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSMenuItem	*menuItem;

	[encryptionMenu setTitle:ENCRYPTION_MENU_TITLE];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Disable chat encryption",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Never];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Encrypt chats as requested",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Manually];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Encrypt chats automatically",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Automatically];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Force encryption and refuse plaintext",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_RejectUnencryptedMessages];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	if (withDefault) {
		[encryptionMenu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Default",nil)
														  target:target
														  action:@selector(selectedEncryptionPreference:)
												   keyEquivalent:@""];
		
		[menuItem setTag:EncryptedChat_Default];
		[encryptionMenu addItem:menuItem];
		[menuItem release];
	}
	
	return [encryptionMenu autorelease];
}

@end
