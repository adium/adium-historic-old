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

@implementation ESApplescriptabilityController

- (void)finishIniting
{
}

- (void)beginClosing
{
}

//close
- (void)closeController
{
	
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

- (AIStatusSummary)myStatus
{
	if ([[adium accountController] oneOrMoreConnectedAccounts]) {
		AIStatus	*activeStatusState = [[adium statusController] activeStatusState];
		
		if ([activeStatusState statusType] != AIAvailableStatus) {
			if ([self myIdleTime]) {
				return AIAwayAndIdleStatus;
			} else {
				return AIAwayStatus;
			}
			
		} else if ([self myIdleTime]) {
			return AIIdleStatus;
		} else {
			return AIAvailableStatus;
		}
		
	} else {
		return AIOfflineStatus;	
	}
}

//Incomplete - make AIStatus scriptable, pass that in
- (void)setMyStatus:(AIStatusSummary)newStatus
{
	AIStatus	*activeStatusState = [[[adium statusController] activeStatusState] mutableCopy];
	
	switch (newStatus) {
		case AIAvailableStatus:
			[activeStatusState setStatusType:AIAvailableStatusType];
			break;
			
		case AIAwayStatus:
			[activeStatusState setStatusType:AIAwayStatusType];
			break;

		case AIIdleStatus:
		case AIAwayAndIdleStatus:
		case AIOfflineStatus:
			break;
			
		case AIUnknownStatus:
			break;
	}
	
	[[adium statusController] setActiveStatusState:activeStatusState];
	
	[activeStatusState release];
}

- (NSString *)myStatusMessage
{
	AIStatus	*activeStatusState = [[adium statusController] activeStatusState];
	
	return([[activeStatusState statusMessage] string]);
}

- (void)setMyStatusMessage:(NSString *)statusMessage
{
	AIStatus	*activeStatusState = [[[adium statusController] activeStatusState] mutableCopy];

	//Take the string and turn it into an attributed string (in case we were passed HTML)
	[activeStatusState setStatusMessage:[AIHTMLDecoder decodeHTML:statusMessage]];
		
	[[adium statusController] setActiveStatusState:activeStatusState];
	
	[activeStatusState release];	
}

#pragma mark Controller convenience
- (AIInterfaceController *)interfaceController{
    return([adium interfaceController]);
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
@end
