//
//  ESYahooService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESYahooService.h"
#import "ESGaimYahooAccount.h"
#import "ESGaimYahooAccountViewController.h"
#import "DCGaimYahooJoinChatViewController.h"

@implementation ESYahooService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
	NSImage *image = [NSImage imageNamed:@"yahoo" forClass:[self class]];
	NSImage *menuImage = [NSImage imageNamed:@"yahoo-menu" forClass:[self class]];
	
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Yahoo!"
                                                      description:@"Yahoo!"
                                                            image:image
														menuImage:menuImage
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-"]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:30] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Yahoo-LIBGAIM");
}
- (NSString *)description
{
    return @"Yahoo!";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimYahooAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimYahooAccountViewController accountView]);
}


- (DCJoinChatViewController *)joinChatView
{
	return([DCGaimYahooJoinChatViewController joinChatView]);
}


@end
