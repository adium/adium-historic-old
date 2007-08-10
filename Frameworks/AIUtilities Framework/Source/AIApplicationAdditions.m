//
//  AIApplicationAdditions.m
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//

#import "AIApplicationAdditions.h"

@implementation NSApplication (AIApplicationAdditions)

- (BOOL)isOnTigerOrBetter
{
	return [self checkSystemVersionWithMajor:10 andMinor:4 andPoint:0 orBetter:YES];
}

- (BOOL)isOnLeopardOrBetter
{
	return [self checkSystemVersionWithMajor:10 andMinor:5 andPoint:0 orBetter:YES];
}

-(BOOL)isTiger
{
	return [self checkSystemVersionWithMajor:10 andMinor:4 andPoint:0 orBetter:NO];
}

-(BOOL)isLeopard
{
	return [self checkSystemVersionWithMajor:10 andMinor:5 andPoint:0 orBetter:NO];
}

-(BOOL)checkSystemVersionWithMajor:(int)majorVersion andMinor:(int)minorVersion andPoint:(int)pointVersion orBetter:(BOOL)higher
{
	BOOL ret = NO;
	//Checks SystemVersion.plist for ProductVersion key.
	NSString *versionString = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];
	NSArray *array = [versionString componentsSeparatedByString:@"."];
	int count = [array count];
	int major = (count >= 1) ? [[array objectAtIndex:0] intValue] : 0;
	int minor = (count >= 2) ? [[array objectAtIndex:1] intValue] : 0;
	int point = (count >= 3) ? [[array objectAtIndex:2] intValue] : 0;
	
	if(higher) {
		if(major >= majorVersion && minor >= minorVersion && point >= pointVersion)
			ret = YES;
	}
	
	else {
		if(major == majorVersion && minor == minorVersion && point == pointVersion)
			ret = YES;
	}
			
	return ret;
}
	

- (BOOL)isWebKitAvailable
{
	static BOOL _initialized = NO;
	static BOOL _webkitAvailable = NO;

	if (_initialized == NO) {
		NSString		*webkitPath = @"/System/Library/Frameworks/WebKit.framework";
		BOOL			isDir;

		if ([[NSFileManager defaultManager] fileExistsAtPath:webkitPath isDirectory:&isDir] && isDir) {
			_webkitAvailable = YES;
		}

		_initialized = YES;
	}

	return _webkitAvailable;
}

- (NSString *)applicationVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

@end
