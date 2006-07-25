//
//  SmackXMPPVCardPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-25.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIObject.h"

@class SmackXMPPAccount;

@interface SmackXMPPVCardPlugin : AIObject {
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

@end
