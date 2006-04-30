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

#import "AIAccountController.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import "ESApplescriptabilityController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIHTMLDecoder.h>

@interface ESApplescriptabilityController (PRIVATE)
- (void)prepareApplescriptRunner;
- (void)shutdownApplescriptRunner;
@end

@implementation ESApplescriptabilityController

- (void)controllerDidLoad
{
	[self prepareApplescriptRunner];
}


//close
- (void)controllerWillClose
{
	[self shutdownApplescriptRunner];
}

#pragma mark Convenience
- (NSArray *)accounts
{
	return ([[adium accountController] accounts]);
}
- (NSArray *)contacts
{
	return ([[adium contactController] allContactsInGroup:nil
												subgroups:YES
												onAccount:nil]);
}
- (NSArray *)chats
{
	return ([[[adium chatController] openChats] allObjects]);
}

#pragma mark Attributes
#warning Quite a bit in here is broken and needs to be rewritten for the new status system -eds
- (NSTimeInterval)myIdleTime
{
	NSDate  *idleSince = [[adium preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
	return (-[idleSince timeIntervalSinceNow]);
}
- (void)setMyIdleTime:(NSTimeInterval)timeInterval
{
	[[adium notificationCenter] postNotificationName:Adium_RequestSetManualIdleTime	
											  object:(timeInterval ? [NSNumber numberWithDouble:timeInterval] : nil)
											userInfo:nil];
}

- (NSData *)defaultImageData
{
	return ([[adium preferenceController] preferenceForKey:KEY_USER_ICON 
													 group:GROUP_ACCOUNT_STATUS]);
			
}
- (void)setDefaultImageData:(NSData *)newDefaultImageData
{
	[[adium preferenceController] setPreference:newDefaultImageData
										 forKey:KEY_USER_ICON 
										  group:GROUP_ACCOUNT_STATUS];	
}

- (AIStatus *)myStatus
{
	return [[adium statusController] activeStatusState];
}

//Incomplete - make AIStatus scriptable, pass that in
- (void)setMyStatus:(AIStatus *)newStatus
{
	if ([newStatus isKindOfClass:[AIStatus class]]) {
		[[adium statusController] setActiveStatusState:newStatus];
	} else {
		NSLog(@"Applescript error: Tried to set status to %@ which is of class %@.  This method expects an object of class %@.",newStatus, NSStringFromClass([newStatus class]),NSStringFromClass([AIStatus class]));
	}
}

- (AIStatusTypeApplescript)myStatusTypeApplescript
{
	return [[self myStatus] statusTypeApplescript];
	
}

- (void)setMyStatusTypeApplescript:(AIStatusTypeApplescript)newStatusType
{
	AIStatus *newStatus = [[self myStatus] mutableCopy];
	
	[newStatus setStatusTypeApplescript:newStatusType];
	[self setMyStatus:newStatus];
	
	[newStatus release];
}

- (NSString *)myStatusMessageString
{
	return [[self myStatus] statusMessageString];
}

- (void)setMyStatusMessageString:(NSString *)inString
{
	AIStatus *newStatus = [[self myStatus] mutableCopy];
	
	[newStatus setStatusMessageString:inString];
	[self setMyStatus:newStatus];
	
	[newStatus release];	
}

#pragma mark Controller convenience
- (AIInterfaceController *)interfaceController{
    return [adium interfaceController];
}


- (AIChat *)createChatCommand:(NSScriptCommand *)command 
{
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*UID = [evaluatedArguments objectForKey:@"UID"];
	NSString		*serviceID = [evaluatedArguments objectForKey:@"serviceID"];
	AIListContact   *contact;
	AIChat			*chat = nil;

	contact = [[adium contactController] preferredContactWithUID:UID
													andServiceID:serviceID 
										   forSendingContentType:CONTENT_MESSAGE_TYPE];

	if (contact) {
		//Open the chat and set it as active
		chat = [[adium chatController] openChatWithContact:contact];
		[[adium interfaceController] setActiveChat:chat];
	}
	
	return chat;
}

#pragma mark Running applescripts
- (void)_executeApplescriptWithDict:(NSDictionary *)executionDict
{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"AdiumApplescriptRunner_ExecuteScript"
																   object:nil
																 userInfo:executionDict
													   deliverImmediately:NO];
}

- (void)launchApplescriptRunner
{
	NSString *applescriptRunnerPath = [[NSBundle mainBundle] pathForResource:@"AdiumApplescriptRunner"
																	  ofType:nil
																 inDirectory:nil];

	//Houston, we are go for launch.
	if (applescriptRunnerPath) {
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus err = FSPathMakeRef((UInt8 *)[applescriptRunnerPath fileSystemRepresentation], &appRef, NULL);
		if (err == noErr) {
			spec.appRef = &appRef;
			spec.numDocs = 0;
			spec.itemRefs = NULL;
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchNoParams | kLSLaunchAsync;
			spec.asyncRefCon = NULL;
			err = LSOpenFromRefSpec(&spec, NULL);

			if (err != noErr) {
				NSLog(@"Could not launch %@",applescriptRunnerPath);
			}
		}
	} else {
		NSLog(@"Could not find AdiumApplescriptRunner...");
	}
}

/*
 * @brief Run an applescript, optinally calling a function with arguments, and notify a target/selector with its output when it is done
 */
- (void)runApplescriptAtPath:(NSString *)path function:(NSString *)function arguments:(NSArray *)arguments notifyingTarget:(id)target selector:(SEL)selector userInfo:(id)userInfo
{
	NSString *uniqueID = [[NSProcessInfo processInfo] globallyUniqueString];

	if (!runningApplescriptsDict) runningApplescriptsDict = [[NSMutableDictionary alloc] init];

	[runningApplescriptsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
		target, @"target",
		NSStringFromSelector(selector), @"selector",
		userInfo, @"userInfo", nil]
								forKey:uniqueID];
	
	NSDictionary *executionDict = [NSDictionary dictionaryWithObjectsAndKeys:
		path, @"path",
		(function ? function : @""), @"function",
		(arguments ? arguments : [NSArray array]), @"arguments",
		uniqueID, @"uniqueID",
		nil];
		
	if (applescriptRunnerIsReady) {
		[self _executeApplescriptWithDict:executionDict];

	} else {
		if (!pendingApplescriptsArray) pendingApplescriptsArray = [[NSMutableArray alloc] init];

		[pendingApplescriptsArray addObject:executionDict];

		[self launchApplescriptRunner];
	}
}

