//
//  CBApplicationAdditions.m
//  Adium XCode
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
    static BOOL _webkitAvailable=NO;
    static BOOL _initialized=NO;
    NSBundle	*webKitBundle;
	
    if (_initialized)
        return _webkitAvailable;
	
    webKitBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/WebKit.framework"];

    if (webKitBundle){		
        _webkitAvailable = [webKitBundle load];
    }
	
    _initialized=YES;

    return _webkitAvailable;	
}

@end
