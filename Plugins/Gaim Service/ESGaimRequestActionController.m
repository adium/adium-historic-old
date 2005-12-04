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
#import "GaimCommon.h"
#import "adiumGaimRequest.h"
#import "SLGaimCocoaAdapter.h"
#import "ESTextAndButtonsWindowController.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/NDRunLoopMessenger.h>

@interface ESGaimRequestActionController (PRIVATE)
- (id)initWithDict:(NSDictionary *)infoDict;
- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict;
- (void)gaimThreadDoRequestActionCbValue:(NSValue *)callBackValue
					   withUserDataValue:(NSValue *)userDataValue 
						   callBackIndex:(NSNumber *)callBackIndexNumber;
@end

@implementation ESGaimRequestActionController

/*
 * @brief Show an action request window
 *
 * @param infoDict Dictionary of information to display, including callbacks for the buttons
 * @result The ESGaimRequestActionController for the displayed window
 */
+ (ESGaimRequestActionController *)showActionWindowWithDict:(NSDictionary *)infoDict
{
	return [[self alloc] initWithDict:infoDict];
}

- (id)initWithDict:(NSDictionary *)infoDict
{
	if ((self = [super init])) {
		NSAttributedString	*attributedMessage;
		NSArray				*buttonNamesArray;
		NSString			*title, *message;
		NSString			*defaultButton, *alternateButton = nil, *otherButton = nil;
		unsigned			buttonNamesArrayCount;
		
		infoDict = [self translatedInfoDict:infoDict];
		
		title = [infoDict objectForKey:@"TitleString"];
		
		//message may be in HTML. If it's plain text, we'll just be getting an attributed string out of this.
		message = [infoDict objectForKey:@"Message"];
		attributedMessage = (message ? [AIHTMLDecoder decodeHTML:message] : nil);
		
		buttonNamesArray = [infoDict objectForKey:@"Button Names"];
		buttonNamesArrayCount = [buttonNamesArray count];
		
		//The last object in the buttons array is the default; alternate is second to last; otherButton is last
		defaultButton = [buttonNamesArray lastObject];
		if (buttonNamesArrayCount > 1) {
			alternateButton = [buttonNamesArray objectAtIndex:(buttonNamesArrayCount-2)];
			
			if (buttonNamesArrayCount > 2) {
				otherButton = [buttonNamesArray objectAtIndex:(buttonNamesArrayCount-3)];			
			}
		}
		
		/*
		 * If we have an attribMsg and a titleString, use the titleString as the window title.
		 * If we just have the titleString (and no attribMsg), it is our message, and the window has no title.
		 */
		requestController = [[ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:(attributedMessage ? title : nil)
																				   defaultButton:defaultButton
																				 alternateButton:alternateButton
																					 otherButton:otherButton
																						onWindow:nil
																			   withMessageHeader:(!attributedMessage ? title : nil)
																					  andMessage:attributedMessage
																						  target:self
																						userInfo:infoDict] retain];
		[requestController setAllowsCloseWithoutResponse:NO];
	}
	
	return self;
}

- (void)dealloc
{
	[requestController release]; requestController = nil;
	
	[super dealloc];
}

- (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	GCallback		*theCallBacks;
	unsigned int	actionCount;
	int				callBackIndex;

	theCallBacks = [[userInfo objectForKey:@"callBacks"] pointerValue];
	actionCount = [[userInfo objectForKey:@"Button Names"] count];

	callBackIndex = -1;
		
	switch (returnCode) {
		case AITextAndButtonsDefaultReturn:
			callBackIndex = (actionCount - 1);
			break;
			
		case AITextAndButtonsAlternateReturn:
			callBackIndex = (actionCount - 2);
			break;

		case AITextAndButtonsOtherReturn:
			callBackIndex = (actionCount - 3);
			break;
			
		case AITextAndButtonsClosedWithoutResponse:
			break;
	}

	if ((callBackIndex != -1) && (theCallBacks[callBackIndex] != NULL)) {
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestActionCbValue:withUserDataValue:callBackIndex:)
											  withObject:[NSValue valueWithPointer:theCallBacks[callBackIndex]]
											  withObject:[userInfo objectForKey:@"userData"]
											  withObject:[NSNumber numberWithInt:callBackIndex]];
	} else {
		NSLog(@"Failure.");
	}
	
	//We won't need to try to close it ourselves later
	[requestController release]; requestController = nil;
	
	//Inform libgaim that the request window closed
	[ESGaimRequestAdapter requestCloseWithHandle:self];	

	return YES;
}

- (void)gaimThreadDoRequestActionCbValue:(NSValue *)callBackValue
					   withUserDataValue:(NSValue *)userDataValue 
						   callBackIndex:(NSNumber *)callBackIndexNumber
{
	GaimRequestActionCb callBack = [callBackValue pointerValue];
	if (callBack) {
		callBack([userDataValue pointerValue],[callBackIndexNumber intValue]);
	}
}

/*
 * @brief libgaim has been made aware we closed or has informed us we should close
 *
 * Close our requestController's window if it's open; then release (we returned without autoreleasing initially).
 */
- (void)gaimRequestClose
{
	if (requestController) {
		[[requestController window] orderOut:self];
		[requestController close];
	}
	
	[self release];
}

/*
 * @brief Translate the strings in the info dictionary
 *
 * The following declarations let genstrings know about what translations we want
 * AILocalizedString(@"Allow MSN Mobile pages?", nil)
 * AILocalizedString(@"Do you want to allow or disallow people on your buddy list to send you MSN Mobile pages to your cell phone or other mobile device?", nil)
 * AILocalizedString(@"Allow","Button title to allow an action")
 * AILocalizedString(@"Disallow", "Button title to prevent an action")
 * AILocalizedString(@"Connect",nil)
 * AILocalizedString(@"Cancel", nil)
 */
- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict
{
	NSMutableDictionary	*translatedDict = [inDict mutableCopy];
	
	NSString		*title = [inDict objectForKey:@"TitleString"];
	NSString		*message = [inDict objectForKey:@"Message"];
	NSMutableArray	*buttonNamesArray = [NSMutableArray array];
	NSBundle		*thisBundle = [NSBundle bundleForClass:[self class]];
	NSString		*buttonName;
	NSEnumerator	*enumerator;

	//Replace each string with a translated version if possible
	[translatedDict setObject:[thisBundle localizedStringForKey:title
														  value:title
														  table:nil]
					   forKey:@"TitleString"];
	[translatedDict setObject:[thisBundle localizedStringForKey:message
														  value:message
														  table:nil]
					   forKey:@"Message"];
	
	enumerator = [[inDict objectForKey:@"Button Names"] objectEnumerator];
	while ((buttonName = [enumerator nextObject])) {
		[buttonNamesArray addObject:[thisBundle localizedStringForKey:buttonName
																value:buttonName
																table:nil]];
	}
	[translatedDict setObject:buttonNamesArray
					   forKey:@"Button Names"];

	return [translatedDict autorelease];
}

@end
