//
//  ESGaimRequestWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Apr 14 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimRequestWindowController.h"

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
		}else{
			okText = AILocalizedString(okText,nil);	
		}
		
		[button_okay setTitle:okText];
		
		//Use the supplied Cancel text, then shift the button left
		NSString	*cancelText = [infoDict objectForKey:@"Cancel Text"];
		cancelText = AILocalizedString(cancelText, nil);
		
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
		
		oldFrame = [textField_primary frame];
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

		newFrame.origin.y = [textField_secondary frame].origin.y - newFrame.size.height - 8;
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

- (oneway void)gaimThreadDoRequestInputCbValue:(NSValue *)callBackValue
							 withUserDataValue:(NSValue *)userDataValue 
								   inputString:(NSString *)string
{
	GaimRequestInputCb callBack = [callBackValue pointerValue];
	if (callBack){
		callBack([userDataValue pointerValue],[string UTF8String]);
	}	
}

- (void)dealloc
{
	[okayCallbackValue release]; okayCallbackValue = nil;
	[cancelCallbackValue release]; cancelCallbackValue = nil;
	[userDataValue release]; userDataValue = nil;
	
	[super dealloc];
}

- (BOOL)windowShouldClose:(id)sender
{
	if (cancelCallbackValue){
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestInputCbValue:withUserDataValue:inputString:)
											  withObject:cancelCallbackValue
											  withObject:userDataValue
											  withObject:[[[textField_input stringValue] copy] autorelease]];
	}
	
	return YES;
}

@end
