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

#import "AIListObject.h"
#import "AIObject.h"
#import "AIService.h"
#import "AIServiceIcons.h"

static NSMutableDictionary	*serviceIcons[NUMBER_OF_SERVICE_ICON_TYPES][NUMBER_OF_ICON_DIRECTIONS];

static NSString				*serviceIconBasePath = nil;
static NSDictionary			*serviceIconNames[NUMBER_OF_SERVICE_ICON_TYPES];

@implementation AIServiceIcons

+ (void)initialize
{
	if (self == [AIServiceIcons class]) {
		int i, j;

		//Allocate our service icon cache
		for (i = 0; i < NUMBER_OF_SERVICE_ICON_TYPES; i++) {
			for (j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++) {
				serviceIcons[i][j] = [[NSMutableDictionary alloc] init];
			}
		}
	}
}

//Retrive the correct service icon for a contact
+ (NSImage *)serviceIconForObject:(AIListObject *)inObject type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [self serviceIconForService:[inObject service] type:iconType direction:iconDirection];
}

//Retrieve the correct service icon for a service
+ (NSImage *)serviceIconForService:(AIService *)service type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSImage	*serviceIcon = [self serviceIconForServiceID:[service serviceID] type:iconType direction:iconDirection];

	return serviceIcon ? serviceIcon : [service defaultServiceIcon];
}

//Retrieve the correct service icon for a service by ID
+ (NSImage *)serviceIconForServiceID:(NSString *)serviceID type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSImage				*serviceIcon;

	//Retrieve the service icon from our cache
	serviceIcon = [serviceIcons[iconType][iconDirection] objectForKey:serviceID];

	//Load the service icon if necessary
	if (!serviceIcon) {
		NSString	*path = [serviceIconBasePath stringByAppendingPathComponent:[serviceIconNames[iconType] objectForKey:serviceID]];

		if (path) {
			serviceIcon = [[NSImage alloc] initWithContentsOfFile:path];

			if (serviceIcon) {
				if (iconDirection == AIIconFlipped) [serviceIcon setFlipped:YES];
				[serviceIcons[iconType][iconDirection] setObject:serviceIcon forKey:serviceID];
			}

			[serviceIcon release];
		}
	}

	return serviceIcon;
}

//Set the active service icon pack
+ (BOOL)setActiveServiceIconsFromPath:(NSString *)inPath
{
	if (!serviceIconBasePath || ![serviceIconBasePath isEqualToString:inPath]) {
		NSDictionary	*serviceIconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];

		if (serviceIconDict && [[serviceIconDict objectForKey:@"AdiumSetVersion"] intValue] == 1) {
			[serviceIconBasePath release];
			serviceIconBasePath = [inPath retain];

			[serviceIconNames[AIServiceIconSmall] release];
			serviceIconNames[AIServiceIconSmall] = [[serviceIconDict objectForKey:@"Interface-Small"] retain];

			[serviceIconNames[AIServiceIconLarge] release];
			serviceIconNames[AIServiceIconLarge] = [[serviceIconDict objectForKey:@"Interface-Large"] retain];

			[serviceIconNames[AIServiceIconList] release];
			serviceIconNames[AIServiceIconList] = [[serviceIconDict objectForKey:@"List"] retain];

			//Clear out the service icon cache
			int i, j;

			for (i = 0; i < NUMBER_OF_SERVICE_ICON_TYPES; i++) {
				for (j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++) {
					[serviceIcons[i][j] removeAllObjects];
				}
			}

			[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:AIServiceIconSetDidChangeNotification
																			   object:nil];

			return YES;
		}
	}

	return NO;
}

#define	PREVIEW_MENU_IMAGE_SIZE		13
#define	PREVIEW_MENU_IMAGE_MARGIN	2

+ (NSImage *)previewMenuImageForIconPackAtPath:(NSString *)inPath
{
	NSImage			*image;
	NSDictionary	*iconDict;

	image = [[NSImage alloc] initWithSize:NSMakeSize((PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN) * 4,
													 PREVIEW_MENU_IMAGE_SIZE)];

	iconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];

	if (iconDict && [[iconDict objectForKey:@"AdiumSetVersion"] intValue] == 1) {
		NSDictionary	*previewIconNames = [iconDict objectForKey:@"List"];
		NSEnumerator	*enumerator = [[NSArray arrayWithObjects:@"AIM",@"Jabber",@"MSN",@"Yahoo!",nil] objectEnumerator];
		NSString		*iconID;
		int				xOrigin = 0;

		[image lockFocus];
		while ((iconID = [enumerator nextObject])) {
			NSString	*anIconPath = [inPath stringByAppendingPathComponent:[previewIconNames objectForKey:iconID]];
			NSImage		*anIcon;

			if ((anIcon = [[[NSImage alloc] initWithContentsOfFile:anIconPath] autorelease])) {
				NSSize	anIconSize = [anIcon size];
				NSRect	targetRect = NSMakeRect(xOrigin, 0, PREVIEW_MENU_IMAGE_SIZE, PREVIEW_MENU_IMAGE_SIZE);

				if (anIconSize.width < targetRect.size.width) {
					float difference = (targetRect.size.width - anIconSize.width)/2;

					targetRect.size.width -= difference;
					targetRect.origin.x += difference;
				}

				if (anIconSize.height < targetRect.size.height) {
					float difference = (targetRect.size.height - anIconSize.height)/2;

					targetRect.size.height -= difference;
					targetRect.origin.y += difference;
				}

				[anIcon drawInRect:targetRect
							fromRect:NSMakeRect(0,0,anIconSize.width,anIconSize.height)
						   operation:NSCompositeCopy
							fraction:1.0];

				//Shift right in preparation for next image
				xOrigin += PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN;
			}
		}
		[image unlockFocus];
	}

	return [image autorelease];
}

@end
