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

@interface AdiumContentFiltering (PRIVATE)
- (void)_registerContentFilter:(id)inFilter
				   filterArray:(NSMutableArray *)inFilterArray;

- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)attributedString
								  contentFilter:(NSArray *)inContentFilterArray
								  filterContext:(id)filterContext;

int filterSort(id<AIContentFilter> filterA, id<AIContentFilter> filterB, void *context);

@end

@implementation AdiumContentFiltering

/*!
 * @brief Init
 */
- (id)init
{
	if((self = [super init])){
		stringsRequiringPolling = [[NSMutableSet alloc] init];
		delayedFilteringDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{	
	[stringsRequiringPolling release];
	[delayedFilteringDict release];

	[super dealloc];
}


//Content Filtering ----------------------------------------------------------------------------------------------------
#pragma mark Content Filtering
/*
 * @brief Register a content filter.
 *
 * If the particular filter wants to apply to multiple types or directions, it should register multiple times.
 */
- (void)registerContentFilter:(id<AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction
{
	NSParameterAssert(type >= 0 && type < FILTER_TYPE_COUNT);
	NSParameterAssert(direction >= 0 && direction < FILTER_DIRECTION_COUNT);

	if (!contentFilter[type][direction]) {
		contentFilter[type][direction] = [[NSMutableArray alloc] init];
	}
	
	[self _registerContentFilter:inFilter
					 filterArray:contentFilter[type][direction]];
}

/*
 * @brief Register a delayed content filter
 *
 * Delayed content filters return YES or NO from their filter method; YES means they began a filtering process.
 * When finished, the filter is responsible for notifying this class that the attributed string is ready.
 * A unique ID will be passed to identify each string.
 */
- (void)registerDelayedContentFilter:(id<AIDelayedContentFilter>)inFilter
							  ofType:(AIFilterType)type
						   direction:(AIFilterDirection)direction
{
	NSParameterAssert(type >= 0 && type < FILTER_TYPE_COUNT);
	NSParameterAssert(direction >= 0 && direction < FILTER_DIRECTION_COUNT);

	if (!delayedContentFilter[type][direction]) {
		delayedContentFilter[type][direction] = [[NSMutableArray alloc] init];
	}
	
	[self _registerContentFilter:inFilter
					 filterArray:delayedContentFilter[type][direction]];
}

/*
 * @brief Add a content filter to the specified array
 *
 * Adds, then sorts by priority
 */
- (void)_registerContentFilter:(id)inFilter
				   filterArray:(NSMutableArray *)inFilterArray
{
	NSParameterAssert(inFilter != nil);
	
	[inFilterArray addObject:inFilter];
	[inFilterArray sortUsingFunction:filterSort context:nil];	
}

/*
 * @brief Unregister a filter.
 *
 * Looks in both contentFilter and delayedContentFilter, for all types and directions
 */
- (void)unregisterContentFilter:(id<AIContentFilter>)inFilter
{
	NSParameterAssert(inFilter != nil);

	int i, j;
	for (i = 0; i < FILTER_TYPE_COUNT; i++) {
		for (j = 0; j < FILTER_DIRECTION_COUNT; j++) {
			[contentFilter[i][j] removeObject:inFilter];
			[delayedContentFilter[i][j] removeObject:inFilter];
		}
	}
}

/*
 * @brief Register a string to be filtered which requires polling to be updated
 */
- (void)registerFilterStringWhichRequiresPolling:(NSString *)inPollString
{
	[stringsRequiringPolling addObject:inPollString];
}

/*
 * @brief Is polling required to update the passed string?
 */
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

/*
 * @brief Filter an attributed string immediately
 *
 * This does not perform delayed filters.
 *
 * @param attributedString NSAttributedString to filter
 * @param type Type of the filter
 * @param direction Direction of the filter
 * @param filterContext A object, such as an AIListContact or an AIAccount, used as context by filters
 * @result The filtered attributed string, which may be the same as attributedString
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)attributedString
							   usingFilterType:(AIFilterType)type
									 direction:(AIFilterDirection)direction
									   context:(id)filterContext
{
	attributedString = [self _filterAttributedString:attributedString
									   contentFilter:contentFilter[type][direction]
									   filterContext:filterContext];
	
	return attributedString;
}


/*
 * @brief Perform the filtering of an attributedString on the specified content filter.
 *
 * @param attributedString NSAttributedString to filter
 * @param inContentFilterArray Array of filters to use
 * @param filtercontext Passed to each filter as context.
 * @result The filtered NSAttributedString, which may be the same as attributedString
 */
- (NSAttributedString *)_filterAttributedString:(NSAttributedString *)attributedString
								  contentFilter:(NSArray *)inContentFilterArray
								  filterContext:(id)filterContext
{
	NSEnumerator		*enumerator = [inContentFilterArray objectEnumerator];
	id<AIContentFilter>	filter;
	
	while ((filter = [enumerator nextObject])) {
		attributedString = [filter filterAttributedString:attributedString context:filterContext];
	}
	
	return attributedString;
}

/*
 * @brief Begin delayed filtering of an attributedString
 *
 * @result YES if any delayed filtering began; NO if it did not
 */
- (BOOL)_delayedFilterAttributedString:(NSAttributedString *)attributedString
						 contentFilter:(NSArray *)inContentFilterArray
						 filterContext:(id)filterContext
				 uniqueDelayedFilterID:(unsigned long long)uniqueID
{
	NSEnumerator				*enumerator = [inContentFilterArray objectEnumerator];
	id<AIDelayedContentFilter>	filter;
	BOOL						beganDelayedFiltering = NO;
	
	//Break as soon as we begin delayed filtering; we'll be back through here when that filtering is done
	while ((filter = [enumerator nextObject]) && !beganDelayedFiltering) {
		beganDelayedFiltering = [filter delayedFilterAttributedString:attributedString 
															  context:filterContext
															 uniqueID:uniqueID];
	}
	
	return beganDelayedFiltering;	
}

/*
 * @brief Filter an attributed string, notifying a target when complete
 *
 * This performs delayed filters, which means there may be a non-blocking delay before the filtered attributed string
 * is returned.
 *
 * @param attributedString NSAttributedString to filter
 * @param type Type of the filter
 * @param direction Direction of the filter
 * @param filterContext A object, such as an AIListContact or an AIAccount, used as context by filters
 * @param target Target to notify when filtering is complete
 * @param selector Selector to call on target.  It should take 2 arguments; the first will be the filtered attributedString; the second is the passed context.
 * @param context Context passed back to target via selector when filtering is complete
 * @result The filtered attributed string, which may be the same as attributedString
 */
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

	BOOL				shouldDelay = NO;
	NSInvocation		*invocation;
	
	//Set up the invocation
	invocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[invocation setSelector:selector];
	[invocation setTarget:target];
	[invocation setArgument:&context atIndex:3]; //context, the second argument after the two hidden arguments of every NSInvocation

	if (attributedString) {
		static unsigned long long	uniqueDelayedFilterID = 0;
		
		//Perform the main filters
		attributedString = [self _filterAttributedString:attributedString
										   contentFilter:contentFilter[type][direction]
										   filterContext:filterContext];

		//Now perform the delayed filters
		shouldDelay = [self _delayedFilterAttributedString:attributedString
											 contentFilter:delayedContentFilter[type][direction]
											 filterContext:filterContext
									 uniqueDelayedFilterID:uniqueDelayedFilterID];

		//If we should delay (a delayed filter is doing its thing), store what we need to finish later
		if (shouldDelay) {
			//NSInvocation does not retain its arguments by default; if we're caching the invocation, we must tell it to.
			[invocation retainArguments];

			//Track this so we can invoke with the filtered product later
			[delayedFilteringDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
				invocation, @"Invocation",
				delayedContentFilter[type][direction], @"Delayed Content Filter",
				filterContext, @"Filter Context", nil]
									 forKey:[NSNumber numberWithUnsignedLongLong:uniqueDelayedFilterID]];
		}

		//Increment our delayed filter ID
		uniqueDelayedFilterID++;
	}
	
	//If we didn't delay, invoke immediately
	if (!shouldDelay) {
		//Put that attributed string into the invocation as the first argument after the two hidden arguments of every NSInvocation
		[invocation setArgument:&attributedString atIndex:2];
		
		//Send the filtered attributedString back via the invocation
		[invocation invoke];
	}
}

/*
 * @brief A delayed filter finished filtering
 *
 * After this filter finishes, run it through the delayed filter system again
 * to hit the next delayed string, if necessary.
 *
 * If no more delayed filtering is needed, look up the invocation and pass the
 * now-finished string to the appropriate target.
 */
- (void)delayedFilterDidFinish:(NSAttributedString *)attributedString uniqueID:(unsigned long long)uniqueID
{
	NSNumber		*uniqueIDNumber;
	NSDictionary	*infoDict;
	BOOL			shouldDelay;

	uniqueIDNumber = [NSNumber numberWithUnsignedLongLong:uniqueID];
	infoDict = [delayedFilteringDict objectForKey:uniqueIDNumber];
	
	//Run through the delayed filters again, since a delayed filter would stop after the first hit
	shouldDelay = [self _delayedFilterAttributedString:attributedString
										 contentFilter:[infoDict objectForKey:@"Delayed Content Filter"]
										 filterContext:[infoDict objectForKey:@"Filter Context"]
								 uniqueDelayedFilterID:uniqueID];
	
	//If we no longer need to delay, set up the invocation and invoke it
	if (!shouldDelay) {
		NSInvocation	*invocation = [infoDict objectForKey:@"Invocation"];

		//Put that attributed string into the invocation as the first argument after the two hidden arguments of every NSInvocation
		[invocation setArgument:&attributedString atIndex:2];

		//Send the filtered attributedString back via the invocation
		[invocation invoke];

		//No further need for the infoDict from delayedFilteringDict
		[delayedFilteringDict removeObjectForKey:uniqueIDNumber];
	}
}

#pragma mark Filter priority sort
int filterSort(id<AIContentFilter> filterA, id<AIContentFilter> filterB, void *context)
{
	float filterPriorityA = [filterA filterPriority];
	float filterPriorityB = [filterB filterPriority];
	
	if (filterPriorityA < filterPriorityB)
		return NSOrderedAscending;
	else if (filterPriorityA > filterPriorityB)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

@end
