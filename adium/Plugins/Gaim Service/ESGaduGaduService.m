//
//  ESGaduGaduService.m
//  Adium
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
    
	NSImage *image = [NSImage imageNamed:@"gadu-gadu" forClass:[self class]];

    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Gadu-Gadu"
                                                      description:@"Gadu-Gadu"
                                                            image:image
														menuImage:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._ "]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
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
    return @"Gadu-Gadu";
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
