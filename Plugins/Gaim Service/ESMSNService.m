//
//  ESMSNService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//
//#import "CBGaimServicePlugin.h"

#import "ESMSNService.h"
#import "ESGaimMSNAccount.h"
#import "ESGaimMSNAccountViewController.h"
#import "DCGaimMSNJoinChatViewController.h"

@implementation ESMSNService

//Account Creation
- (Class)accountClass{
	return([ESGaimMSNAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimMSNAccountViewController accountView]);
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
	return(@"MSN");
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

@end
