//
//  MSNAccountViewController.h
//  Adium
//
//  Created by Colin Barrett on Thu Jul 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@class MSNAccount;

@interface MSNAccountViewController : AIObject <AIAccountViewController>
{
    MSNAccount	*account;
    
    IBOutlet	NSView		*view_accountView;
    IBOutlet	NSTextField	*textField_email;
    IBOutlet	NSTextField	*textField_friendlyName;
}
+ (id)accountViewForAccount:(id)inAccount;
- (NSView *)view;
- (void)configureViewAfterLoad;
- (IBAction)saveChanges:(id)sender;

@end
