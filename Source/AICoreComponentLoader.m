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

 * Loads integrated plugins.  All integrated plugins require a _loadComponentClass statement below and their class name
 * in the @class list.  In situations where the load order of plugins is important, please make note.
 */

#import "AICoreComponentLoader.h"
#import <Adium/AIPlugin.h>

#define VERSION_KEY			@"Version"
#define COMPONENTS_KEY		@"Components"

#define COMPONENT_DISABLED	@"Disabled"
#define COMPONENT_CLASS		@"Class"
#define COMPONENT_HEADER	@"Header"
#define COMPONENT_LOCATION	@"Location"

@implementation AICoreComponentLoader

- (id)init
{
	if((self = [super init])){
		components = [[NSMutableArray alloc] init];
	}

	return self;
}

/*!
 * @brief Load integrated components
 */
- (void)initController
{
	NSString *propertyList = [[NSBundle mainBundle] pathForResource:@"CoreComponents" ofType:@"plist"];
	NSDictionary *componentDict = [NSDictionary dictionaryWithContentsOfFile:propertyList];
	NSArray *componentArray = [componentDict objectForKey:COMPONENTS_KEY];

	if(!componentArray){
		return;
	}

	NSEnumerator *compEnumerator = [componentArray objectEnumerator];
	NSDictionary *dict;

	while((dict = [compEnumerator nextObject])){
		if([[dict objectForKey:COMPONENT_DISABLED] boolValue]){
			continue;
		}

		NSString *className = [dict objectForKey:COMPONENT_CLASS];
		Class class;

		if(className && (class = NSClassFromString(className))){
			id object = [[class alloc] init];

			NSAssert1(object, @"Failed to load %@", className);

			[components addObject:object];
			[object release];
		}
	}
}

/*!
 * @brief Give all components a chance to close
 */
- (void)closeController
{
	NSEnumerator	*enumerator = [components objectEnumerator];
	AIPlugin		*plugin;

	while (plugin = [enumerator nextObject]) {
		[plugin uninstallPlugin];
	}
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[components release];
	components = nil;

	[super dealloc];
}

@end
