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
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict multiline:(BOOL)multiline
{
    [super initWithWindowNibName:windowNibName];
	[self showWindowWithDict:infoDict multiline:multiline];
	
    return(self);
}

- (void)showWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline
{	
	NSRect  oldFrame, newFrame;
	float   changeInTextHeight = 0;
	
	//Ensure the window is loaded
	[self window];
	
	//Buttons
	{
		//Use the supplied OK text, then shift the button left so that the right side remains in the old location in the window
		NSString *okText = [infoDict objectForKey:@"OK Text"];
		if ([okText isEqualToString:@"OK"]){
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
		if ([primary length]){
			[textField_primary setStringValue:primary];
			[textField_primary sizeToFit];
		}else{
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
		NSString *secondary = [infoDict objectForKey:@"Secondary Text"];
		
		oldFrame = [textField_secondary frame];
		if ([secondary length]){
			[textField_secondary setStringValue:secondary];
			[textField_secondary sizeToFit];
		}else{
			[textField_secondary setStringValue:@""];
			[textField_secondary setFrame:NSMakeRect(0,0,0,0)];
			changeInTextHeight -= 8;
		}
		newFrame = [textField_secondary frame];
		
		changeInTextHeight += (newFrame.size.height - oldFrame.size.height);

		newFrame.origin.y = oldFrame.origin.y - changeInTextHeight;
		[textField_secondary setFrame:newFrame];
	}
	
	//Default value
	{
		NSString *defaultValue = [infoDict objectForKey:@"Default Value"];
		[textField_input setStringValue:(defaultValue ? defaultValue : @"")];
		[textField_input selectText:nil];
	}
	
	//Text input frame size
	{
		if (multiline){
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
	if (sender == button_okay){
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestInputCbValue:withUserDataValue:inputString:)
											  withObject:okayCallbackValue
											  withObject:userDataValue
											  withObject:[[[textField_input stringValue] copy] autorelease]];

		[cancelCallbackValue release]; cancelCallbackValue = nil;
		[[self window] close];
		
	}else if (sender == button_cancel){
		[[self window] performClose:nil];
	}
}

- (oneway void)gaimThreadDoRequestInputCbValue:(NSValue *)inCallBackValue
							 withUserDataValue:(NSValue *)inUserDataValue 
								   inputString:(NSString *)inString
{
	GaimRequestInputCb callBack = [inCallBackValue pointerValue];
	if (callBack){
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
	
	if (cancelCallbackValue){
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestInputCbValue:withUserDataValue:inputString:)
											  withObject:cancelCallbackValue
											  withObject:userDataValue
											  withObject:[[[textField_input stringValue] copy] autorelease]];
	}
}

@end
