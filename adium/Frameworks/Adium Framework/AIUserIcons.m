//
//  AIUserIcons.m
//  Adium
//
//  Created by Adam Iser on 8/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIUserIcons.h"
#import "AIListObject.h"

static NSMutableDictionary	*iconCache = nil;
static NSSize				iconCacheSize;

@implementation AIUserIcons

//Retrieve a user icon sized for the contact list
+ (NSImage *)listUserIconForContact:(AIListContact *)inContact
{
	NSImage *userIcon;
	
	//Retrieve the icon from our cache
	if(!iconCache) iconCache = [[NSMutableDictionary alloc] init];
	userIcon = [iconCache objectForKey:[inContact uniqueObjectID]];

	//Render the icon if it's not cached
	if(!userIcon){
		userIcon = [[inContact userIcon] imageByScalingToSize:iconCacheSize fraction:1.0 flipImage:YES];
		if(userIcon) [iconCache setObject:userIcon forKey:[inContact uniqueObjectID]];
	}
	
	return(userIcon);
}

//Set the current contact list user icon size
+ (void)setListUserIconSize:(NSSize)inSize
{
	if(!NSEqualSizes(inSize, iconCacheSize)){
		iconCacheSize = inSize;
		[self flushListUserIconCache];
	}	
}

//Flush all cached user icons
+ (void)flushListUserIconCache
{
	[iconCache release];
	iconCache = nil;
}

@end
