//
//  ESGaimRequestActionController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed May 05 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimRequestActionController.h"
#import "ESTextAndButtonsWindowController.h"

@implementation ESGaimRequestActionController

+ (void)showActionWindowWithDict:(NSDictionary *)infoDict
{
	ESTextAndButtonsWindowController	*controller;

	NSAttributedString	*attributedMessage;
	NSArray				*buttonNamesArray;
	NSString			*title, *message;
	NSString			*defaultButton, *alternateButton = nil, *otherButton = nil;
	unsigned			buttonNamesArrayCount;

	title = [infoDict objectForKey:@"TitleString"];
	
	//message may be in HTML. If it's plain text, we'll just be getting an attributed string out of this.
	message = [infoDict objectForKey:@"Message"];
	attributedMessage = (message ? [AIHTMLDecoder decodeHTML:message] : nil);

	buttonNamesArray = [infoDict objectForKey:@"Button Names"];
	buttonNamesArrayCount = [buttonNamesArray count];

	//The last object in the buttons array is the default; alternate is second to last; otherButton is last
	defaultButton = [buttonNamesArray lastObject];
	if(buttonNamesArrayCount > 1){
		alternateButton = [buttonNamesArray objectAtIndex:(buttonNamesArrayCount-2)];
		
		if(buttonNamesArrayCount > 2){
			otherButton = [buttonNamesArray objectAtIndex:(buttonNamesArrayCount-3)];			
		}
	}

	/*
	 * If we have an attribMsg and a titleString, use the titleString as the window title.
	 * If we just have the titleString (and no attribMsg), it is our message, and the window has no title.
	 */
	controller = [ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:(attributedMessage ? title : nil)
																	   defaultButton:defaultButton
																	 alternateButton:alternateButton
																		 otherButton:otherButton
																			onWindow:nil
																   withMessageHeader:(!attributedMessage ? title : nil)
																		  andMessage:attributedMessage
																			  target:self
																			userInfo:infoDict];
	[controller setAllowsCloseWithoutResponse:NO];
}

+ (void)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	GCallback		*theCallBacks;
	unsigned int	actionCount;
	int				callBackIndex;

	theCallBacks = [[userInfo objectForKey:@"callBacks"] pointerValue];
	actionCount = [[userInfo objectForKey:@"Button Names"] count];

	callBackIndex = -1;
		
	switch(returnCode){
		case AITextAndButtonsDefaultReturn:
			NSLog(@"Default");
			callBackIndex = (actionCount - 1);
			break;
			
		case AITextAndButtonsAlternateReturn:
			NSLog(@"Alternate");
			callBackIndex = (actionCount - 2);
			break;

		case AITextAndButtonsOtherReturn:
			NSLog(@"Other");
			callBackIndex = (actionCount - 3);
			break;
			
		case AITextAndButtonsClosedWithoutResponse:
			NSLog(@"Should not have gotten here!");
			break;
	}

	if ((callBackIndex != -1) && (theCallBacks[callBackIndex] != NULL)){
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestActionCbValue:withUserDataValue:inputString:)
											  withObject:[NSValue valueWithPointer:theCallBacks[callBackIndex]]
											  withObject:[userInfo objectForKey:@"userData"]
											  withObject:[NSNumber numberWithInt:callBackIndex]];
	}else{
		NSLog(@"Failure.");
	}
}

+ (oneway void)gaimThreadDoRequestActionCbValue:(NSValue *)callBackValue
							  withUserDataValue:(NSValue *)userDataValue 
								  callBackIndex:(NSNumber *)callBackIndexNumber
{
	GaimRequestActionCb callBack = [callBackValue pointerValue];
	if (callBack){
		callBack([userDataValue pointerValue],[callBackIndexNumber intValue]);
	}
}

@end
