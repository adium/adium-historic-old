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

#import "ESGaimRequestActionController.h"
#import "ESTextAndButtonsWindowController.h"
#import <AIUtilities/NDRunLoopMessenger.h>
#import <Adium/AIHTMLDecoder.h>

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
