//
//  AIServiceIcons.h
//  Adium
//
//  Created by Adam Iser on 8/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	AIServiceIconSmall = 0,		//Interface large
	AIServiceIconLarge,			//Interface small
	AIServiceIconList			//Contact List
} AIServiceIconType;
#define NUMBER_OF_SERVICE_ICON_TYPES 	3

typedef enum {
	AIIconNormal = 0,
	AIIconFlipped
} AIIconDirection;
#define NUMBER_OF_ICON_DIRECTIONS		2


@interface AIServiceIcons : NSObject {

}

+ (NSImage *)serviceIconForObject:(AIListObject *)inObject type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection;
+ (NSImage *)serviceIconForService:(AIService *)service type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection;
+ (BOOL)setActiveServiceIconsFromPath:(NSString *)inPath;

@end
