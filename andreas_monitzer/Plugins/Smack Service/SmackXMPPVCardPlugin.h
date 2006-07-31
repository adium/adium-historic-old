//
//  SmackXMPPVCardPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-25.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIObject.h"

@class SmackXMPPAccount, SmackXVCard;

@interface SmackXMPPVCardPlugin : AIObject {
    SmackXMPPAccount *account;
    
    IBOutlet NSWindow *editorwindow;
    IBOutlet NSTextField *fullnameField;
    
    SmackXVCard *vCardPacket;
    NSMutableDictionary *ownvCard;
    
    NSString *avatarhash;
    BOOL avatarUpdateInProgress;
    
    NSMutableArray *resourcesBlockingAvatar;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

- (IBAction)reloadvCard:(id)sender;
- (IBAction)savevCard:(id)sender;

@end
