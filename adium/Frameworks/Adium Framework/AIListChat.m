//
//  AIListChat.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIListChat.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIListChat

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
    [super initWithUID:inUID serviceID:inServiceID];
    
    return(self);    
}

- (NSString *)displayName
{
    NSString	*displayName;

    displayName = [[self statusArrayForKey:@"Display Name"] objectWithOwner:self];
    if(displayName != nil && [displayName length] != 0){
        return(displayName);
    }else{
        return(UID);
    }
}

- (NSString *)longDisplayName
{
    AIMutableOwnerArray * longNameArray;
    NSString *outName;

    longNameArray = [self displayArrayForKey:@"Long Display Name"];
    if (longNameArray && [longNameArray count]){
        outName = [longNameArray objectAtIndex:0];
    } else{
        outName = [self displayName];
    }
    return (outName);
}
@end
