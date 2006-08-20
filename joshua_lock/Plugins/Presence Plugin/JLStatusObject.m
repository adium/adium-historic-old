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

#import "JLStatusObject.h"
#import "AIStatus.h"

@implementation JLStatusObject

- (id)init
{
	if ((self == [super init])) {
		title = nil;
		toolTip = nil;
		type = -1;
		//image = [[NSImage alloc] init];
		isActiveStatus = NO;
		hasSubmenu = NO;
	}
	return self;
}

- (id)initWithTitle:(NSString *)theTitle
{
	[self init];
	[self setTitle:theTitle];
	
	return self;
}

- (void)dealloc
{
	[title release];
	[toolTip release];
	//[image release];
	
	[super dealloc];
}

- (void)setTitle: (NSString *)theTitle 
{
	[title autorelease];
	title = [theTitle copy];
}

- (NSString *)title
{
	return title;
}

- (void)setIsActiveStatus: (BOOL)activeStatus
{
	isActiveStatus = activeStatus;
}

- (BOOL)isActiveStatus
{
	return isActiveStatus;
}

- (void)setToolTip: (NSString *)theTip 
{
	[toolTip autorelease];
	toolTip = [theTip copy];
}

- (NSString *)toolTip
{
	return toolTip;
}

- (void)setHasSubmenu: (BOOL)submenu 
{
	hasSubmenu = submenu;
}

- (BOOL)hasSubmenu
{
	return hasSubmenu;
}

- (void)setType:(int)aType
{
	type = aType;
}

- (int)type
{
	return type;
}

/*- (void)setImage: (NSImage *)newImage
{
	[newImage retain];
	[image release];
	image = newImage;
}

- (NSImage *)image
{
	return [[image copy] autorelease];
}*/

- (AIStatusItem *)objectToStatusItem
{
	AIStatusItem	*statusItem;
	statusItem = [[AIStatusItem alloc] init];
	[statusItem setTitle:title];
	[statusItem setStatusType:(AIStatusType)type];
	
	return statusItem;
}

@end
