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
	return(@"Yahoo!");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(30);
}
- (BOOL)caseSensitive{
	return(NO);
}

@end
