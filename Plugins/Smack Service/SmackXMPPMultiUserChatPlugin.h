//
//  SmackXMPPMultiUserChatPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-03.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <Adium/DCJoinChatViewController.h>

@class SmackXMPPAccount, SmackXMPPMultiUserChatPluginListener;

@protocol SmackXMPPMultiUserChatPluginListenerDelegate <NSObject>

- (void)setMUCInvitation:(NSDictionary*)info;

@end

@interface SmackXMPPMultiUserChatPlugin : AIObject<SmackXMPPMultiUserChatPluginListenerDelegate> {
    SmackXMPPMultiUserChatPluginListener *listener;
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;
- (void)setMUCInvitation:(NSDictionary*)info;

@end

@interface SmackXMPPJoinChatViewController : DCJoinChatViewController {
    IBOutlet NSTextField *chatRoomNameField;
    IBOutlet NSTextField *serverField;
    IBOutlet NSTextField *nicknameField;
    IBOutlet NSTextField *passwordField;
}

- (void)setJID:(NSString *)jid; // chatroom@host/nick

@end
