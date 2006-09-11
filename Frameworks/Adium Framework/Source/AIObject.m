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

#import <Adium/AIObject.h>
#import <Adium/AIAdiumProtocol.h>

/*
 * @class AIObject
 * @brief Superclass for all objects within Adium
 *
 * Provides all Adium objects with an 'adium' instance variable through which they can access shared Adium
 * controllers. The class methods sharedAdiumInstance provides access for C functions and other class methods.
 */
@implementation AIObject

#define COUNT_NONE 0 //Don't compile instance counting code
#define COUNT_INCLUDE 1 //Only count instances for subclasses of AIObject in CLASS_LIST
#define COUNT_EXCLUDE 2 //Count instances for subclasses of AIObject *not* in CLASS_LIST
#define COUNT_ALL 3 //Count instance for all subclasses of AIObject

#define CLASS_LIST [[NSArray alloc] initWithObjects:@"AIContentMessage", @"AIContentTyping", @"AIContentContext", @"AIIconState", nil]

//set to one of the constants above to change instance counting behavior
#define INSTANCE_COUNT_STYLE COUNT_NONE

#if INSTANCE_COUNT_STYLE != COUNT_NONE
static NSMutableDictionary *instanceCountDict = nil;
static NSArray *classList = nil;

BOOL loggableClass(NSString *className)
{
	switch(INSTANCE_COUNT_STYLE)
	{
		case COUNT_INCLUDE:
			return [classList containsObject:className];
		case COUNT_EXCLUDE:
			return ![classList containsObject:className];
		default:
			return YES;
	}
}

void modifyInstanceCount(int delta, NSString *className)
{
	@synchronized(instanceCountDict) {
		NSNumber *count = [instanceCountDict objectForKey:className];
		if(!count) count = [NSNumber numberWithInt:0];
		count = [NSNumber numberWithInt:[count intValue] + delta];
		[instanceCountDict setObject:count forKey:className];
		NSLog(@"Instance Counter: %@ a(n) %@, there are now %@ of them", 
			  ((delta >= 0) ? @"Created" : @"Destroyed"), 
			  className, 
			  count);
	}
}
#endif

static NSObject<AIAdium> *_sharedAdium = nil;

/*
 * @brief Set the shared AIAdium instance
 *
 * Called once, after AIAdium loads
 */
+ (void)_setSharedAdiumInstance:(NSObject<AIAdium> *)shared
{
    NSParameterAssert(_sharedAdium == nil);
    _sharedAdium = [shared retain];
#if INSTANCE_COUNT_STYLE != COUNT_NONE
	instanceCountDict = [[NSMutableDictionary alloc] init];
	classList = CLASS_LIST;
#endif
}

/*
 * @brief Return the shared AIAdium instance
 */
+ (NSObject<AIAdium> *)sharedAdiumInstance
{
    NSParameterAssert(_sharedAdium != nil);
    return _sharedAdium;
}

/*
 * @brief Initialize
 */
- (id)init
{
    if ((self = [super init]))
	{
		NSParameterAssert(_sharedAdium != nil);
		adium = _sharedAdium;
		
#if INSTANCE_COUNT_STYLE != COUNT_NONE
		NSString *className = NSStringFromClass([self class]);
		if(loggableClass(className)) 
			modifyInstanceCount(1, className);
#endif
	}

    return self;
}

#if INSTANCE_COUNT_STYLE != COUNT_NONE
- (void) dealloc
{
	NSString *className = NSStringFromClass([self class]);
	if(loggableClass(className)) 
		modifyInstanceCount(-1, className);
	[super dealloc];
}
#endif

@end
