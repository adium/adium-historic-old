//
//  AWRendezvousService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIStatusController.h"
#import "AWRendezvousAccount.h"
#import "AWRendezvousService.h"
#import "ESRendezvousAccountViewController.h"
#import <Adium/DCJoinChatViewController.h>

@implementation AWRendezvousService

//Account Creation
- (Class)accountClass{
	return([AWRendezvousAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESRendezvousAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"bonjour-libezv");
}
- (NSString *)serviceID{
	return(@"Bonjour");
}
- (NSString *)serviceClass{
	return(@"Bonjour");
}
- (NSString *)shortDescription{
	return(@"Bonjour");
}
- (NSString *)longDescription{
	return(@"Bonjour");
}
- (NSCharacterSet *)allowedCharacters{
	return([[NSCharacterSet illegalCharacterSet] invertedSet]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(999);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}
- (BOOL)supportsProxySettings{
	return(NO);
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
}

@end
