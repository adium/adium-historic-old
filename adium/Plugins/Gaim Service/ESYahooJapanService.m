//
//  ESYahooJapanService.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ESYahooJapanService.h"
#import "ESGaimYahooJapanAccount.h"
#import "ESGaimYahooAccountViewController.h"

@implementation ESYahooJapanService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Yahoo! Japan"
                                                      description:@"Yahoo! Japan"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@"]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:24] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Yahoo-Japan-LIBGAIM");
}
- (NSString *)description
{
    return @"Yahoo! Japan";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimYahooJapanAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimYahooAccountViewController accountView]);
}

@end
