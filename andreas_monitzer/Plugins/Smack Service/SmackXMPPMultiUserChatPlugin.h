//
//  SmackXMPPMultiUserChatPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-03.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class SmackXMPPAccount, SmackXMPPMultiUserChatPluginListener, DCJoinChatViewController;

@protocol SmackXMPPMultiUserChatPluginListenerDelegate <NSObject>

- (void)setMUCInvitation:(NSDictionary*)info;

@end

@interface SmackXMPPMultiUserChatPlugin : AIObject<SmackXMPPMultiUserChatPluginListenerDelegate> {
    NSMutableDictionary *mucs;
    SmackXMPPMultiUserChatPluginListener *listener;
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;
- (void)setMUCInvitation:(NSDictionary*)info;

@end
