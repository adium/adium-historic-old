//
//  SmackJinglePlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-10.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "AIObject.h"

@class SmackJingleListener, SmackXMPPAccount;

@interface SmackJinglePlugin : AIObject {
    SmackJingleListener *listener;
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

@end
