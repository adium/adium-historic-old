//
//  ESMSNService.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
//#import "CBGaimServicePlugin.h"

#import "ESMSNService.h"
#import "ESGaimMSNAccount.h"

@implementation ESMSNService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"MSN"
                                                      description:@"MSN"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._-"]
													allowedLength:50] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"MSN-LIBGAIM");
}
- (NSString *)description
{
    return([NSString stringWithFormat:@"MSN %@",[self gaimDescriptionSuffix]]);
}

- (id)accountWithUID:(NSString *)inUID
{
    ESGaimMSNAccount *anAccount = [[[ESGaimMSNAccount alloc] initWithUID:inUID service:self] autorelease];
    
    return anAccount;
}

@end
