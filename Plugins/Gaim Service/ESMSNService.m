//
//  ESMSNService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

//#import "CBGaimServicePlugin.h"

#import "ESMSNService.h"
#import "ESGaimMSNAccount.h"
#import "ESGaimMSNAccountViewController.h"
#import "DCGaimMSNJoinChatViewController.h"
#import "AIMSNServicePreferences.h"

@implementation ESMSNService

//Service specific preferences
- (id)init
{
	[super init];
	
	MSNServicePrefs = [[AIMSNServicePreferences preferencePane] retain];

	return(self);
}

//Account Creation
- (Class)accountClass{
	return([ESGaimMSNAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimMSNAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimMSNJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-MSN");
}
- (NSString *)serviceID{
	return(@"MSN");
}
- (NSString *)serviceClass{
	return(@"MSN");
}
- (NSString *)shortDescription{
	return(@"MSN");
}
- (NSString *)longDescription{
	return(@"MSN Messenger");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._-"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(113);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServicePrimary);
}
- (NSString *)userNameLabel{
    return(AILocalizedString(@"MSN Passport",""));    //Sign-in name
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
	
	[[adium statusController] registerStatus:STATUS_NAME_BRB
							 withDescription:STATUS_DESCRIPTION_BRB
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_BUSY
							 withDescription:STATUS_DESCRIPTION_BUSY
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_PHONE
							 withDescription:STATUS_DESCRIPTION_PHONE
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_LUNCH
							 withDescription:STATUS_DESCRIPTION_LUNCH
									  ofType:AIAwayStatusType
								  forService:self];
	/*
	m = g_list_append(m, _("Available"));
	m = g_list_append(m, _("Away From Computer"));
	m = g_list_append(m, _("Be Right Back"));
	m = g_list_append(m, _("Busy"));
	m = g_list_append(m, _("On The Phone"));
	m = g_list_append(m, _("Out To Lunch"));
	m = g_list_append(m, _("Hidden"));
	 */
}

@end
