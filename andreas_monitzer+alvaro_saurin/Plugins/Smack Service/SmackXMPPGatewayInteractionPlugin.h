//
//  SmackXMPPGatewayInteractionPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-18.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class SmackXMPPAccount;

@interface SmackXMPPGatewayInteractionPlugin : AIObject {
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

@end
