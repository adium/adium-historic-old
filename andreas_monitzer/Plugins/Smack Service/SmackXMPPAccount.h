//
//  SmackXMPPAccount.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccount.h"

@class SmackCocoaAdapter, SmackConnectionConfiguration;

@interface SmackXMPPAccount : AIAccount {
    SmackCocoaAdapter *smackAdapter;
}

- (NSString*)hostName;
- (SmackConnectionConfiguration*)connectionConfiguration;

@end
