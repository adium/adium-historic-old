//
//  ESSimpleService.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//

#import "ESSimpleService.h"
#import "ESGaimSimpleAccount.h"
#import "ESGaimSimpleAccountViewController.h"
#import "AIStatusController.h"

@implementation ESSimpleService
//Account Creation
- (Class)accountClass{
	return [ESGaimSimpleAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESGaimSimpleAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return nil;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libgaim-simple";
}
- (NSString *)serviceID{
	return @"SIMPLE";
}
- (NSString *)serviceClass{
	return @"SIMPLE";
}
- (NSString *)shortDescription{
	return @"SIMPLE";
}
- (NSString *)longDescription{
	return @"SIP / SIMPLE";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._-"];
}
- (NSCharacterSet *)allowedCharactersForUIDs{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._-"];	
}
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@""];
}
- (int)allowedLength{
	return 255;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (BOOL)canCreateGroupChats{
	return NO;
}

- (void)registerStatuses{
	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];
}

@end
