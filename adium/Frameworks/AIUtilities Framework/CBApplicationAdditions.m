//
//  CBApplicationAdditions.m
//  Adium XCode
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
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
@end
