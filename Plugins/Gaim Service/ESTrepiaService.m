//
//  ESTrepiaService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Feb 22 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESTrepiaService.h"
#import "ESGaimTrepiaAccount.h"
#import "ESGaimTrepiaAccountViewController.h"
#import "DCGaimTrepiaJoinChatViewController.h"

@implementation ESTrepiaService

//Account Creation
- (Class)accountClass{
	return([ESGaimTrepiaAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimTrepiaAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimTrepiaJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Trepia");
}
- (NSString *)serviceID{
	return(@"Trepia");
}
- (NSString *)serviceClass{
	return(@"Trepia");
}
- (NSString *)shortDescription{
	return(@"Trepia");
}
- (NSString *)longDescription{
	return(@"Trepia");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._"]);
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