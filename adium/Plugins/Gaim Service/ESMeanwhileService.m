//
//  ESMeanwhileService.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.

#import "ESMeanwhileService.h"
#import "ESGaimMeanwhileAccount.h"
#import "ESGaimMeanwhileAccountViewController.h"

@implementation ESMeanwhileService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
	//A sametime UID may need to be in the form "uid=aforbes ou=employee ..."
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Sametime"
                                                      description:@"Lotus Sametime"
                                                            image:nil
                                                    caseSensitive:YES
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@.,_-()= "]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:255] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Sametime-LIBGAIM");
}
- (NSString *)description
{
    return @"Sametime";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimMeanwhileAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimMeanwhileAccountViewController accountView]);
}

@end
