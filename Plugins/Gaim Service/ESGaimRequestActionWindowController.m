//
//  ESGaimRequestActionWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed May 05 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
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
	
	[[requestWindowController window] makeKeyAndOrderFront:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict
{
	theInfoDict = [infoDict retain];
	
	[super initWithWindowNibName:windowNibName];
	
    return(self);
}

- (void)windowDidLoad
{
	NSAttributedString	*attribMsg;
	NSRect  newFrame, oldFrame, zeroFrame = NSMakeRect(0,0,0,0);
	
	NSArray		*buttonNamesArray = [theInfoDict objectForKey:@"Button Names"];
	NSString	*titleString = [theInfoDict objectForKey:@"TitleString"];
	NSString	*msg = [theInfoDict objectForKey:@"Message"];
	
	//msg may be in HTML; decode it just in case
	attribMsg = (msg ? [AIHTMLDecoder decodeHTML:msg] : nil);
	
	actionCount = [[theInfoDict objectForKey:@"Count"] intValue];
	callBacks = [[theInfoDict objectForKey:@"callBacks"] retain];
	userData = [[theInfoDict objectForKey:@"userData"] retain];

	//Title
	[textField_title setStringValue:(titleString ? titleString : @"")];

	//Set the message, then change the window size accordingly
	{
		[textView_msg setVerticallyResizable:YES];
		[textView_msg setDrawsBackground:NO];
		[scrollView_msg setDrawsBackground:NO];

		NSRect  frame = [[self window] frame];
		int		heightChange;

		[[textView_msg textStorage] setAttributedString:attribMsg];
		[textView_msg sizeToFit];
		heightChange = [textView_msg frame].size.height - [scrollView_msg documentVisibleRect].size.height;
		
		frame.size.height += heightChange;
		frame.origin.y -= heightChange;
		
		if(!titleString){
			if([textField_title respondsToSelector:@selector(setHidden:)]){
				[textField_title setHidden:YES];
			}
			
			NSRect scrollFrame = [scrollView_msg frame];
			NSRect textFrame = [textField_title frame];
			int verticalChange = textFrame.size.height + 8;

			scrollFrame.origin.y += verticalChange;
			textFrame.origin.y += verticalChange;
			
			//frame.size.height -= verticalChange;
			frame.origin.y += heightChange;
			
			[scrollView_msg setFrame:scrollFrame];
			[textView_msg setFrame:textFrame];
		}
		
		//Resize the window to fit the message
		[[self window] setFrame:frame display:YES animate:YES];
	}
	
	//The last object in the array is the default
	//Size the default button, maintaining its rightmost edge's position
	{		
		[button_default setTitle:[buttonNamesArray objectAtIndex:(actionCount-1)]];
	}
	
	if (actionCount < 2) {
		[button_alternate setFrame:zeroFrame];
	}else{
		//Apply the title and shift the button left to maintain distance between the alternate's right and the default's left
		[button_alternate setTitle:[buttonNamesArray objectAtIndex:(actionCount-2)]];
		
		if (actionCount < 3){
			[button_other setFrame:zeroFrame];
		}else{
			[button_other setTitle:[buttonNamesArray objectAtIndex:(actionCount-3)]];
		}
	}
}

- (IBAction)pressedButton:(id)sender
{
	GCallback *theCallbacks = [callBacks pointerValue];
	int callBackIndex = -1;
	
	if (sender == button_default){
		NSLog(@"default");
		callBackIndex = (actionCount - 1);
		
	}else if (sender == button_alternate){
		NSLog(@"alternate");
		callBackIndex = (actionCount - 2);
		
	}else if (sender == button_other){
		NSLog(@"other");

		callBackIndex = (actionCount - 3);
	}

	if ((callBackIndex != -1) && (theCallbacks[callBackIndex] != NULL)){
		[[SLGaimCocoaAdapter sharedInstance] doRequestActionCbValue:[NSValue valueWithPointer:theCallbacks[callBackIndex]]
												  withUserDataValue:userData
													  callBackIndex:[NSNumber numberWithInt:callBackIndex]];
		
		[[self window] close];
	}
}

- (BOOL)windowShouldClose:(id)sender
{	
	return YES;
}

- (void)dealloc
{
	[theInfoDict release];
	[userData release];
	[callBacks release];
	
	[super dealloc];
}

@end
