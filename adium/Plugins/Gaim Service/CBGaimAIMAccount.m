//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "CBGaimAIMAccount.h"
#import "aim.h"

#define SCREEN_NAME "tekjew"

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

- (NSString *)UIDAndServiceID{
    return [NSString stringWithFormat:@"%@.%@", [self serviceID], [self UID]]; 
}

// Return a readable description of this account's username
- (NSString *)accountDescription
{
    NSString	*description = [propertiesDict objectForKey:@"Handle"];
    
    return((description && [description length]) ? description : [self UIDAndServiceID]);
}

- (id <AIAccountViewController>)accountView
{
    //return accountView;
    return nil;
}

@end
