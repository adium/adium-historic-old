//
//  ESTrepiaService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Feb 22 2004.
//

#import "ESTrepiaService.h"
#import "ESGaimTrepiaAccount.h"
#import "ESGaimTrepiaAccountViewController.h"

@implementation ESTrepiaService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Trepia"
                                                      description:@"Trepia"
                                                            image:nil
														menuImage:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._"]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
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
    return @"Trepia";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimTrepiaAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimTrepiaAccountViewController accountView]);
}

@end