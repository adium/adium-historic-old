/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIWindowController.h"

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

