//
//  ESJabberService.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESJabberService.h"
#import "ESGaimJabberAccount.h"

@implementation ESJabberService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Jabber"
                                                      description:@"Jabber c/o Libgaim"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@ "]
													allowedLength:129] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Jabber-LIBGAIM");
}
- (NSString *)description
{
    return([NSString stringWithFormat:@"Jabber %@",[self gaimDescriptionSuffix]]);
}

- (id)accountWithUID:(NSString *)inUID
{
    ESGaimJabberAccount *anAccount = [[[ESGaimJabberAccount alloc] initWithUID:inUID service:self] autorelease];
    
    [super addAccount:anAccount forGaimAccountPointer:nil];
    
    return anAccount;
}

@end
