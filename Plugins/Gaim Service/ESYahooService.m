//
//  ESYahooService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESYahooService.h"
#import "ESGaimYahooAccount.h"
#import "ESGaimYahooAccountViewController.h"
#import "DCGaimYahooJoinChatViewController.h"

@implementation ESYahooService

//Account Creation
- (Class)accountClass{
	return([ESGaimYahooAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimYahooAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimYahooJoinChatViewController joinChatView]);
}

- (BOOL)canCreateGroupChats{
	return YES;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Yahoo!");
}
- (NSString *)serviceID{
	return(@"Yahoo!");
}
- (NSString *)serviceClass{
	return(@"Yahoo!");
}
- (NSString *)shortDescription{
	return(@"Yahoo!");
}
- (NSString *)longDescription{
	return(@"Yahoo! Messenger");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789_@.-"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(32);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServicePrimary);
}
- (NSString *)userNameLabel{
    return(AILocalizedString(@"Yahoo! ID",nil));    //Yahoo! ID
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

	[[adium statusController] registerStatus:STATUS_NAME_NOT_AT_HOME
							 withDescription:STATUS_DESCRIPTION_NOT_AT_HOME
									  ofType:AIAwayStatusType
								  forService:self];

	[[adium statusController] registerStatus:STATUS_NAME_NOT_AT_DESK
							 withDescription:STATUS_DESCRIPTION_NOT_AT_DESK
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_NOT_IN_OFFICE
							 withDescription:STATUS_DESCRIPTION_NOT_IN_OFFICE
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_PHONE
							 withDescription:STATUS_DESCRIPTION_PHONE
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_VACATION
							 withDescription:STATUS_DESCRIPTION_VACATION
									  ofType:AIAwayStatusType
								  forService:self];

	[[adium statusController] registerStatus:STATUS_NAME_LUNCH
							 withDescription:STATUS_DESCRIPTION_LUNCH
									  ofType:AIAwayStatusType
								  forService:self];

	[[adium statusController] registerStatus:STATUS_NAME_STEPPED_OUT
							 withDescription:STATUS_DESCRIPTION_STEPPED_OUT
									  ofType:AIAwayStatusType
								  forService:self];

	/*
	m = g_list_append(m, _("Be Right Back"));
	m = g_list_append(m, _("Busy"));
	m = g_list_append(m, _("Not At Home"));
	m = g_list_append(m, _("Not At Desk"));
	m = g_list_append(m, _("Not In Office"));
	m = g_list_append(m, _("On The Phone"));
	m = g_list_append(m, _("On Vacation"));
	m = g_list_append(m, _("Out To Lunch"));
	m = g_list_append(m, _("Stepped Out"));
	 */
}

@end
