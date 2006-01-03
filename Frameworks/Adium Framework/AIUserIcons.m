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

#import "AIListContact.h"
#import "AIListObject.h"
#import "AIUserIcons.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIServiceIcons.h>

static NSMutableDictionary	*iconCache = nil;
static NSMutableDictionary	*menuIconCache = nil;
static NSSize				iconCacheSize;
static NSSize				menuIconCacheSize;

@implementation AIUserIcons

+ (void)initialize
{
	if (self == [AIUserIcons class]) {
		iconCache = [[NSMutableDictionary alloc] init];
		menuIconCache = [[NSMutableDictionary alloc] init];
		menuIconCacheSize = NSMakeSize(16,16);		
	}
}

//Retrieve a user icon sized for the contact list
+ (NSImage *)listUserIconForContact:(AIListContact *)inContact size:(NSSize)size
{
	BOOL	cache = NSEqualSizes(iconCacheSize, size);
	NSImage *userIcon = nil;
	
	//Retrieve the icon from our cache
	if (cache) userIcon = [iconCache objectForKey:[inContact internalObjectID]];

	//Render the icon if it's not cached
	if (!userIcon) {
		userIcon = [[inContact userIcon] imageByScalingToSize:size 
													 fraction:1.0
													flipImage:YES
											   proportionally:YES];
		if (userIcon && cache) [iconCache setObject:userIcon forKey:[inContact internalObjectID]];
	}
	
	return userIcon;
}

//Retrieve a user icon sized for a menu, returning the appropriate service icon if no user icon is found
+ (NSImage *)menuUserIconForObject:(AIListObject *)inObject
{
	NSImage *userIcon;
	
	//Retrieve the icon from our cache
	userIcon = [menuIconCache objectForKey:[inObject internalObjectID]];
	
	//Render the icon if it's not cached
	if (!userIcon) {
		userIcon = [[inObject userIcon] imageByScalingToSize:menuIconCacheSize
													fraction:1.0
												   flipImage:NO
											  proportionally:YES];
		if (userIcon) [menuIconCache setObject:userIcon
									   forKey:[inObject internalObjectID]];
	}

	return (userIcon ?
		   	userIcon :
			[AIServiceIcons serviceIconForObject:inObject
										   type:AIServiceIconSmall
									  direction:AIIconNormal]);
}

//Set the current contact list user icon size
+ (void)setListUserIconSize:(NSSize)inSize
{
	if (!NSEqualSizes(inSize, iconCacheSize)) {
		iconCacheSize = inSize;
		[self flushListUserIconCache];
	}	
}

//Flush all cached user icons
+ (void)flushListUserIconCache
{
	[iconCache release]; iconCache = nil; 	
	iconCache = [[NSMutableDictionary alloc] init];
	
	[menuIconCache release]; menuIconCache = nil; 	
	menuIconCache = [[NSMutableDictionary alloc] init];
}

+ (void)flushCacheForContact:(AIListContact *)inContact
{
	[iconCache removeObjectForKey:[inContact internalObjectID]];
	[menuIconCache removeObjectForKey:[inContact internalObjectID]];
}

@end
