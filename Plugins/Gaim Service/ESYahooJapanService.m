//
//  ESYahooJapanService.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Apr 22 2004.
//

#import "ESYahooJapanService.h"
#import "ESGaimYahooJapanAccount.h"
#import "ESGaimYahooAccountViewController.h"
#import "DCGaimYahooJoinChatViewController.h"

@implementation ESYahooJapanService

//Account Creation
- (Class)accountClass{
	return([ESGaimYahooJapanAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimYahooAccountViewController accountView]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimYahooJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Yahoo!-Japan");
}
- (NSString *)serviceID{
	return(@"Yahoo! Japan");
}
- (NSString *)serviceClass{
	return(@"Yahoo! Japan");
}
- (NSString *)shortDescription{
	return(@"Yahoo! Japan");
}
- (NSString *)longDescription{
	return(@"Yahoo! Japan");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-"]);
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

@end
