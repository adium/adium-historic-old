//
//  ESApplescriptabilityController.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 24 2004.
//

#import "ESApplescriptabilityController.h"


@implementation ESApplescriptabilityController

//init
- (void)initController
{

}

//close
- (void)closeController
{
	
}

#pragma mark Convenience
- (NSArray *)accounts
{
	return ([[owner accountController] accountArray]);
}
- (NSArray *)contacts
{
	return ([[owner contactController] allContactsInGroup:nil
												subgroups:YES
												onAccount:nil]);
}
- (NSArray *)chats
{
	return ([[owner contentController] chatArray]);
}

#pragma mark Attributes
- (NSTimeInterval)myIdleTime
{
	NSDate  *idleSince = [[owner preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
	return (-[idleSince timeIntervalSinceNow]);
}
- (void)setMyIdleTime:(NSTimeInterval)timeInterval
{
	[[owner notificationCenter] postNotificationName:Adium_RequestSetManualIdleTime	
											  object:[NSNumber numberWithDouble:timeInterval]
											userInfo:nil];
}

- (NSData *)defaultImageData
{
	return ([[owner preferenceController] preferenceForKey:KEY_USER_ICON 
													 group:GROUP_ACCOUNT_STATUS]);
			
}
- (void)setDefaultImage:(NSData *)newDefaultImageData
{
	[[owner preferenceController] setPreference:newDefaultImageData
										 forKey:KEY_USER_ICON 
										  group:GROUP_ACCOUNT_STATUS];	
}

- (AIStatusSummary)myStatus
{
	if ([[owner accountController] oneOrMoreConnectedAccounts]){
		
		//Of course, it's AIM-centric to assume that an AwayMessage = "I am away"... but pending a status rewrite, this'll work.
		if ([[owner preferenceController] preferenceForKey:@"AwayMessage"
													 group:GROUP_ACCOUNT_STATUS]){
			if ([self myIdleTime]){
				return AIAwayAndIdleStatus;
			}else{
				return AIAwayStatus;
			}
			
		}else if([self myIdleTime]){
			return AIIdleStatus;
		}else{
			return AIAvailableStatus;
		}
		
	}else{
		return AIOfflineStatus;	
	}
}

//Incomplete - use setMyIdleTime and setMyStatusMessage
- (void)setMyStatus:(AIStatusSummary)newStatus
{
	if (newStatus == AIAvailableStatus){
		[[owner preferenceController] setPreference:nil forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
	}
}

- (NSString *)myStatusMessage
{
	return [[[[owner preferenceController] preferenceForKey:@"AwayMessage"
													  group:GROUP_ACCOUNT_STATUS] attributedString] string];
}
- (void)setMyStatusMessage:(NSString *)statusMessage
{
	//Take the string and turn it into an attributed string (in case we were passed HTML)
	NSData  *attributedStatusMessage = [[AIHTMLDecoder decodeHTML:statusMessage] dataRepresentation];

	//Set the away
    [[owner preferenceController] setPreference:attributedStatusMessage forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
    [[owner preferenceController] setPreference:nil forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
	
}

#pragma mark Controller convenience
- (AIInterfaceController *)interfaceController{
    return([owner interfaceController]);
}


- (AIChat *)createChatCommand:(NSScriptCommand *)command 
{
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*UID = [evaluatedArguments objectForKey:@"UID"];
	NSString		*serviceID = [evaluatedArguments objectForKey:@"serviceID"];
	AIListContact   *contact;
	AIChat			*chat = nil;

	contact = [[owner contactController] preferredContactWithUID:UID
													andServiceID:serviceID 
										   forSendingContentType:CONTENT_MESSAGE_TYPE];

	if(contact){
		//Open the chat and set it as active
		chat = [[owner contentController] openChatWithContact:contact];
		[[owner interfaceController] setActiveChat:chat];
	}
	
	return chat;
}
@end
