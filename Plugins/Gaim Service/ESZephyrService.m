//
//  ESZephyrService.m
//  Adium
//
//  Created by Evan Schoenberg on 8/12/04.
//

#import "ESZephyrService.h"
#import "ESGaimZephyrAccount.h"
#import "ESGaimZephyrAccountViewController.h"
#import "DCGaimZephyrJoinChatViewController.h"

@implementation ESZephyrService

//Account Creation
- (Class)accountClass{
	return([ESGaimZephyrAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimZephyrAccountViewController accountView]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimZephyrJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-zephyr");
}
- (NSString *)serviceID{
	return(@"Zephyr");
}
- (NSString *)serviceClass{
	return(@"Zephyr");
}
- (NSString *)shortDescription{
	return(@"Zephyr");
}
- (NSString *)longDescription{
	return(@"Zephyr");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(255);
}
- (BOOL)caseSensitive{
	return(NO);
}

@end
