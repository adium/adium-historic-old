//
//  AIUserIcons.m
//  Adium
//
//  Created by Adam Iser on 8/24/04.
//

#import "AIUserIcons.h"
#import "AIListObject.h"

static NSMutableDictionary	*iconCache = nil;
static NSMutableDictionary	*menuIconCache = nil;
static NSSize				iconCacheSize;
static NSSize				menuIconCacheSize;

@implementation AIUserIcons

+ (void)initialize
{
	iconCache = [[NSMutableDictionary alloc] init];
	menuIconCache = [[NSMutableDictionary alloc] init];
	menuIconCacheSize = NSMakeSize(16,16);

//	defaultUserIcon = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
}

//Retrieve a user icon sized for the contact list
+ (NSImage *)listUserIconForContact:(AIListContact *)inContact size:(NSSize)size
{
	BOOL	cache = NSEqualSizes(iconCacheSize, size);
	NSImage *userIcon = nil;
	
	//Retrieve the icon from our cache
	if(cache) userIcon = [iconCache objectForKey:[inContact internalObjectID]];

	//Render the icon if it's not cached
	if(!userIcon){
		userIcon = [[inContact userIcon] imageByScalingToSize:size 
													 fraction:1.0
													flipImage:YES
											   proportionally:YES];
		if(userIcon && cache) [iconCache setObject:userIcon forKey:[inContact internalObjectID]];
	}
	
	return(userIcon/* ? userIcon : defaultUserIcon*/);
}

//Retrieve a user icon sized for a menu, returning the appropriate service icon if no user icon is found
+ (NSImage *)menuUserIconForObject:(AIListObject *)inObject
{
	NSImage *userIcon = nil;
	
	if ([inObject isKindOfClass:[AIListContact class]]){
		//Retrieve the icon from our cache
		userIcon = [menuIconCache objectForKey:[(AIListContact *)inObject internalObjectID]];
		
		//Render the icon if it's not cached
		if(!userIcon){
			userIcon = [[(AIListContact *)inObject userIcon] imageByScalingToSize:menuIconCacheSize
																		 fraction:1.0
																		flipImage:NO
																   proportionally:YES];
			if(userIcon) [menuIconCache setObject:userIcon
										   forKey:[(AIListContact *)inObject internalObjectID]];
		}
	}
	
	return(userIcon ?
		   userIcon :
		   [AIServiceIcons serviceIconForObject:inObject
										   type:AIServiceIconSmall
									  direction:AIIconNormal]);
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
	
	[menuIconCache release]; menuIconCache = nil; 	
	menuIconCache = [[NSMutableDictionary alloc] init];
}

+ (void)flushCacheForContact:(AIListContact *)inContact
{
	[iconCache removeObjectForKey:[inContact internalObjectID]];
	[menuIconCache removeObjectForKey:[inContact internalObjectID]];
}

@end
