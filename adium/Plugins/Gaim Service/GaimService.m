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

- (NSString *)gaimDescriptionSuffix
{
    return(@"");
}

- (AIAccountViewController *)accountView
{
	return([ESGaimAccountViewController accountView]);
}

- (DCJoinChatViewController *)joinChatView
{
	return nil;
}

@end
