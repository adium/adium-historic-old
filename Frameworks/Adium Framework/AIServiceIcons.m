//
//  AIServiceIcons.m
//  Adium
//
//  Created by Adam Iser on 8/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIServiceIcons.h"

static NSMutableDictionary	*serviceIcons = nil;
static NSMutableDictionary	*serviceIconsFlipped = nil;

static NSString				*serviceIconBasePath = nil;
static NSDictionary			*serviceIconNames = nil;

@implementation AIServiceIcons

//Retrive the correct service icon for a contact
+ (NSImage *)serviceIconForContact:(AIListContact *)inContact flipped:(BOOL)isFlipped
{
#warning (Adam) [inContact serviceID] would be nice here, except that it returns vague values
	/*
	 serviceID is less of a service ID and more of a compatability ID type thing.  So it will be AIM for all contacts
	 on that 'service' and not give us the correct values of aim/icq/.mac ... :\
	 */
	
	NSString			*serviceID = [[[[inContact account] service] handleServiceType] identifier];
	NSMutableDictionary	*cacheDict;
	NSImage				*serviceIcon;
	
#warning xxx temp
	if(!serviceIconNames){
		NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Service Icons"] stringByExpandingTildeInPath];
		NSLog(@"%@",path);
		[self setActiveServiceIconsFromPath:[path stringByAppendingPathComponent:@"Gaim.AdiumServiceIcons"]];
	}
#warning xxx temp

	if(!serviceIcons) serviceIconsFlipped = [[NSMutableDictionary alloc] init];
	if(!serviceIconsFlipped) serviceIconsFlipped = [[NSMutableDictionary alloc] init];

	//Retrieve the service icon from our cache
	cacheDict = (isFlipped ? serviceIconsFlipped : serviceIcons);
	serviceIcon = [cacheDict objectForKey:serviceID];
	
	//Load the service icon if necessary
	if(!serviceIcon){
		NSString	*path = [serviceIconBasePath stringByAppendingPathComponent:[serviceIconNames objectForKey:serviceID]];
		NSLog(@"%@:%@",serviceID,path);

		if(path){
			serviceIcon = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			if(serviceIcon){
				if(isFlipped) [serviceIcon setFlipped:YES];
				[cacheDict setObject:serviceIcon forKey:serviceID];
			}
		}
	}
}

//Set the active service icon pack
+ (BOOL)setActiveServiceIconsFromPath:(NSString *)inPath
{
	if(!serviceIconBasePath || ![serviceIconBasePath isEqualToString:inPath]){
		NSDictionary	*serviceIconPack = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];
		NSLog(@"setActiveServiceIconsFromPath:%@",inPath);
		
		if(serviceIconPack && [[serviceIconPack objectForKey:@"AdiumSetVersion"] intValue] == 1){
			serviceIconBasePath = [inPath retain];
			serviceIconNames = [[serviceIconPack objectForKey:@"Icons"] retain];
			NSLog(@"%@",serviceIconNames);
			return(YES);
		}else{
			return(NO);
		}
	}
}

//resourcePathsForName

@end
