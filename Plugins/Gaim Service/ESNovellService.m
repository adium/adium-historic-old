//
//  ESNovellService.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESNovellService.h"
#import "ESGaimNovellAccount.h"
#import "ESGaimNovellAccountViewController.h"
#import "DCGaimNovellJoinChatViewController.h"

@implementation ESNovellService

//Account Creation
- (Class)accountClass{
	return([ESGaimNovellAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimNovellAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimNovellJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-GroupWise");
}
- (NSString *)serviceID{
	return(@"GroupWise");
}
- (NSString *)serviceClass{
	return(@"GroupWise");
}
- (NSString *)shortDescription{
	return(@"GroupWise");
}
- (NSString *)longDescription{
	return(@"Novell GroupWise");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@-._ "]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(40);
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
	
	[[adium statusController] registerStatus:STATUS_NAME_BUSY
							 withDescription:STATUS_DESCRIPTION_BUSY
									  ofType:AIAwayStatusType
								  forService:self];
	
/*
 m = g_list_append(m, _("Available"));
	m = g_list_append(m, _("Away"));
	m = g_list_append(m, _("Busy"));
	m = g_list_append(m, _("Appear Offline"));
	m = g_list_append(m, GAIM_AWAY_CUSTOM);
*/ 
}
@end
