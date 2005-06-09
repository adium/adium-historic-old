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

#import "ESGaimRequestWindowController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/NDRunLoopMessenger.h>

#define MULTILINE_WINDOW_NIB	@"GaimMultilineRequestWindow"
#define SINGLELINE_WINDOW_NIB   @"GaimSinglelineRequestWindow"

@interface ESGaimRequestWindowController (PRIVATE)
- (void)showWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline;
@end

@implementation ESGaimRequestWindowController
 
+ (void)showInputWindowWithDict:(NSDictionary *)infoDict
{
	ESGaimRequestWindowController	*requestWindowController;
	BOOL							multiline = [[infoDict objectForKey:@"Multiline"] boolValue];
	
	requestWindowController = [[self alloc] initWithWindowNibName:(multiline ? MULTILINE_WINDOW_NIB : SINGLELINE_WINDOW_NIB)
														 withDict:infoDict
														multiline:multiline];
	
	[requestWindowController showWindow:nil];
	[[requestWindowController window] makeKeyAndOrderFront:nil];
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict multiline:(BOOL)multiline
{
    self = [super initWithWindowNibName:windowNibName];
	[self showWindowWithDict:infoDict multiline:multiline];
	
    return(self);
}

- (void)showWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline
{	
	NSRect		oldFrame, newFrame;
	NSRect		windowFrame;
	NSWindow	*window;
	float		changeInTextHeight = 0;
	
	//Ensure the window is loaded
	window = [self window];
	windowFrame = [window frame];

	//If masked, replace our textField_input with a secure one
	if ([[infoDict objectForKey:@"Masked"] boolValue]) {
		NSRect				inputFrame = [textField_input frame];
		NSSecureTextField	*secureTextField = [[[NSSecureTextField alloc] initWithFrame:inputFrame] autorelease];
		
		[[textField_input superview] addSubview:secureTextField];
		[secureTextField setNeedsDisplay:YES];
		[textField_input removeFromSuperview];
		textField_input = secureTextField;		
	}

	//Buttons
	{
		//Use the supplied OK text, then shift the button left so that the right side remains in the old location in the window
		NSString *okText = [infoDict objectForKey:@"OK Text"];
		if ([okText isEqualToString:@"OK"]) {
			okText = AILocalizedString(@"OK",nil);
		}
		
		[button_okay setTitle:okText];
		
		//Use the supplied Cancel text, then shift the button left
		NSString	*cancelText = [infoDict objectForKey:@"Cancel Text"];
		
		[button_cancel setTitle:cancelText];
	}
	
	//Window Title
	{
		NSString *title = [infoDict objectForKey:@"Title"];
		[[self window] setTitle:(title ? title : @"")];
	}
	
	//Primary text field
	{
		float		heightDifference;

		NSString	*primary = [infoDict objectForKey:@"Primary Text"];
		
		oldFrame = [textField_primary frame];
		[textField_primary setStringValue:(primary ? primary : @"")];
		if ([primary length]) {
			[textField_primary setStringValue:primary];
			[textField_primary sizeToFit];
		} else {
			[textField_primary setStringValue:@""];
			[textField_primary setFrame:NSMakeRect(0,0,0,0)];
		}
		
		newFrame = [textField_primary frame];
		heightDifference = (newFrame.size.height - oldFrame.size.height);
		changeInTextHeight += heightDifference;
		
		newFrame.origin.y = oldFrame.origin.y - heightDifference;
		[textField_primary setFrame:newFrame];
	}
	
	//Secondary text field
	{
		NSString	*secondary = [infoDict objectForKey:@"Secondary Text"];
		float		secondaryHeightChange;

		[textView_secondary setVerticallyResizable:YES];
		[textView_secondary setHorizontallyResizable:NO];
		[textView_secondary setDrawsBackground:NO];
		[textView_secondary setTextContainerInset:NSZeroSize];
		[scrollView_secondary setDrawsBackground:NO];
		
		[textView_secondary setString:(secondary ? secondary : @"")];
		
		//Resize the window frame to fit the error title
		[textView_secondary sizeToFit];
		secondaryHeightChange = [textView_secondary frame].size.height - [scrollView_secondary documentVisibleRect].size.height;
		changeInTextHeight += secondaryHeightChange;

//		changeInTextHeight += (newFrame.size.height - oldFrame.size.height);

//		newFrame.origin.y = oldFrame.origin.y - changeInTextHeight;
//		[textField_secondary setFrame:newFrame];
		
		windowFrame.size.height += changeInTextHeight;
		windowFrame.origin.y -= changeInTextHeight;

		//Resize the window to fit the message
		[window setFrame:windowFrame display:YES animate:NO];
	}
	
	//Default value
	{
		NSString *defaultValue = [infoDict objectForKey:@"Default Value"];
		[textField_input setStringValue:(defaultValue ? defaultValue : @"")];
		[textField_input selectText:nil];
	}
	
	//Text input frame size
	{
		if (multiline) {
			newFrame = [textField_input frame];
			newFrame.size.height = newFrame.size.height - changeInTextHeight;
			
			[textField_input setFrame:newFrame];
		}
	}
	
	okayCallbackValue = [[infoDict objectForKey:@"OK Callback"] retain];
	cancelCallbackValue = [[infoDict objectForKey:@"Cancel Callback"] retain];
	userDataValue = [[infoDict objectForKey:@"userData"] retain];
	
	[self showWindow:nil];
}

- (IBAction)pressedButton:(id)sender
{
	if (sender == button_okay) {
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestInputCbValue:withUserDataValue:inputString:)
											  withObject:okayCallbackValue
											  withObject:userDataValue
											  withObject:[[[textField_input stringValue] copy] autorelease]];

		[cancelCallbackValue release]; cancelCallbackValue = nil;
		[[self window] close];
		
	} else if (sender == button_cancel) {
		[[self window] performClose:nil];
	}
}

- (oneway void)gaimThreadDoRequestInputCbValue:(NSValue *)inCallBackValue
							 withUserDataValue:(NSValue *)inUserDataValue 
								   inputString:(NSString *)inString
{
	GaimRequestInputCb callBack = [inCallBackValue pointerValue];
	if (callBack) {
		callBack([inUserDataValue pointerValue],[inString UTF8String]);
	}	
}

- (void)dealloc
{
	[okayCallbackValue release]; okayCallbackValue = nil;
	[cancelCallbackValue release]; cancelCallbackValue = nil;
	[userDataValue release]; userDataValue = nil;
	
	[super dealloc];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	if (cancelCallbackValue) {
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestInputCbValue:withUserDataValue:inputString:)
											  withObject:cancelCallbackValue
											  withObject:userDataValue
											  withObject:[[[textField_input stringValue] copy] autorelease]];
	}
}

@end
