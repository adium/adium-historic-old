//
//  GaimService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "GaimService.h"
#import "ESGaimAccountViewController.h"

@implementation GaimService

//Methods for subclasses to override
- (NSString *)identifier
{
    return nil;
}
- (NSString *)description
{
    return nil;
}
- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{
    return nil;
}

//GaimService methods
- (id)initWithService:(id)inService
{
    [super init];
    
    service = [inService retain];
    
    return self;
}

- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

//pass nil for gaimAcct to retrieve the GaimAccount* from anAccount
- (void)addAccount:(CBGaimAccount *)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct
{
    if (!gaimAcct)
        gaimAcct = [anAccount gaimAccount];
    
    [service addAccount:anAccount forGaimAccountPointer:gaimAcct];   
}

- (void)removeAccount:(GaimAccount *)gaimAcct
{
    [service removeAccount:gaimAcct];
}

- (BOOL)configureGaimProxySettings
{
    return [service configureGaimProxySettings];
}

- (NSString *)gaimDescriptionSuffix
{
    return(@" (LibGaim)");
}

- (AIAccountViewController *)accountView
{
	return([ESGaimAccountViewController accountView]);
}

@end
