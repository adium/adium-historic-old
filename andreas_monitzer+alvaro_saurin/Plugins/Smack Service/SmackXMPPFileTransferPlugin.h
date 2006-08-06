//
//  SmackXMPPFileTransferPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-21.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class SmackXMPPAccount, SmackXMPPFileTransferListener;

@interface SmackXMPPFileTransferPlugin : AIObject {
    SmackXMPPAccount *account;
    
    SmackXMPPFileTransferListener *listener;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

@end
