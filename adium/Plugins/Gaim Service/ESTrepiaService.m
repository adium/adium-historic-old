//
//  ESTrepiaService.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Feb 22 2004.
//

#import "ESTrepiaService.h"
#import "ESGaimTrepiaAccount.h"

@implementation ESTrepiaService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Trepia"
                                                      description:@"Trepia"
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
    return(@"Trepia-LIBGAIM");
}
- (NSString *)description
{
    return([NSString stringWithFormat:@"Trepia %@",[self gaimDescriptionSuffix]]);
}

- (id)accountWithUID:(NSString *)inUID
{
    ESGaimTrepiaAccount *anAccount = [[[ESGaimTrepiaAccount alloc] initWithUID:inUID 
																	   service:self] autorelease];
    
    return anAccount;
}

@end