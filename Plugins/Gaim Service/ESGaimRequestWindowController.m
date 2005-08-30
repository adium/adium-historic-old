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
- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict;
@end

@implementation ESGaimRequestWindowController
 
+ (ESGaimRequestWindowController *)showInputWindowWithDict:(NSDictionary *)infoDict
{
	ESGaimRequestWindowController	*requestWindowController;
	BOOL							multiline = [[infoDict objectForKey:@"Multiline"] boolValue];
	
	if ((requestWindowController = [[self alloc] initWithWindowNibName:(multiline ? MULTILINE_WINDOW_NIB : SINGLELINE_WINDOW_NIB)
														 withDict:infoDict
															 multiline:multiline])) {
		[requestWindowController showWindow:nil];
		[[requestWindowController window] makeKeyAndOrderFront:nil];
	}
	
	return requestWindowController;
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict multiline:(BOOL)multiline
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		[self showWindowWithDict:[self translatedInfoDict:infoDict]
					   multiline:multiline];
	}
	
    return self;
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
		
		[button_okay setTitle:(okText ? okText : AILocalizedString(@"OK",nil))];
		
		//Use the supplied Cancel text, then shift the button left
		NSString	*cancelText = [infoDict objectForKey:@"Cancel Text"];
		
		[button_cancel setTitle:(cancelText ? cancelText : AILocalizedString(@"Cancel",nil))];
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

/*
 * @brief Translate the strings in the info dictionary
 *
 * The following declarations let genstrings know about what translations we want
 * AILocalizedString(@"Set your friendly name.","Title for the MSN display name setting dialogue box")
 * AILocalizedString(@"This is the name that other MSN buddies will see you as.", "Description for the MSN display name setting dialogue.")
 * AILocalizedString(@"Set your home phone number.", "Title for the dialogue prompting for your home phone number")
 * AILocalizedString(@"Set your work phone number.", "Title for the dialogue prompting for your work phone number")
 * AILocalizedString(@"Set your mobile phone number.", "Title for the dialogue prompting for your mobile phone number")
 */
- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict
{
	NSMutableDictionary	*translatedDict = [inDict mutableCopy];
	
	NSString	*primary = [inDict objectForKey:@"Primary Text"];
	NSString	*secondary = [inDict objectForKey:@"Secondary Text"];
	NSString	*okText = [inDict objectForKey:@"OK Text"];
	NSString	*cancelText = [inDict objectForKey:@"Cancel Text"];

	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];

	//Replace each string with a translated version if possible
	[translatedDict setObject:[thisBundle localizedStringForKey:primary
														  value:primary
														  table:nil]
					   forKey:@"Primary Text"];
	[translatedDict setObject:[thisBundle localizedStringForKey:secondary
														  value:secondary
														  table:nil]
					   forKey:@"Secondary Text"];
	[translatedDict setObject:[thisBundle localizedStringForKey:okText
														  value:okText
														  table:nil]
					   forKey:@"OK Text"];
	[translatedDict setObject:[thisBundle localizedStringForKey:cancelText
														  value:cancelText
														  table:nil]
					   forKey:@"Cancel Text"];
	
	return [translatedDict autorelease];
}

@end
