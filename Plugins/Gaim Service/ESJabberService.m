//
//  ESJabberService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
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

- (AIAccountViewController *)accountView{
    return([ESGaimJabberAccountViewController accountView]);
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
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-()"]);
}
- (NSCharacterSet *)allowedCharactersForUIDs{ 
	/* Allow % for use in transport names, username%hotmail.com@msn.blah.jabber.org */
	/* Allow / for specifying a resource */
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-()%/"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(129);
}
- (BOOL)caseSensitive{
	return(NO);
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

@end
