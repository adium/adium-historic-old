//
//  AIStatusIcons.h
//  Adium
//
//  Created by Adam Iser on 8/23/04.
//

#import <Cocoa/Cocoa.h>
#import "AIServiceIcons.h"

typedef enum {
	AIStatusIconTab = 0,		//Tabs
	AIStatusIconList			//Contact List
} AIStatusIconType;
#define NUMBER_OF_STATUS_ICON_TYPES 	2

@interface AIStatusIcons : NSObject {

}
+ (NSImage *)statusIconForListObject:(AIListObject *)object type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection;
+ (NSImage *)statusIconForChat:(AIChat *)chat type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection;
+ (NSImage *)statusIconForStatusID:(NSString *)statusID type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection;
+ (BOOL)setActiveStatusIconsFromPath:(NSString *)inPath;

@end