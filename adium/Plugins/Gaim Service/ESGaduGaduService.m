//
//  ESGaduGaduService.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaduGaduService.h"
#import "ESGaimGaduGaduAccount.h"
#import "ESGaimGaduGaduAccountViewController.h"

@implementation ESGaduGaduService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Gadu-Gadu"
                                                      description:@"Gadu-Gadu"
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
    return(@"GaduGadu-LIBGAIM");
}
- (NSString *)description
{
    return([NSString stringWithFormat:@"Gadu-Gadu %@",[self gaimDescriptionSuffix]]);
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimGaduGaduAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimGaduGaduAccountViewController accountView]);
}

@end
