//
//  ESNapsterService.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESNapsterService.h"
#import "ESGaimNapsterAccount.h"

@implementation ESNapsterService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Napster"
                                                      description:@"Napster c/o Libgaim"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@."]] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Napster-LIBGAIM");
}
- (NSString *)description
{
    return([NSString stringWithFormat:@"Napster %@",[self gaimDescriptionSuffix]]);
}

- (id)accountWithUID:(NSString *)inUID
{
    ESGaimNapsterAccount *anAccount = [[[ESGaimNapsterAccount alloc] initWithUID:inUID service:self] autorelease];
    
    [super addAccount:anAccount forGaimAccountPointer:nil];
    
    return anAccount;
}

@end
