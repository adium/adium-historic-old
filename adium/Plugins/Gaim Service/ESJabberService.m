//
//  ESJabberService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESJabberService.h"
#import "ESGaimJabberAccount.h"
#import "ESGaimJabberAccountViewController.h"
#import "DCGaimJabberJoinChatViewController.h"

@implementation ESJabberService

- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
	NSImage *image = [NSImage imageNamed:@"jabber" forClass:[self class]];
	
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Jabber"
                                                      description:@"Jabber"
                                                            image:image
														menuImage:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-()"]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:129] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Jabber-LIBGAIM");
}
- (NSString *)description
{
    return @"Jabber";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimJabberAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimJabberAccountViewController accountView]);
}

- (DCJoinChatViewController *)joinChatView
{
	return([DCGaimJabberJoinChatViewController joinChatView]);
}

@end
