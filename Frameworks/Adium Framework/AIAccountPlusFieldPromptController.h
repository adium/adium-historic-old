//
//  AIAccountPlusFieldPromptController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/5/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AIAccountPlusFieldPromptController : AIWindowController {
    IBOutlet	AICompletingTextField	*textField_handle;
    IBOutlet	NSPopUpButton			*popUp_service;
}

+ (void)showPrompt;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (IBAction)okay:(id)sender;
- (AIListContact *)contactFromTextField;

@end
