//
//  ESICQService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//

#import "ESICQService.h"
#import "ESGaimICQAccount.h"
#import "ESGaimICQAccountViewController.h"

@implementation ESICQService

//Account Creation
- (Class)accountClass{
	return([ESGaimICQAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimICQAccountViewController accountViewController]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-oscar-ICQ");
}
- (NSString *)serviceID{
	return(@"ICQ");
}
- (NSString *)shortDescription{
	return(@"ICQ");
}
- (NSString *)longDescription{
	return(@"ICQ");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"0123456789"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(16);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}
- (NSString *)userNameLabel{
    return(AILocalizedString(@"ICQ Number",nil));    //ICQ#
}

- (void)registerStatuses{
	[super registerStatuses];

	[[adium statusController] registerStatus:STATUS_NAME_FREE_FOR_CHAT
							 withDescription:STATUS_DESCRIPTION_FREE_FOR_CHAT
									  ofType:AIAvailableStatusType
								  forService:self];

	[[adium statusController] registerStatus:STATUS_NAME_DND
							 withDescription:STATUS_DESCRIPTION_DND
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_NOT_AVAILABLE
							 withDescription:STATUS_DESCRIPTION_NOT_AVAILABLE
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_OCCUPIED
							 withDescription:STATUS_DESCRIPTION_OCCUPIED
									  ofType:AIAwayStatusType
								  forService:self];
}
		
@end
