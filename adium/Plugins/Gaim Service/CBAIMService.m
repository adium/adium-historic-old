//
//  CBAIMService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimAIMAccount.h"
#import "CBAIMService.h"
#import "AIGaimAIMAccountViewController.h"

@implementation CBAIMService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];

    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"AIM"
                                                      description:@"AIM, ICQ, and .Mac"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._ "]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@" "]
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
    return @"AIM, ICQ, and .Mac";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[CBGaimAIMAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([AIGaimAIMAccountViewController accountView]);
}


@end
