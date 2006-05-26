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

#import "AIObject.h"

/*
 * @class AIObject
 * @brief Superclass for all objects within Adium
 *
 * Provides all Adium objects with an 'adium' instance variable through which they can access shared Adium
 * controllers. The class methods sharedAdiumInstance provides access for C functions and other class methods.
 */
@implementation AIObject

//
static AIAdium *_sharedAdium = nil;

/*
 * @brief Set the shared AIAdium instance
 *
 * Called once, after AIAdium loads
 */
+ (void)_setSharedAdiumInstance:(AIAdium *)shared
{
    NSParameterAssert(_sharedAdium == nil);
    _sharedAdium = [shared retain];
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
	}

    return self;
}

@end
