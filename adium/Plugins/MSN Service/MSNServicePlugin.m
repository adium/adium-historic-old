//
//  AIMSNServicePlugin.m
//  Adium
//
//  Created by Colin Barrett on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MSNServicePlugin.h"
#import "MSNAccount.h"

@implementation MSNServicePlugin

- (void)installPlugin
{
        handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"MSN"
                          description:@"MSN Messenger Service"
                          image:[AIImageUtilities imageNamed:@"LilYellowDuck" forClass:[self class]]
                          caseSensitive:NO
                          allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]] retain];
                          
        [[owner accountController] registerService:self];
}

- (void)uninstallPlugin
{
    //pass
}

- (NSString *)identifier
{
    return(@"MSN");
}
- (NSString *)description
{
    return(@"MSN Messenger");
}

- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner
{
    return([[[MSNAccount alloc] initWithProperties:inProperties service:self owner:inOwner] autorelease]);
}

@end