//
//  ESAccountPasswordPromptController.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 23 2004.

#import "AIPasswordPromptController.h"

@interface ESAccountPasswordPromptController : AIPasswordPromptController {
	IBOutlet	NSTextField	*textField_account;
	IBOutlet	NSTextField *textField_service;
    AIAccount				*account;
}

+ (void)showPasswordPromptForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;

@end
