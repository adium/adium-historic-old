//
//  ESFileTransferRequestPromptController.h
//  Adium
//
//  Created by Evan Schoenberg on 1/3/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESFileTransfer;

@interface ESFileTransferRequestPromptController : AIWindowController {
	IBOutlet	NSTextView		*textView_requestTitle;
    IBOutlet	NSScrollView	*scrollView_requestTitle;
    
    IBOutlet	NSTextView		*textView_requestDetails;
    IBOutlet	NSScrollView	*scrollView_requestDetails;
	
	IBOutlet	NSImageView		*imageView_icon;
	IBOutlet	NSButton		*button_save;
	IBOutlet	NSButton		*button_saveAs;
	IBOutlet	NSButton		*button_cancel;
	
	ESFileTransfer	*fileTransfer;
	id	target;
	SEL	selector;
}

+ (void)displayPromptForFileTransfer:(ESFileTransfer *)inFileTransfer
					 notifyingTarget:(id)inTarget
							selector:(SEL)inSelector;

- (IBAction)pressedButton:(id)sender;

@end
