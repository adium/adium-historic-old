//
//  MSNAccountViewController.h
//  Adium
//
//  Created by Colin Barrett on Thu Jul 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

@class MSNAccount;

@interface MSNAccountViewController : NSObject <AIAccountViewController>
{
    AIAdium 	*owner;
    MSNAccount	*account;
    
    IBOutlet	NSView		*view_accountView;
    IBOutlet	NSTextField	*textField_email;
    IBOutlet	NSTextField	*textField_friendlyName;
}
+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount;
- (NSView *)view;
- (void)saveChanges;
- (void)configureViewAfterLoad;

@end
