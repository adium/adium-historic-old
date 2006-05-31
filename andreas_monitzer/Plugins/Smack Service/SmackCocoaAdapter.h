//
//  SmackCocoaAdapter.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AIObject.h"

@protocol AdiumSmackBridgeDelegate;
@class SmackXMPPConnection, SmackXMPPAccount;

@interface SmackCocoaAdapter : AIObject <AdiumSmackBridgeDelegate> {
    SmackXMPPConnection *connection;
    SmackXMPPAccount *account;
}

+ (void)initializeJavaVM;
- (id)initForAccount:(SmackXMPPAccount *)inAccount;

- (SmackXMPPConnection*)connection;

@end
