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

- (void)dealloc
{
    [serviceID release];
    
    [super dealloc];
}

- (NSString *)serviceID
{
    return(serviceID);
}

- (void)setServiceID:(NSString *)inServiceID
{
    [serviceID release];
    serviceID = [inServiceID retain];
}


@end
