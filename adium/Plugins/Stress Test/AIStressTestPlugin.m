///
//  AIStressTestPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//

#import "AIStressTestPlugin.h"
#import "AIStressTestAccount.h"

@implementation AIStressTestPlugin

- (void)installPlugin
{
#ifdef DEVELOPMENT_BUILD
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:[self identifier]
                                                      description:[self description]
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]
												ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
													allowedLength:20] retain];

    //Register this service
    [[adium accountController] registerService:self];
#endif
}

#ifdef DEVELOPMENT_BUILD

//Return a new account with the specified properties
- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{
    return([[[AIStressTestAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

// Return a view for the connection window
- (AIAccountViewController *)accountView{
    return(nil);
}

// Return a Plugin-specific ID and description
- (NSString *)identifier
{
    return(STRESS_TEST_SERVICE_IDENTIFIER);
}
- (NSString *)description
{
    return(@"Stress Test (Das ist verboten)");
}

// Return an ID, description, and image for handles owned by accounts of this type
- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

#endif

@end

