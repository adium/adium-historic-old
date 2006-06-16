//
//  SmackXMPPRosterPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SmackXMPPAccount;

@interface SmackXMPPRosterPlugin : NSObject {
}

- (id)initWithAccount:(SmackXMPPAccount*)account;

@end
