//
//  ESJabberService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESJabberService.h"
#import "ESGaimJabberAccount.h"
#import "ESGaimJabberAccountViewController.h"
#import "DCGaimJabberJoinChatViewController.h"

@implementation ESJabberService

//Account Creation
- (Class)accountClass{
	return([ESGaimJabberAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimJabberAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimJabberJoinChatViewController joinChatView]);
}

- (BOOL)canCreateGroupChats{
	return YES;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Jabber");
}
- (NSString *)serviceID{
	return(@"Jabber");
}
- (NSString *)serviceClass{
	return(@"Jabber");
}
- (NSString *)shortDescription{
	return(@"Jabber");
}
- (NSString *)longDescription{
	return(@"Jabber");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-()|"]);
}
- (NSCharacterSet *)allowedCharactersForUIDs{ 
	/* Allow % for use in transport names, username%hotmail.com@msn.blah.jabber.org */
	/* Allow / for specifying a resource */
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-()%/|"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(129);
}

//Generally, Jabber is NOT case sensitive, but handles in group chats are case sensitive, so return YES
//and do custom handling as needed in the account code
- (BOOL)caseSensitive{
	return(YES);
}
- (AIServiceImportance)serviceImportance{
	return(AIServicePrimary);
}
- (BOOL)canRegisterNewAccounts{
	return(YES);
}
- (NSString *)userNameLabel{
    return(AILocalizedString(@"Jabber ID",nil)); //Jabber ID
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
	
	[[adium statusController] registerStatus:STATUS_NAME_FREE_FOR_CHAT
							 withDescription:STATUS_DESCRIPTION_FREE_FOR_CHAT
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_DND
							 withDescription:STATUS_DESCRIPTION_DND
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_EXTENDED_AWAY
							 withDescription:STATUS_DESCRIPTION_EXTENDED_AWAY
									  ofType:AIAwayStatusType
								  forService:self];
}

@end
