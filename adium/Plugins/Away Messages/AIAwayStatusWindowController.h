//
//  AIAwayStatusWindowController.h
//  Adium
//
//  Created by David Clark on Sat May 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class	AIAdium, AISendingTextView;

@interface AIAwayStatusWindowController : NSWindowController {
    AIAdium *owner;
    
    IBOutlet NSButton *button_comeBack;
    IBOutlet NSTextView *textView_awayMessage;
    IBOutlet NSTextField *textField_awayTime;
}

+ (AIAwayStatusWindowController *)awayStatusWindowControllerForOwner:(id)inOwner;
+ (void)updateAwayStatusWindow;
- (IBAction)comeBack:(id)sender;
- (void)updateWindow;
@end
