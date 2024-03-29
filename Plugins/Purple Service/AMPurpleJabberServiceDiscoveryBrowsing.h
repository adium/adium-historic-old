//
//  SmackXMPPServiceDiscoveryBrowsing.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-18.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <AdiumLibpurple/PurpleCommon.h>

@class AMPurpleJabberNode, AIAccount;

@interface AMPurpleJabberServiceDiscoveryBrowsing : AIObject {
    PurpleConnection *gc;
	AIAccount *account;
	
	NSMutableArray *browsers;
	AMPurpleJabberNode *rootnode;
}

- (id)initWithAccount:(AIAccount*)_account purpleConnection:(PurpleConnection*)_gc;
- (IBAction)browse:(id)sender;

@end
