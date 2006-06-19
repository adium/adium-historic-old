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

#ifndef JOSCAR_SUPERCEDE_LIBGAIM
/*!
* @brief Default icon
 *
 * Service Icon packs should always include images for all the built-in Adium services.  This method allows external
 * service plugins to specify an image which will be used when the service icon pack does not specify one.  It will
 * also be useful if new services are added to Adium itself after a significant number of Service Icon packs exist
 * which do not yet have an image for this service.  If the active Service Icon pack provides an image for this service,
 * this method will not be called.
 *
 * The service should _not_ cache this icon internally; multiple calls should return unique NSImage objects.
 *
 * @param iconType The AIServiceIconType of the icon to return. This specifies the desired size of the icon.
 * @return NSImage to use for this service by default
 */
- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType
{
	NSImage *baseImage = [NSImage imageNamed:@"aim" forClass:[self class]];
	
	if (iconType == AIServiceIconSmall) {
		baseImage = [baseImage imageByScalingToSize:NSMakeSize(16, 16)];
	}
	
	return baseImage;
}
#endif

@end
