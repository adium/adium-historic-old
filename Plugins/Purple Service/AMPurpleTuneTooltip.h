//
//  AMPurpleTuneTooltip.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-12.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIInterfaceControllerProtocol.h>

@class CBPurpleAccount;

@interface AMPurpleTuneTooltip : NSObject <AIContactListTooltipEntry> {
	CBPurpleAccount *account;
}

- (id)initWithAccount:(CBPurpleAccount*)_account;

@end
