//
//  AIUserIcons.m
//  Adium
//
//  Created by Adam Iser on 8/24/04.
//

#import "AIUserIcons.h"
#import "AIListObject.h"

static NSMutableDictionary	*iconCache = nil;
static NSSize				iconCacheSize;

@implementation AIUserIcons

+ (void)initialize
{
	iconCache = [[NSMutableDictionary alloc] init];
	
//	defaultUserIcon = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
}

//Retrieve a user icon sized for the contact list
+ (NSImage *)listUserIconForContact:(AIListContact *)inContact
{
	NSImage *userIcon;
	
	//Retrieve the icon from our cache
	userIcon = [iconCache objectForKey:[inContact internalObjectID]];

	//Render the icon if it's not cached
	if(!userIcon){
		userIcon = [[inContact userIcon] imageByScalingToSize:iconCacheSize fraction:1.0 flipImage:YES];
		if(userIcon) [iconCache setObject:userIcon forKey:[inContact internalObjectID]];
	}
	
	return(userIcon/* ? userIcon : defaultUserIcon*/);
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
	[iconCache release]; iconCache = nil; 	
	iconCache = [[NSMutableDictionary alloc] init];
}

+ (void)flushCacheForContact:(AIListContact *)inContact
{
	[iconCache removeObjectForKey:[inContact internalObjectID]];
}

@end
