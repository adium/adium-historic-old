//
//  AIJavaScriptBridge.m
//  Adium
//
//  Created by David Smith on 12/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIJavaScriptBridge.h"
#import <Adium/AIFileTransferControllerProtocol.h>
#import "AIWebKitMessageViewStyle.h"
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebFrameViewAdditions.h"
#import "ESWebKitMessageViewPreferences.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIFileTransferControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AIEmoticon.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import "ESFileTransferRequestPromptController.h"

#import "ESWebView.h"
@implementation AIWebKitMessageViewController (JSBridging)

- (void)handleAction:(NSString *)action forFileTransfer:(NSString *)fileTransferID
{
	ESFileTransfer *fileTransfer = [ESFileTransfer existingFileTransferWithID:fileTransferID];
	ESFileTransferRequestPromptController *tc = [fileTransfer fileTransferRequestPromptController];
	
	if (tc) {
		AIFileTransferAction a;
		if ([action isEqualToString:@"SaveAs"])
			a = AISaveFileAs;
		else if ([action isEqualToString:@"Cancel"]) 
			a = AICancel;
		else
			a = AISaveFile;
		
		[tc handleFileTransferAction:a];
	}
}

- (NSString *) loadTemplate:(NSString *)templateName
{
	return [NSString stringWithContentsOfURL:[NSURL URLWithString:[self getResourceURL:templateName]]];
}

- (NSString *) backgroundStyle
{
	return @"background-color: rgba(255, 255, 255, 1.0)";
}

- (NSString *) getResourceURL:(NSString *)resourceName
{
	NSString *resource = [[styleBundle resourcePath] stringByAppendingPathComponent:resourceName];
	if(![[NSFileManager defaultManager] fileExistsAtPath:resource])
		resource = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:resourceName];
	if(resource && [resource length] > 0)
		return [[NSURL fileURLWithPath:resource] absoluteString];
	return @"";
}
- (AIChat *)chat
{
	return chat;
}

/*See http://developer.apple.com/documentation/AppleApplications/Conceptual/SafariJSProgTopics/Tasks/ObjCFromJavaScript.html#//apple_ref/doc/uid/30001215 for more information.
*/

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	if(aSelector == @selector(handleAction:forFileTransfer:)) return NO;
	if(aSelector == @selector(debugLog:)) return NO;
	if(aSelector == @selector(loadTemplate:)) return NO;
	if(aSelector == @selector(backgroundStyle)) return NO;
	if(aSelector == @selector(getResourceURL:)) return NO;
	if(aSelector == @selector(chat)) return NO;
	//return YES;
	return NO;
}

/*
 * This method returns the name to be used in the scripting environment for the selector specified by aSelector.
 * It is your responsibility to ensure that the returned name is unique to the script invoking this method.
 * If this method returns nil or you do not implement it, the default name for the selector will be constructed as follows:
 *
 * Any colon (“:”)in the Objective-C selector is replaced by an underscore (“_”).
 * Any underscore in the Objective-C selector is prefixed with a dollar sign (“$”).
 * Any dollar sign in the Objective-C selector is prefixed with another dollar sign.
 */
+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	if(aSelector == @selector(handleAction:forFileTransfer:)) return @"handleFileTransfer";
	if(aSelector == @selector(debugLog:)) return @"debugLog";
	if(aSelector == @selector(loadTemplate:)) return @"getResourceContents";
	if(aSelector == @selector(getResourceURL:)) return @"getResourceURL";
	return NSStringFromSelector(aSelector);
}

- (void)debugLog:(NSString *)message { NSLog(@"%@", message);}

	//gets the source of the html page, for debugging
- (NSString *)webviewSource
{
	return [(DOMHTMLHtmlElement *)[[[[webView mainFrame] DOMDocument] getElementsByTagName:@"html"] item:0] outerHTML];
}

@end

@implementation AIContentObject (JSBridging)

- (NSString *) getType
{
	return @"message";
}

- (NSString *) getID
{
	return uuid;
}

- (NSString *) localizedTimeStamp
{
#warning PERF
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	NSDateFormatter *timeStampFormatter = [[[NSDateFormatter alloc] initWithDateFormat:[prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT]
																  allowNaturalLanguage:NO] autorelease];
	NSDate *messageDate = nil;
	if ([self respondsToSelector:@selector(date)])
		messageDate = [(AIContentMessage *)self date];
	return messageDate != nil ? [timeStampFormatter stringForObjectValue:messageDate] : @"";
}

- (NSString *) wkmvMessageHTML
{
	return [self messageHTML];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	if(aSelector == @selector(wkmvMessageHTML)) return NO;
	if(aSelector == @selector(source)) return NO;
	if(aSelector == @selector(localizedTimeStamp)) return NO;
	if(aSelector == @selector(source)) return NO;
	if(aSelector == @selector(getType)) return NO;
	if(aSelector == @selector(getID)) return NO;
	return YES;
}

/*
 * This method returns the name to be used in the scripting environment for the selector specified by aSelector.
 * It is your responsibility to ensure that the returned name is unique to the script invoking this method.
 * If this method returns nil or you do not implement it, the default name for the selector will be constructed as follows:
 *
 * Any colon (“:”)in the Objective-C selector is replaced by an underscore (“_”).
 * Any underscore in the Objective-C selector is prefixed with a dollar sign (“$”).
 * Any dollar sign in the Objective-C selector is prefixed with another dollar sign.
 */
+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	if(aSelector == @selector(wkmvMessageHTML)) return @"HTMLContent";
	if(aSelector == @selector(source)) return @"sender";
	return NSStringFromSelector(aSelector);
}

@end

@implementation ESFileTransfer (JSBridging)

- (NSString *) getType
{
	return @"event";
}

/*
 TEMP
 */
- (NSString *) getTransferID
{
	return [[self uniqueID] stringByEscapingForXMLWithEntities:nil];
}

- (NSString *) getState
{
	return [NSString stringWithFormat:@"%f", percentDone];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	if(![super isSelectorExcludedFromWebScript:aSelector]) return NO;
	if(aSelector == @selector(getTransferID)) return NO;
	if(aSelector == @selector(getState)) return NO;
	return YES;
}
@end

@implementation AIContentEventTest (JSBridging)
- (NSString *) getType
{
	return @"event";
}
@end

@implementation AIChat (JSBridging)
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	if(aSelector == @selector(displayName)) return NO;
	return NO;
}

+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	if(aSelector == @selector(displayName)) return @"name";
	return NSStringFromSelector(aSelector);
}

@end

@implementation AIListObject (JSBridging)

- (NSString *) iconPath
{
	NSString    *userIconPath = nil;
	NSString	*replacementString = nil;
	
	userIconPath = [self statusObjectForKey:KEY_WEBKIT_USER_ICON];
	if (!userIconPath) {
		userIconPath = [self statusObjectForKey:@"UserIconPath"];
	}
	
	if (/*showUserIcons*/YES && userIconPath) {
		replacementString = [[NSURL fileURLWithPath:userIconPath] absoluteString];
		
	}
	return (replacementString != nil) ? replacementString : @"";
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	return NSStringFromSelector(aSelector);
}

@end
