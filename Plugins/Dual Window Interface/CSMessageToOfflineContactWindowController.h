//
//  CSMessageToOfflineContactWindowController.h
//  Adium
//
//  Created by Chris Serino on Sat Apr 24 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@class AIMessageViewController;

@interface CSMessageToOfflineContactWindowController : AIWindowController {
	AIMessageViewController *messageViewController;
}

+ (void)showSheetInWindow:(NSWindow *)inWindow forMessageViewController:(AIMessageViewController *) inMessageViewController;

- (IBAction)closeWindow:(id)sender;

// Actions
- (IBAction)sendLater:(id)sender;
- (IBAction)dontSend:(id)sender;
- (IBAction)sendNow:(id)sender;

@end
