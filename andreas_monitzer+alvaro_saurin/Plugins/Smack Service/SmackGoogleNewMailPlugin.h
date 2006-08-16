//
//  SmackGoogleNewMailPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIObject.h"

@class SmackXMPPAccount;

@interface SmackGoogleNewMailPlugin : AIObject {
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

@end
