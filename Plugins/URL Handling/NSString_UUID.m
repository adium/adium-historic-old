//
//  NSString_UUID.m
//  IMGamesPluginInstaller
//
//  Created by Sam McCandlish on 10/14/04.
//

#import "NSString_UUID.h"

@implementation NSString (UUID)

+ (NSString *)uuid
{
	CFUUIDRef	uuid;
	NSString	*uuidStr;
	
	uuid = CFUUIDCreate(NULL);
	uuidStr = (NSString *)CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);

	return([uuidStr autorelease]);
}

@end
