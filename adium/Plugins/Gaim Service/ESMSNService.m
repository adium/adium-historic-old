//
//  ESMSNService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//
//#import "CBGaimServicePlugin.h"

#import "ESMSNService.h"
#import "ESGaimMSNAccount.h"
#import "ESGaimMSNAccountViewController.h"

@implementation ESMSNService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
	NSImage *image = [NSImage imageNamed:@"msn" forClass:[self class]];
	
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"MSN"
                                                      description:@"MSN"
                                                            image:image
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._-"]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:113] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"MSN-LIBGAIM");
}
- (NSString *)description
{
    return @"MSN";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimMSNAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimMSNAccountViewController accountView]);
}


@end
