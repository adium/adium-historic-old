//
//  AINewMessagePrompt.h
//  Adium
//
//  Created by Adam Iser on Sat Feb 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AICompletingTextField, AIAdium;

@interface AINewMessagePrompt : NSWindowController {
    AIAdium	*owner;
    
    IBOutlet	AICompletingTextField	*textField_handle;
    IBOutlet	NSPopUpButton		*popUp_service;
}

+ (void)newMessagePromptWithOwner:(id)inOwner;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (IBAction)newMessage:(id)sender;

@end