- (void)applescriptRunnerIsReady:(NSNotification *)inNotification
{
	NSEnumerator	*enumerator;
	NSDictionary	*executionDict;
	
	applescriptRunnerIsReady = YES;
	
	enumerator = [pendingApplescriptsArray objectEnumerator];
	while ((executionDict = [enumerator nextObject])) {
		[self _executeApplescriptWithDict:executionDict];		
	}
	
	[pendingApplescriptsArray release]; pendingApplescriptsArray = nil;
}

- (void)applescriptRunnerDidQuit:(NSNotification *)inNotification
{
	applescriptRunnerIsReady = NO;
}

- (void)applescriptDidRun:(NSNotification *)inNotification
{
	NSDictionary *userInfo = [inNotification userInfo];
	NSString	 *uniqueID = [userInfo objectForKey:@"uniqueID"];

	NSDictionary *targetDict = [runningApplescriptsDict objectForKey:uniqueID];
	id			 target = [targetDict objectForKey:@"target"];
	//Selector will be of the form applescriptDidRun:resultString:
	SEL			 selector = NSSelectorFromString([targetDict objectForKey:@"selector"]);

	//Notify our target
	[target performSelector:selector
				 withObject:[targetDict objectForKey:@"userInfo"]
				 withObject:[userInfo objectForKey:@"resultString"]];

	//No further need for this dictionary entry
	[runningApplescriptsDict removeObjectForKey:uniqueID];
}

- (void)prepareApplescriptRunner
{
	NSDistributedNotificationCenter *distributedNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
	[distributedNotificationCenter addObserver:self
									  selector:@selector(applescriptRunnerIsReady:)
										  name:@"AdiumApplescriptRunner_IsReady"
										object:nil];
	[distributedNotificationCenter addObserver:self
									  selector:@selector(applescriptRunnerDidQuit:)
										  name:@"AdiumApplescriptRunner_DidQuit"
										object:nil];

	[distributedNotificationCenter addObserver:self
									  selector:@selector(applescriptDidRun:)
										  name:@"AdiumApplescript_DidRun"
										object:nil];	

	//Check for an existing AdiumApplescriptRunner; if there is one, it will respond with AdiumApplescriptRunner_IsReady
	[distributedNotificationCenter postNotificationName:@"AdiumApplescriptRunner_RespondIfReady"
												 object:nil
											   userInfo:nil
									 deliverImmediately:NO];
}

- (void)shutdownApplescriptRunner
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"AdiumApplescriptRunner_Quit"
																   object:nil
																 userInfo:nil
													   deliverImmediately:NO];	
}
@end
