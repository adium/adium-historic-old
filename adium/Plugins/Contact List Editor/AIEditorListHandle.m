//
//  AIEditorListHandle.m
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEditorListHandle.h"
#import <Adium/Adium.h>


@implementation AIEditorListHandle

/*- (id)initWithHandle:(AIHandle *)inHandle
{
    [super initWithUID:[inHandle UID]];

//    handle = [inHandle retain];
    serviceID = [[handle serviceID] retain];
    
    return(self);
}*/

- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID temporary:(BOOL)inTemporary
{
    [super initWithUID:inUID];

    serviceID = [inServiceID retain];
    temporary = inTemporary;
    
    return(self);
}

- (NSString *)serviceID
{
    return(serviceID);
}

//Temporary = not on the account's list.. for the editor's use only (when creating new)
- (BOOL)temporary
{
    return(temporary);
}

@end
