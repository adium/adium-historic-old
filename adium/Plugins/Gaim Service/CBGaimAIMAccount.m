//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimAIMAccount.h"

#warning change this to your SN to connect :-)
#define SCREEN_NAME "kro26"

@implementation CBGaimAIMAccount

- (void)initAccount
{
    NSLog(@"CBGaimAIMAccount initAccount");
    screenName = @"kro26";
    [super initAccount];
}

- (const char*)protocolPlugin
{
    return "prpl-oscar";
}

- (NSString *)UID{
    return([NSString stringWithUTF8String:SCREEN_NAME]);
}
    
- (NSString *)serviceID{
    return @"AIM";
}

@end
