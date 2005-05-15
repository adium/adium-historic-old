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

#import "ESTextAndButtonsWindowController.h"
#import "AIDockController.h"

#define TEXT_AND_BUTTONS_WINDOW_NIB   @"TextAndButtonsWindow"

@interface ESTextAndButtonsWindowController (PRIVATE)
- (void)showWindowWithDict:(NSDictionary *)infoDict;
@end

@implementation ESTextAndButtonsWindowController

/*!
 * @brief Show a text and buttons window which will notify a target when a button is clicked or the window is closed.
 *
 * The buttons have titles of defaultButton, alternateButton, and otherButton.
 * The buttons are laid out on the lower-right corner of the window, with defaultButton on the right, alternateButton on
 * the left, and otherButton in the middle. 
 *
 * If defaultButton is nil or an empty string, a default localized button title (“OK” in English) is used. 
 * For the remaining buttons, the window displays them only if their corresponding button title is non-nil.
 *
 * @param inTitle Window title
 * @param inDefaultButton Rightmost button.  Localized OK if nil.
 * @param inAlternateButton Leftmost button.  Hidden if nil.
 * @param inOtherButton Middle button.  Hidden if nil. inAlternateButton must be non-nil for inOtherButton to be used.
 * @param parentWindow Window on which to display as a sheet.  Displayed as a normal window if nil.
 * @param inMessageHeader A plain <tt>NSString</tt> which will be displayed as a bolded header for the message.  Hidden if nil.
 * @param inMessage The <tt>NSAttributedString</tt> which is the body of text for the window.
 * @param target The target to send the selector <tt>textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo</tt> when the sheet ends.
 *
 * @see AITextAndButtonsReturnCode
 *
 * @result A retained <tt>ESTextAndButtonsWindowController</tt> which will handle releasing itself when the window is finished.
 */
+ (id)showTextAndButtonsWindowWithTitle:(NSString *)inTitle
						  defaultButton:(NSString *)inDefaultButton
						alternateButton:(NSString *)inAlternateButton
							otherButton:(NSString *)inOtherButton
							   onWindow:(NSWindow *)parentWindow
					  withMessageHeader:(NSString *)inMessageHeader
							 andMessage:(NSAttributedString *)inMessage
								 target:(id)inTarget
							   userInfo:(id)inUserInfo
{
	ESTextAndButtonsWindowController	*controller;
	
	controller = [[self alloc] initWithWindowNibName:TEXT_AND_BUTTONS_WINDOW_NIB
										   withTitle:inTitle
									   defaultButton:inDefaultButton
									 alternateButton:inAlternateButton
										 otherButton:inOtherButton
								   withMessageHeader:inMessageHeader
										  andMessage:inMessage
											  target:inTarget
											userInfo:inUserInfo];
	
	if(parentWindow){
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];

	}else{
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
	}
	
	return controller;
}

/*!
 * @bref Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName
				  withTitle:(NSString *)inTitle
			  defaultButton:(NSString *)inDefaultButton
			alternateButton:(NSString *)inAlternateButton
				otherButton:(NSString *)inOtherButton
		  withMessageHeader:(NSString *)inMessageHeader
				 andMessage:(NSAttributedString *)inMessage
					 target:(id)inTarget
				   userInfo:(id)inUserInfo
{
	title = [inTitle retain];
	defaultButton = [inDefaultButton retain];
	alternateButton = [inAlternateButton retain];
	otherButton = [inOtherButton retain];
	messageHeader = [inMessageHeader retain];
	message = [inMessage retain];
	target = [inTarget retain];
	userInfo = [inUserInfo retain];
	userClickedButton = NO;
	allowsCloseWithoutResponse = YES;

	self = [super initWithWindowNibName:windowNibName];
	
    return(self);
}

/*!
 * @brief Can the window be closed without clicking one of the buttons?
 */
- (void)setAllowsCloseWithoutResponse:(BOOL)inAllowsCloseWithoutResponse
{
	allowsCloseWithoutResponse = inAllowsCloseWithoutResponse;
	
	[[[self window] standardWindowButton:NSWindowCloseButton] setEnabled:allowsCloseWithoutResponse];
}

/*!
 * @brief Refuse to let the window close, if allowsCloseWithoutResponse = NO
 */
- (BOOL)windowShouldClose:(id)sender
{
	if(!userClickedButton){
		if(allowsCloseWithoutResponse){
			//Notify the target that the window closed with no response
			[target textAndButtonsWindowDidEnd:[self window]
									returnCode:AITextAndButtonsClosedWithoutResponse
									  userInfo:userInfo];
		}else{
			//Don't allow the close
			NSBeep();
			return(NO);
		}
	}
	
	return(YES);
}

