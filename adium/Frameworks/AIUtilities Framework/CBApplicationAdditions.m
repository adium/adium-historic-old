//
//  CBApplicationAdditions.m
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//

#import "CBApplicationAdditions.h"


@implementation NSApplication (CBApplicationAdditions)
- (BOOL)isOnPantherOrBetter
{
    return(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2);
}
- (BOOL)isOnJaguarOrBetter
{
    return(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_1);
}

- (BOOL)isWebKitAvailable
{
    static BOOL _webkitAvailable = NO;
    static BOOL _initialized = NO;
    NSBundle	*webKitBundle;
	
    if (_initialized)
        return _webkitAvailable;
	
/*
 webKitBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/WebKit.framework"];

    if (webKitBundle){		
        _webkitAvailable = [webKitBundle load];
    }
*/
	NSFileManager   *manager = [NSFileManager defaultManager];
	NSString		*fontPath = @"/System/Library/Frameworks/WebKit.framework";
	BOOL			isDir;
	
	if ([manager fileExistsAtPath:fontPath isDirectory:&isDir] && isDir){
		_webkitAvailable = YES;
	}
		
    _initialized = YES;

    return _webkitAvailable;	
}

- (BOOL)isURLLoadingAvailable
{
    return (NSFoundationVersionNumber >= 462.6);	
}

@end
