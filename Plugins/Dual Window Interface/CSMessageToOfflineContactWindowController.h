//
//  CSMessageToOfflineContactWindowController.h
//  Adium
//
//  Created by Chris Serino on Sat Apr 24 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@class AIMessageViewController;

@interface CSMessageToOfflineContactWindowController : AIWindowController {
	AIMessageViewController *messageViewController;
}

+ (void)showSheetInWindow:(NSWindow *)inWindow forMessageViewController:(AIMessageViewController *) inMessageViewController;

// Actions
- (IBAction)sendLater:(id)sender;
- (IBAction)dontSend:(id)sender;
- (IBAction)sendNow:(id)sender;

@end
