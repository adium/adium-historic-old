//
//  ESGaduGaduService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESGaduGaduService.h"
#import "ESGaimGaduGaduAccount.h"
#import "ESGaimGaduGaduAccountViewController.h"
#import "DCGaimGaduGaduJoinChatViewController.h"

@implementation ESGaduGaduService

//Account Creation
- (Class)accountClass{
	return([ESGaimGaduGaduAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimGaduGaduAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimGaduGaduJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Gadu-Gadu");
}
- (NSString *)serviceID{
	return(@"Gadu-Gadu");
}
- (NSString *)serviceClass{
	return(@"Gadu-Gadu");
}
- (NSString *)shortDescription{
	return(@"Gadu-Gadu");
}
- (NSString *)longDescription{
	return(@"Gadu-Gadu");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._ "]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(24);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}

- (void)registerStatuses{
	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:STATUS_DESCRIPTION_AVAILABLE
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_AWAY
							 withDescription:STATUS_DESCRIPTION_AWAY
									  ofType:AIAwayStatusType
								  forService:self];
	
	/*
#define AGG_STATUS_AVAIL              _("Available")
#define AGG_STATUS_AVAIL_FRIENDS      _("Available for friends only")
#define AGG_STATUS_BUSY               _("Away")
#define AGG_STATUS_BUSY_FRIENDS       _("Away for friends only")
#define AGG_STATUS_INVISIBLE          _("Invisible")
#define AGG_STATUS_INVISIBLE_FRIENDS  _("Invisible for friends only")
#define AGG_STATUS_NOT_AVAIL          _("Unavailable")
	*/

	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE_FRIENDS_ONLY
							 withDescription:STATUS_DESCRIPTION_AVAILABLE_FRIENDS_ONLY
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_AWAY_FRIENDS_ONLY
							 withDescription:STATUS_DESCRIPTION_AWAY_FRIENDS_ONLY
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_NOT_AVAILABLE
							 withDescription:STATUS_DESCRIPTION_NOT_AVAILABLE
									  ofType:AIAwayStatusType
								  forService:self];
}

@end
