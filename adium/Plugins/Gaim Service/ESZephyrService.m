//
//  ESZephyrService.m
//  Adium
//
//  Created by Evan Schoenberg on 8/12/04.
//

#import "ESZephyrService.h"
#import "ESGaimZephyrAccount.h"
#import "ESGaimZephyrAccountViewController.h"
#import "DCGaimZephyrJoinChatViewController.h"


@implementation ESZephyrService
- (id)initWithService:(id)inService
{
    [super initWithService:inService];
    
	NSImage *image = [NSImage imageNamed:@"zephyr" forClass:[self class]];
	
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Zephyr"
                                                      description:@"Zephyr"
                                                            image:image
														menuImage:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-"]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:255] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
    
    return self;
}

- (NSString *)identifier
{
    return(@"Zephyr-LIBGAIM");
}
- (NSString *)description
{
    return @"Zephyr";
}

- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{    
    return([[[ESGaimZephyrAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

- (AIAccountViewController *)accountView
{
    return([ESGaimZephyrAccountViewController accountView]);
}

- (DCJoinChatViewController *)joinChatView
{
	return([DCGaimZephyrJoinChatViewController joinChatView]);
}

@end
