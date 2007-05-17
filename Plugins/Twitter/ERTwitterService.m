//
//  ERTwitterService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//  Copyright (c) 2004-2007 The Adium Team. All rights reserved.
//

#import <Adium/AIStatusControllerProtocol.h>
#import "ERTwitterAccount.h"
#import "ERTwitterService.h"
#import "ERTwitterAccountViewController.h"
#import <Adium/DCJoinChatViewController.h>

@implementation ERTwitterService

//Account Creation
- (Class)accountClass{
	return [ERTwitterAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ERTwitterAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"twitter";
}
- (NSString *)serviceID{
	return @"Twitter";
}
- (NSString *)serviceClass{
	return @"Twitter";
}
- (NSString *)shortDescription{
	return @"Twitter";
}
- (NSString *)longDescription{
	return @"Twitter";
}
- (NSCharacterSet *)allowedCharacters{
	return [[NSCharacterSet illegalCharacterSet] invertedSet];
}
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@""];
}
- (int)allowedLength{
	return 999;
}
- (BOOL)caseSensitive{
	return YES;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (BOOL)supportsProxySettings{
	return NO;
}
- (BOOL)requiresPassword
{
	return YES;
}
- (void)registerStatuses{
	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_AWAY
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
}
- (NSString *)defaultUserName { 
	return NSFullUserName(); 
}
@end
