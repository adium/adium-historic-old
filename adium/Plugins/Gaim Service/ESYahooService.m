//
//  ESYahooService.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESYahooService.h"
#import "ESGaimYahooAccount.h"

@implementation ESYahooService

- (id)initWithService:(id)inService
{
/*    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Yahoo!"
                                                      description:@"Yahoo!"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@"]
													allowedLength:24] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
*/    
    return nil;
}

- (NSString *)identifier
{
    return(@"Yahoo-LIBGAIM");
}
- (NSString *)description
{
    return([NSString stringWithFormat:@"Yahoo! %@",[self gaimDescriptionSuffix]]);
}

- (id)accountWithUID:(NSString *)inUID
{
    ESGaimYahooAccount *anAccount = [[[ESGaimYahooAccount alloc] initWithUID:inUID service:self] autorelease];
    
    return anAccount;
}

@end
