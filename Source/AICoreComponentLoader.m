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
#ifdef TRACK_COMPONENTS
			NSLog(@"%@: adding component: %@", [self class], object);
#endif

			NSAssert1(object, @"Failed to load %@", className);

			[components setObject:object forKey:className];
			[object release];
		}
	}
}

/*!
 * @brief Give all components a chance to close
 */
- (void)closeController
{
	NSArray			*keys = [components allKeys];
	NSEnumerator	*enumerator = [keys objectEnumerator];
	NSString		*className;

	while ((className = [enumerator nextObject])) {
		AIPlugin	*plugin = [components objectForKey:className];
#ifdef TRACK_COMPONENTS
		NSLog(@"%@: removing component: %@", [self class], plugin);
#endif
		[plugin uninstallPlugin];
	}
}

#pragma mark -

- (AIPlugin *)pluginWithClassName:(NSString *)className {
	return [components objectForKey:className];
}

@end
