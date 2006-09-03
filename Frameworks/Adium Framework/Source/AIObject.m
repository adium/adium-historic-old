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

/*
 * @class AIObject
 * @brief Superclass for all objects within Adium
 *
 * Provides all Adium objects with an 'adium' instance variable through which they can access shared Adium
 * controllers. The class methods sharedAdiumInstance provides access for C functions and other class methods.
 */
@implementation AIObject

//define to @"All" for all AIObjects, or @"ClassName" for ClassName
//#define COUNT_AIOBJECT_INSTANCES @"All"
//
static AIAdium *_sharedAdium = nil;

#ifdef COUNT_AIOBJECT_INSTANCES
static NSMutableDictionary *instanceCountDict = nil;
#endif
/*
 * @brief Set the shared AIAdium instance
 *
 * Called once, after AIAdium loads
 */
+ (void)_setSharedAdiumInstance:(AIAdium *)shared
{
    NSParameterAssert(_sharedAdium == nil);
    _sharedAdium = [shared retain];
#ifdef COUNT_AIOBJECT_INSTANCES
	instanceCountDict = [[NSMutableDictionary alloc] init];
#endif
}

/*
 * @brief Return the shared AIAdium instance
 */
+ (AIAdium *)sharedAdiumInstance
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
		
#ifdef COUNT_AIOBJECT_INSTANCES
		NSString *className = NSStringFromClass([self class]);
		if( [@"All" isEqualToString:COUNT_AIOBJECT_INSTANCES] || [className isEqualToString:COUNT_AIOBJECT_INSTANCES]) {
			@synchronized(instanceCountDict) {
				NSNumber *instanceCount = [instanceCountDict objectForKey:className];
				if(!instanceCount) instanceCount = [NSNumber numberWithInt:0];
				instanceCount = [NSNumber numberWithInt:[instanceCount intValue] + 1];
				[instanceCountDict setObject:instanceCount forKey:className];
				NSLog(@"Instance Counter: Initializing object of class %@, there are now %@ of them", className, [instanceCount stringValue]);
			}
		}
#endif
	}

    return self;
}

#ifdef COUNT_AIOBJECT_INSTANCES
- (void) dealloc
{
	@synchronized(instanceCountDict) {
		NSString *className = NSStringFromClass([self class]);
		if([@"All" isEqualToString:COUNT_AIOBJECT_INSTANCES] || [className isEqualToString:COUNT_AIOBJECT_INSTANCES]) {
			NSNumber *count = [instanceCountDict objectForKey:className];
			[instanceCountDict setObject:[NSNumber numberWithInt:[count intValue] - 1] forKey:className];
			NSLog(@"Instance Counter: Deallocating object of class %@, there are now %d of them", className, [count intValue] - 1);
		}

	}
		[super dealloc];
}
#endif

@end
