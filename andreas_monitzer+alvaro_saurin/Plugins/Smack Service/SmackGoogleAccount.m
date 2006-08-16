//
//  SmackGoogleAccount.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-15.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackGoogleAccount.h"

@class SmackGoogleNewMailPlugin;

@implementation SmackGoogleAccount

- (void)initAccount {
	[super initAccount];
    
    [self addPlugin:[SmackGoogleNewMailPlugin class]];
}

@end
