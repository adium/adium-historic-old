//
//  AIServiceIcons.m
//  Adium
//
//  Created by Adam Iser on 8/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIServiceIcons.h"

static NSMutableDictionary	*serviceIcons[NUMBER_OF_SERVICE_ICON_TYPES][NUMBER_OF_ICON_DIRECTIONS];

static NSString				*serviceIconBasePath = nil;
static NSDictionary			*serviceIconNames[NUMBER_OF_SERVICE_ICON_TYPES];

@implementation AIServiceIcons

+ (void)initialize
{
	int i, j;

	[super initialize];
	
	//Allocate our service icon cache
	for(i = 0; i < NUMBER_OF_SERVICE_ICON_TYPES; i++){
		for(j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++){
			serviceIcons[i][j] = [[NSMutableDictionary alloc] init];
		}
	}

	//Hard coded icon pack for now
	NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Service Icons"] stringByExpandingTildeInPath];
	[self setActiveServiceIconsFromPath:[path stringByAppendingPathComponent:@"Gaim.AdiumServiceIcons"]];
}

//Retrive the correct service icon for a contact
+ (NSImage *)serviceIconForObject:(AIListObject *)inObject type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	return([self serviceIconForService:[inObject service] type:iconType direction:iconDirection]);
}

//Retrieve the correct service icon for a service
+ (NSImage *)serviceIconForService:(AIService *)service type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSString			*serviceID = [service serviceID];
	NSImage				*serviceIcon;
	
	//Retrieve the service icon from our cache
	serviceIcon = [serviceIcons[iconType][iconDirection] objectForKey:serviceID];
	
	//Load the service icon if necessary
	if(!serviceIcon){
		NSString	*path = [serviceIconBasePath stringByAppendingPathComponent:[serviceIconNames[iconType] objectForKey:serviceID]];

		if(path){
			serviceIcon = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];

			if(serviceIcon){
				if(iconDirection == AIIconFlipped) [serviceIcon setFlipped:YES];
				[serviceIcons[iconType][iconDirection] setObject:serviceIcon forKey:serviceID];
			}
		}
	}
	
	return(serviceIcon);
}

//Set the active service icon pack
+ (BOOL)setActiveServiceIconsFromPath:(NSString *)inPath
{
	if(!serviceIconBasePath || ![serviceIconBasePath isEqualToString:inPath]){
		NSDictionary	*serviceIconPack = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];
		NSLog(@"setActiveServiceIconsFromPath:%@",inPath);
		
		if(serviceIconPack && [[serviceIconPack objectForKey:@"AdiumSetVersion"] intValue] == 1){
			serviceIconBasePath = [inPath retain];
			
			serviceIconNames[AIServiceIconSmall] = [[serviceIconPack objectForKey:@"Interface-Small"] retain];
			serviceIconNames[AIServiceIconLarge] = [[serviceIconPack objectForKey:@"Interface-Large"] retain];
			serviceIconNames[AIServiceIconList] = [[serviceIconPack objectForKey:@"List"] retain];

			return(YES);
		}else{
			return(NO);
		}
	}
}

//resourcePathsForName

@end
