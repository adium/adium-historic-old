//
//  CBGaimServicePlugin.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimServicePlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "CBGaimAccount.h"

@implementation CBGaimServicePlugin

- (void)installPlugin
{
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"GAIM"
                                                      description:@"LIBGAIM (Do not use)"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]] retain];

    //Register this service
    [[owner accountController] registerService:self];
}

- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner
{
    return([[[CBGaimAccount alloc] initWithProperties:inProperties service:self owner:inOwner] autorelease]);
}

- (NSString *)identifier
{
    return(@"LIBGAIM");
}
- (NSString *)description
{
    return(@"LIBGAIM (Do not use)");
}

- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}
@end