/*!
 * @brief Perform behaviors before the window closes
 *
 * If the user did not click a button to get us here, inform the target that the window closed
 * with no response, sending it the AITextAndButtonsClosedWithoutResponse return code (default behavior)
 *
 * As our window is closing, we auto-release this window controller instance.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[self autorelease];
	
	//Release our target immediately to avoid a potential mutual retain (if the target is retaining us)
	[target release]; target = nil;
}

/*!
 * @brief Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

/*!
 * @brief Window loaded.
 *
 * Here we perform configuration and autosizing for our message and buttons.
 */
- (void)windowDidLoad
{
	NSWindow	*window = [self window];

	[super windowDidLoad];

	//Hide the toolbar and zoom buttons
	[[[self window] standardWindowButton:NSWindowToolbarButton] setFrame:NSMakeRect(0,0,0,0)];
	[[[self window] standardWindowButton:NSWindowZoomButton] setFrame:NSMakeRect(0,0,0,0)];
	
	//Title
	if(title){
		[window setTitle:title];
	}else{
		[window setExcludedFromWindowsMenu:YES];
	}

	//Message header
	int		headerHeightChange, heightChange = 0;
	NSRect  frame = [window frame];
	
	[textView_messageHeader setVerticallyResizable:YES];
	[textView_messageHeader setDrawsBackground:NO];
	[scrollView_messageHeader setDrawsBackground:NO];
	
	[textView_messageHeader setString:(messageHeader ? messageHeader : @"")];
	
	//Resize the window frame to fit the error title
	[textView_messageHeader sizeToFit];
	headerHeightChange = [textView_messageHeader frame].size.height - [scrollView_messageHeader documentVisibleRect].size.height;
	heightChange += headerHeightChange;
	
	frame.size.height += heightChange;
	frame.origin.y -= heightChange;

	//Set the message, then change the window size accordingly
	{
		[textView_message setVerticallyResizable:YES];
		[textView_message setDrawsBackground:NO];
		[scrollView_message setDrawsBackground:NO];
		
		[[textView_message textStorage] setAttributedString:message];
		[textView_message sizeToFit];
		heightChange += [textView_message frame].size.height - [scrollView_message documentVisibleRect].size.height;
		
		frame.size.height += heightChange;
		frame.origin.y -= heightChange;

		//Adjust the message's scrollView's frame to account for the movement of the header
		NSRect	infoFrame = [scrollView_message frame];
		infoFrame.origin.y -= headerHeightChange;
		[scrollView_message setFrame:infoFrame];
		
		if(!messageHeader){
			if([scrollView_messageHeader respondsToSelector:@selector(setHidden:)]){
				[scrollView_messageHeader setHidden:YES];
			}else{
				[scrollView_messageHeader setFrame:NSZeroRect];	
			}
			
			NSRect messageHeaderFrame = [scrollView_messageHeader frame];
			NSRect scrollFrame = [scrollView_message frame];
			
			//verticalChange is how far we can move our message area up since we don't have a messageHeader
			int verticalChange = (messageHeaderFrame.size.height +
								  (messageHeaderFrame.origin.y - NSMaxY(scrollFrame)));

			scrollFrame.origin.y += verticalChange;
			
			[scrollView_message setFrame:scrollFrame];
		}

		[scrollView_message setNeedsDisplay:YES];
		
		//Resize the window to fit the message
		[window setFrame:frame display:YES animate:YES];
	}
	
	//Set the default button
	[button_default setLocalizedString:(defaultButton ? defaultButton : AILocalizedString(@"OK",nil))];

	//Set the alternate button if we were provided one, otherwise hide it
	if(alternateButton){
		[button_alternate setLocalizedString:alternateButton];

		//Set the other button if we were provided one, otherwise hide it
		if(otherButton){
			[button_other setLocalizedString:otherButton];

		}else{
			if([button_other respondsToSelector:@selector(setHidden:)]){
				[button_other setHidden:YES];
			}else{
				[button_other setFrame:NSZeroRect];
			}			
		}
	}else{
		if([button_alternate respondsToSelector:@selector(setHidden:)]){
			[button_alternate setHidden:YES];
		}else{
			[button_alternate setFrame:NSZeroRect];
		}
	}

    //Center the window (if we're not a sheet)
    [[self window] center];
}

- (IBAction)pressedButton:(id)sender
{
	AITextAndButtonsReturnCode returnCode;
	
	userClickedButton = YES;

	if(sender == button_default)
		returnCode = AITextAndButtonsDefaultReturn;
	else if(sender == button_alternate)
		returnCode = AITextAndButtonsAlternateReturn;			
	else if (sender == button_other)
		returnCode = AITextAndButtonsOtherReturn;
	else
		returnCode = AITextAndButtonsClosedWithoutResponse;

	//Notify the target
	if([target textAndButtonsWindowDidEnd:[self window]
							   returnCode:returnCode
								 userInfo:userInfo]){
		
		//Close the window if the target returns YES
		[[self window] close];
	}
}



- (void)dealloc
{
	[title release];
	[defaultButton release];
	[target release];
	[alternateButton release];
	[otherButton release];
	[messageHeader release];
	[message release];
	[userInfo release];
	
	[super dealloc];
}

@end
