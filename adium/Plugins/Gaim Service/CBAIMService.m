//
//  CBAIMService.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimAIMAccount.h"
#import "CBAIMService.h"

@implementation CBAIMService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];

    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"AIM"
                                                      description:@"AIM, AOL, and .Mac"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._ "]
													allowedLength:24] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"AIM-LIBGAIM");
}
- (NSString *)description
{
    return([NSString stringWithFormat:@"AIM %@",[self gaimDescriptionSuffix]]);
}

- (id)accountWithUID:(NSString *)inUID
{
    CBGaimAIMAccount *anAccount = [[[CBGaimAIMAccount alloc] initWithUID:inUID service:self] autorelease];
    
    return anAccount;
}



@end
