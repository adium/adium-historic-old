//
//  AIEnterAwayWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class	AIAdium, AISendingTextView;

@interface AIEnterAwayWindowController : NSWindowController {
    AIAdium	*owner;

    IBOutlet	AISendingTextView	*textView_awayMessage;
    IBOutlet	NSButton		*button_setAwayMessage;
    
}

+ (AIEnterAwayWindowController *)enterAwayWindowControllerForOwner:(id)inOwner;
- (IBAction)closeWindow:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)setAwayMessage:(id)sender;

@end
