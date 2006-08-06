//
//  RAFjoscarICQService.m
//  Adium
//
//  Created by Augie Fackler on 1/15/06.
//

#import "RAFjoscarICQService.h"
#import "RAFjoscarICQAccount.h"
#import "RAFjoscarAccountViewController.h"
#import "AIStatusController.h"

#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringUtilities.h>

#import <Adium/AIAccountViewController.h>

#import "AIAdium.h"

@implementation RAFjoscarICQService

//subclass should change this
- (Class)accountClass{
	return [RAFjoscarICQAccount class];
}

//Account Creation
- (AIAccountViewController *)accountViewController{
    return [RAFjoscarAccountViewController accountViewController];
}

//subclass should change this
//- (DCJoinChatViewController *)joinChatView{
//	return(nil);
//}

- (NSCharacterSet *)allowedCharacters
{
	return [NSCharacterSet characterSetWithCharactersInString:@"0123456789-"];
}

- (NSCharacterSet *)allowedCharactersForUIDs
{
	return [NSCharacterSet characterSetWithCharactersInString:@"0123456789-"];	
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
	return [NSCharacterSet characterSetWithCharactersInString:@"-"];
}

- (NSString *)serviceCodeUniqueID{
	return(@"joscar-OSCAR-ICQ");
}
#ifdef JOSCAR_SUPERCEDE_LIBGAIM
- (NSString *)shortDescription{
	return @"ICQ";
}
- (NSString *)longDescription{
	return @"ICQ";
}
- (NSString *)serviceID{
	return @"ICQ";
}
#else
- (NSString *)shortDescription{
	return @"ICQ-joscar";
}
- (NSString *)longDescription{
	return @"ICQ-joscar";
}
- (NSString *)serviceID{
	return @"ICQ-joscar";
}
#endif

- (BOOL)caseSensitive{
	return NO;
}

- (NSString *)userNameLabel{
    return AILocalizedString(@"ICQ Number",nil); //ScreenName
}

- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}


- (NSImage *)defaultServiceIcon{
	static NSImage	*defaultServiceIcon = nil;
	if (!defaultServiceIcon) defaultServiceIcon = [[NSImage imageNamed:@"joscar" forClass:[self class]] retain];
	return defaultServiceIcon;
}

- (void)registerStatuses{
	[super registerStatuses];
	
	[[adium statusController] registerStatus:STATUS_NAME_FREE_FOR_CHAT
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_FREE_FOR_CHAT]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_DND
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_DND]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_NOT_AVAILABLE
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AVAILABLE]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_OCCUPIED
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_OCCUPIED]
									  ofType:AIAwayStatusType
								  forService:self];
}

@end
