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
    
	NSImage *image = [NSImage imageNamed:@"meanwhile" forClass:[self class]];
		
    //Create our handle service type
	//A sametime UID may need to be in the form "uid=C'\awef@@+ +3 ou=fuEWJGhw67_ efWEf ..." I'm serious.
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Sametime"
                                                      description:@"Lotus Sametime"
                                                            image:image
                                                    caseSensitive:YES
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@.,_-()='/ "]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:1000] retain];
    
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
