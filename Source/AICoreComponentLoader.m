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

/*!
 * @class AICoreComponentLoader
 * @brief Core - Component Loader

 * Loads integrated plugins.  Component classes to load are determined by CoreComponents.plist
 */

#import "AICoreComponentLoader.h"
#import <Adium/AIObject.h>
#import <Adium/AIPlugin.h>

@implementation AICoreComponentLoader

/*!
 * @brief Init
 */
- (id)init
{
	if((self = [super init])){
		components = [[NSMutableDictionary alloc] init];
	}

	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[components release];
	[super dealloc];
}

#pragma mark -

/*!
 * @brief Load integrated components
 */
- (void)initController
{
	//Fetch the list of components to load
	NSString	*propertyList = [[NSBundle mainBundle] pathForResource:@"CoreComponents" ofType:@"plist"];
	NSArray 	*componentArray = [NSArray arrayWithContentsOfFile:propertyList];
	NSParameterAssert(componentArray != nil);

	//Load each component
	NSEnumerator *enumerator = [componentArray objectEnumerator];
	NSString	 *className;

	while((className = [enumerator nextObject])){
		Class class;

		if(className && (class = NSClassFromString(className))){
			id <AIPlugin>	object = [[class alloc] init];

			NSAssert1(object, @"Failed to load %@", className);

			[object installPlugin];

			[components setObject:object forKey:className];
			[object release];
		}
	}
}

- (void)finishIniting
{
}

- (void)beginClosing
{
}

/*!
 * @brief Close integreated components
 */
- (void)closeController
{
	NSEnumerator	*enumerator = [components objectEnumerator];
	id <AIPlugin>	plugin;

	while((plugin = [enumerator nextObject])) {
		[[[AIObject sharedAdiumInstance] notificationCenter] removeObserver:plugin];
		[[NSNotificationCenter defaultCenter] removeObserver:plugin];
		[plugin uninstallPlugin];
	}
}

#pragma mark -

/*!
 * @brief Retrieve a component plugin by its class name
 */
- (id <AIPlugin>)pluginWithClassName:(NSString *)className {
	return [components objectForKey:className];
}

@end
