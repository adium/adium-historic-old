//
//  ESTextAndButtonsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 2/8/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	AITextAndButtonsDefaultReturn			= 1,
    AITextAndButtonsAlternateReturn			= 0,
	AITextAndButtonsOtherReturn				= -1,
	AITextAndButtonsClosedWithoutResponse	= -2
} AITextAndButtonsReturnCode;

@interface ESTextAndButtonsWindowController : AIWindowController {
    IBOutlet	NSTextField		*textField_messageHeader;
    IBOutlet	NSTextView		*textView_message;
    IBOutlet	NSScrollView	*scrollView_message;
	IBOutlet	NSButton		*button_default;
	IBOutlet	NSButton		*button_alternate;
	IBOutlet	NSButton		*button_other;

	NSString			*title;
	NSString			*defaultButton;
	NSString			*alternateButton;
	NSString			*otherButton;
	NSString			*messageHeader;
	NSAttributedString	*message;
	id					target;
	id					userInfo;
	
	BOOL				userClickedButton; //Did the user click a button to begin closing the window?
	BOOL				allowsCloseWithoutResponse; //Is it okay to close without clicking a button?
}

+ (id)showTextAndButtonsWindowWithTitle:(NSString *)inTitle
						  defaultButton:(NSString *)inDefaultButton
						alternateButton:(NSString *)inAlternateButton
							otherButton:(NSString *)inOtherButton
							   onWindow:(NSWindow *)parentWindow
					  withMessageHeader:(NSString *)inMessageHeader
							 andMessage:(NSAttributedString *)inMessage
								 target:(id)inTarget
							   userInfo:(id)inUserInfo;

- (id)initWithWindowNibName:(NSString *)windowNibName
				  withTitle:(NSString *)inTitle
			  defaultButton:(NSString *)inDefaultButton
			alternateButton:(NSString *)inAlternateButton
				otherButton:(NSString *)inOtherButton
		  withMessageHeader:(NSString *)inMessageHeader
				 andMessage:(NSAttributedString *)inMessage
					 target:(id)inTarget
				   userInfo:(id)inUserInfo;

- (IBAction)pressedButton:(id)sender;

- (void)setAllowsCloseWithoutResponse:(BOOL)inAllowsCloseWithoutResponse;

@end

@interface NSObject (ESTextAndButtonsTarget)
- (void)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo;
@end

