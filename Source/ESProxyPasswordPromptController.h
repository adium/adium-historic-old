//
//  ESProxyPasswordPromptController.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIPasswordPromptController.h"

@interface ESProxyPasswordPromptController : AIPasswordPromptController {
	IBOutlet	NSTextField	*textField_server;
	IBOutlet	NSTextField	*textField_userName;
	
    NSString	*server;
	NSString	*userName;
}

+ (void)showPasswordPromptForProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;

@end
