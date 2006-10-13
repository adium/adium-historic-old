//
//  SmackXMPPErrorMessagePlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-23.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class SmackXMPPAccount,SmackPacket;

@interface SmackXMPPErrorMessagePlugin : AIObject {
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

+ (void)handleXMPPErrorPacket:(SmackPacket*)packet service:(NSString *)service;
+ (NSString *)errorMessageForCode:(int)code;

@end
