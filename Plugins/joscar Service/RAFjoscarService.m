//
//  RAFjoscarService.m
//  Adium
//
//  Created by Augie Fackler on 11/21/05.
//

#import "RAFjoscarService.h"
#import "AIStatusController.h"
#import "RAFjoscarAccount.h"
#import "RAFjoscarAccountViewController.h"
#import "ESjoscarJoinChatViewController.h"
#import <Adium/DCJoinChatViewController.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIStringUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIObject.h>
#import "AIAdium.h"

@implementation RAFjoscarService

//this service type should never be directly accessed, only subclasses should be.

//subclass should change this
- (Class)accountClass{
	return [RAFjoscarAccount class];
}

//Account Creation
- (AIAccountViewController *)accountViewController{
    return [RAFjoscarAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [ESjoscarJoinChatViewController joinChatView];
}

- (BOOL)canCreateGroupChats{
	return YES;
}

- (NSString *)serviceClass
{
	return @"AIM-compatible";
}

- (NSCharacterSet *)allowedCharacters
{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "];
}

- (NSCharacterSet *)allowedCharactersForUIDs
{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "];	
}

- (int)allowedLength
{
	return(28);
}
- (int)allowedLengthForUIDs
{
	return(28);
}

- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@" "];
}

- (BOOL)caseSensitive{
	return NO;
}

- (NSString *)userNameLabel{
    return AILocalizedString(@"Screen Name",nil); //ScreenName
}

#pragma mark Statuses
/*!
* @brief Register statuses
 */
- (void)registerStatuses{
	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_AWAY
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_INVISIBLE
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_INVISIBLE]
									  ofType:AIInvisibleStatusType
								  forService:self];
}

@end
