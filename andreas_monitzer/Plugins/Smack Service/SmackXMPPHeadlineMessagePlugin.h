//
//  SmackXMPPHeadlineMessagePlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-23.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class SmackXMPPAccount;

@interface SmackXMPPHeadlineMessagePlugin : AIObject {
}

- (id)initWithAccount:(SmackXMPPAccount*)account;

@end
