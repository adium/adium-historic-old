//
//  SmackXMPPPrivacyPlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-04.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIObject.h"
#import "AIAccount.h"

@class SmackXMPPAccount;

@interface SmackXMPPPrivacyPlugin : AIObject <AIAccount_Privacy> {
    SmackXMPPAccount *account;
    
    NSMutableDictionary *privacyLists;
    NSString *defaultListName;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

@end
