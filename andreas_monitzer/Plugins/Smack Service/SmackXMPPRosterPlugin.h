//
//  SmackXMPPRosterPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class SmackXMPPAccount;

@interface SmackXMPPRosterPlugin : AIObject {
}

- (id)initWithAccount:(SmackXMPPAccount*)account;

@end
