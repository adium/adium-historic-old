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

- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID temporary:(BOOL)inTemporary
{
    [super initWithUID:inUID temporary:inTemporary];

    serviceID = [inServiceID retain];
    
    return(self);
}

- (NSString *)serviceID
{
    return(serviceID);
}


@end
