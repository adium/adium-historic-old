//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "CBGaimAIMAccount.h"
#import "aim.h"

#define SCREEN_NAME "otsku"

@implementation CBGaimAIMAccount

- (void)initAccount
{
    NSLog(@"CBGaimAIMAccount initAccount");
    screenName = [NSString stringWithUTF8String:SCREEN_NAME];
    [super initAccount];
}

- (NSString *)UID{
    return([NSString stringWithUTF8String:SCREEN_NAME]);
}
    
- (NSString *)serviceID{
    return @"AIM";
}

- (NSString *)accountDescription
{
    return @"AIM/OSCAR";
}

- (id <AIAccountViewController>)accountView
{
    //return accountView;
    return nil;
}

@end
