//
//  ESYahooService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESYahooService.h"
#import "ESGaimYahooAccount.h"
#import "ESGaimYahooAccountViewController.h"
#import "DCGaimYahooJoinChatViewController.h"

@implementation ESYahooService

//Account Creation
- (Class)accountClass{
	return([ESGaimYahooAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimYahooAccountViewController accountView]);
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
    return(@"Yahoo ID");    //Yahoo! ID
}
@end
