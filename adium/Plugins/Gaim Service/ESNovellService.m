//
//  ESNovellService.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//

#import "ESNovellService.h"
#import "ESGaimNovellAccount.h"
#import "ESGaimNovellAccountViewController.h"

@implementation ESNovellService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"GroupWise"
                                                      description:@"Novell GroupWise"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._ "]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:40] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Novell-LIBGAIM");
}
- (NSString *)description
{
    return @"Novell GroupWise";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimNovellAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimNovellAccountViewController accountView]);
}


@end
