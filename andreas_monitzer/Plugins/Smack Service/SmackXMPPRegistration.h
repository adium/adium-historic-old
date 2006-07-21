//
//  SmackXMPPRegistration.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-21.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

// This class implements JEP-77

@class SmackXMPPAccount, SmackXMPPFormController;

@interface SmackXMPPRegistration : AIObject {
    SmackXMPPAccount *account;
    NSString *otherJID;
    NSString *packetID;
    
    BOOL wasForm;
    BOOL receivedInitialForm;
}

- (id)initWithAccount:(SmackXMPPAccount*)a registerWith:(NSString*)jid;

@end
