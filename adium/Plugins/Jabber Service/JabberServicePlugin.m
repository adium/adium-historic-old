#import "JabberServicePlugin.h"
#import "JabberAccount.h"

@implementation JabberServicePlugin

- (void)installPlugin
{
        handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"Jabber"
                          description:@"Jabber Service"
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
    return(@"Jabber");
}
- (NSString *)description
{
    return(@"Jabber");
}

- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner
{
    return([[[JabberAccount alloc] initWithProperties:inProperties service:self owner:inOwner] autorelease]);
}

@end
