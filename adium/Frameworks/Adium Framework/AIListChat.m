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

- (NSString *)formattedDisplayName
{

    AIMutableOwnerArray * formattedNameArray;
    NSString *outName;

    formattedNameArray = [self displayArrayForKey:@"Formatted Display Name"];
    if (formattedNameArray && [formattedNameArray count])
    {
        outName = [formattedNameArray objectAtIndex:0];
    }
    else
    {
        outName = UID;
    }

    return (outName);
}
@end
