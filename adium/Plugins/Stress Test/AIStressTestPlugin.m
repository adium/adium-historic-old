//
//  AIStressTestPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIStressTestPlugin.h"
#import "AIStressTestAccount.h"


@implementation AIStressTestPlugin

- (void)installPlugin
{
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"TEST"
                                                      description:@"Stress Test (Do not use)"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]] retain];

    //Register this service
#warning [[adium accountController] registerService:self];
}

//Return a new account with the specified properties
- (id)accountWithProperties:(NSDictionary *)inProperties
{
    return([[[AIStressTestAccount alloc] initWithProperties:inProperties service:self] autorelease]);
}

// Return a Plugin-specific ID and description
- (NSString *)identifier
{
    return(@"Stress Test");
}
- (NSString *)description
{
    return(@"Stress Test (Do not use)");
}

// Return an ID, description, and image for handles owned by accounts of this type
- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

@end
