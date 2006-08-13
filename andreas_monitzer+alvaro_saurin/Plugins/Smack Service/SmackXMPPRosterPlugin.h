//
//  SmackXMPPRosterPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@protocol AIContactListTooltipEntry;
@class SmackXMPPAccount, SmackXMPPRosterPluginListener, SmackRoster;

@interface SmackXMPPRosterPlugin : AIObject <AIContactListTooltipEntry> {
    SmackXMPPAccount *account;
    SmackXMPPRosterPluginListener *listener;
    
    SmackRoster *roster;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

@end
