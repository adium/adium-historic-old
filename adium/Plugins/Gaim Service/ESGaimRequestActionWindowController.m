//
//  ESGaimRequestActionWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed May 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ESGaimRequestActionWindowController.h"

#define REQUEST_ACTION_WINDOW_NIB   @"GaimActionRequestWindow"

@interface ESGaimRequestActionWindowController (PRIVATE)
- (void)showWindowWithDict:(NSDictionary *)infoDict;
@end

@implementation ESGaimRequestActionWindowController

+ (void)showActionWindowWithDict:(NSDictionary *)infoDict
{
	ESGaimRequestActionWindowController	*requestWindowController;

	requestWindowController = [[self alloc] initWithWindowNibName:REQUEST_ACTION_WINDOW_NIB
														 withDict:infoDict];
	
	[requestWindowController showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict
{
	[super initWithWindowNibName:windowNibName];
	[self showWindowWithDict:infoDict];
	
    return(self);
}

- (void)showWindowWithDict:(NSDictionary *)infoDict
{
	NSRect  newFrame, oldFrame, zeroFrame = NSMakeRect(0,0,0,0);
	
	NSArray		*buttonNamesArray = [infoDict objectForKey:@"Button Names"];
	NSString	*titleString = [infoDict objectForKey:@"TitleString"];
	NSString	*msg = [infoDict objectForKey:@"Message"];
		
	actionCount = [[infoDict objectForKey:@"Count"] intValue];
	callBacks = [[infoDict objectForKey:@"callBacks"] retain];
	userData = [[infoDict objectForKey:@"userData"] retain];
	
	//Ensure the window is loaded
	[self window];
	
	//Title
	[textField_title setStringValue:(titleString ? titleString : @"")];

	//Set the message, then change the window size accordingly
	{
		[textView_msg setVerticallyResizable:YES];
		[textView_msg setDrawsBackground:NO];
		[scrollView_msg setDrawsBackground:NO];

		NSRect  frame = [[self window] frame];
		int		heightChange;

		[textView_msg setString:(msg ? msg : @"")];
		[textView_msg sizeToFit];
		heightChange = [textView_msg frame].size.height - [scrollView_msg documentVisibleRect].size.height;
		
		frame.size.height += heightChange;
		frame.origin.y -= heightChange;
		
		//Resize the window to fit the message
		[[self window] setFrame:frame display:YES animate:YES];
	}
	
	//The last object in the array is the default
	//Size the default button, maintaining its rightmost edge's position
	float   defaultButtonWidthChange, alternateButtonChange;
	{		
		oldFrame = [button_default frame];
		[button_default setTitle:[buttonNamesArray objectAtIndex:(actionCount-1)]];
		[button_default sizeToFit];
		
		newFrame = [button_default frame];
		defaultButtonWidthChange = (newFrame.size.width - oldFrame.size.width);
		newFrame.origin.x = oldFrame.origin.x - defaultButtonWidthChange;	
		[button_default setFrame:newFrame];
	}
	
	if (actionCount < 2) {
		[button_alternate setFrame:zeroFrame];
	}else{
		//Apply the title and shift the button left to maintain distance between the alternate's right and the default's left
		oldFrame = [button_alternate frame];
		[button_alternate setTitle:[buttonNamesArray objectAtIndex:(actionCount-2)]];
		[button_alternate sizeToFit];
		
		newFrame = [button_alternate frame];
		alternateButtonChange = (newFrame.size.width - oldFrame.size.width) + defaultButtonWidthChange;
		newFrame.origin.x = oldFrame.origin.x - alternateButtonChange;
		[button_alternate setFrame:newFrame];
		
		if (actionCount < 3){
			[button_other setFrame:zeroFrame];
		}else{
			oldFrame = [button_other frame];
			[button_other setTitle:[buttonNamesArray objectAtIndex:(actionCount-3)]];
			[button_other sizeToFit];
			
			newFrame = [button_other frame];
			newFrame.origin.x = oldFrame.origin.x - (newFrame.size.width - oldFrame.size.width) - alternateButtonChange;
			[button_other setFrame:newFrame];
		}
	}
}

- (IBAction)pressedButton:(id)sender
{
	GCallback *theCallbacks = [callBacks pointerValue];
	int callBackIndex = -1;
	
	if (sender == button_default){
		callBackIndex = (actionCount - 1);
		
	}else if (sender == button_alternate){
		callBackIndex = (actionCount - 2);
		
	}else if (sender == button_other){
		callBackIndex = (actionCount - 3);
	}

	if ((callBackIndex != -1) && (theCallbacks[callBackIndex] != NULL)){
		((GaimRequestActionCb)theCallbacks[callBackIndex])([userData pointerValue], callBackIndex);
		[[self window] close];
	}
}

- (BOOL)windowShouldClose:(id)sender
{	
	return YES;
}

- (void)dealloc
{
	[userData release];
	[callBacks release];
}

@end
