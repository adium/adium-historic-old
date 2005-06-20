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

#import "AdiumContentFiltering.h"
#import <Adium/NDRunLoopMessenger.h>
#import <AIUtilities/ESExpandedRecursiveLock.h>

static NDRunLoopMessenger   	*filterRunLoopMessenger = nil;
static NSLock					*filterCreationLock = nil;
static NSRecursiveLock			*mainFilterLock = nil;
static ESExpandedRecursiveLock	*threadedFilterLock = nil;

//The autorelease pool presently in use; it will be periodically released and recreated
static NSAutoreleasePool *currentAutoreleasePool = nil;
#define	AUTORELEASE_POOL_REFRESH	5.0

@interface AdiumContentFiltering (PRIVATE)
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

@implementation AdiumContentFiltering

/*!
 * @brief Init
 */
- (id)init
{
	if((self = [super init])){
		stringsRequiringPolling = [[NSMutableSet alloc] init];
	}
	
	return(self);
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{	
	[super dealloc];
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

@end
