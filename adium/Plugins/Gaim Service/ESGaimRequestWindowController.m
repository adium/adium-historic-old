//
//  ESGaimRequestWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Apr 14 2004.
//

#import "ESGaimRequestWindowController.h"

#define MULTILINE_WINDOW_NIB	@"GaimMultilineRequestWindow"
#define SINGLELINE_WINDOW_NIB   @"GaimSinglelineRequestWindow"

@interface ESGaimRequestWindowController (PRIVATE)
- (void)showWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline masked:(BOOL)inMasked;
@end

@implementation ESGaimRequestWindowController
 
+ (void)showInputWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline masked:(BOOL)masked
{
	ESGaimRequestWindowController	*requestWindowController;
	
	requestWindowController = [[self alloc] initWithWindowNibName:(multiline ? MULTILINE_WINDOW_NIB : SINGLELINE_WINDOW_NIB)
														 withDict:infoDict
														multiline:multiline
														   masked:masked];
	
	[requestWindowController showWindow:nil];
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict multiline:(BOOL)multiline masked:(BOOL)masked
{
    [super initWithWindowNibName:windowNibName];
	[self showWindowWithDict:infoDict multiline:multiline masked:masked];
	
    return(self);
}

- (void)showWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline masked:(BOOL)inMasked
{	
	NSRect  oldFrame, newFrame;
	float   changeInTextHeight = 0;
	
	//Ensure the window is loaded;
	[self window];
	
	//Buttons
	{
		//Use the supplied OK text, then shift the button left so that the right side remains in the old location in the window
		NSString *okText = [infoDict objectForKey:@"OK Text"];
		if ([okText isEqualToString:@"OK"]){
			okText = AILocalizedString(@"Okay",nil);
		}
		
		float okayButtonWidthChange;
		
		oldFrame = [button_okay frame];
		[button_okay setTitle:okText];
		[button_okay sizeToFit];
		newFrame = [button_okay frame];
		okayButtonWidthChange = (newFrame.size.width - oldFrame.size.width);
		newFrame.origin.x = oldFrame.origin.x - okayButtonWidthChange;	
		[button_okay setFrame:newFrame];
		
		//Use the supplied Cancel text, then shift the button left
		NSString	*cancelText = [infoDict objectForKey:@"Cancel Text"];
		cancelText = AILocalizedString(cancelText, nil);
		
		oldFrame = [button_cancel frame];
		[button_cancel setTitle:cancelText];
		[button_cancel sizeToFit];
		newFrame = [button_cancel frame];
		newFrame.origin.x = oldFrame.origin.x - (newFrame.size.width - oldFrame.size.width) - okayButtonWidthChange;
		[button_cancel setFrame:newFrame];
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
		GaimRequestInputCb okayCallback = [okayCallbackValue pointerValue];
		if (okayCallback){
			okayCallback([userDataValue pointerValue],[[textField_input stringValue] UTF8String]);
			[cancelCallbackValue release]; cancelCallbackValue = nil;
		}
		[[self window] close];
		
	}else if (sender == button_cancel){
		[[self window] performClose:nil];
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
	GaimRequestInputCb cancelCallback = [cancelCallbackValue pointerValue];
	if (cancelCallback){
		cancelCallback([userDataValue pointerValue],[[textField_input stringValue] UTF8String]);
	}
	
	return YES;
}

@end
