//
//  ESMeanwhileService.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESMeanwhileService.h"
#import "ESGaimMeanwhileAccount.h"
#import "ESGaimMeanwhileAccountViewController.h"
#import "DCGaimMeanwhileJoinChatViewController.h"

@implementation ESMeanwhileService

//Account Creation
- (Class)accountClass{
	return([ESGaimMeanwhileAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimMeanwhileAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimMeanwhileJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Sametime");
}
- (NSString *)serviceID{
	return(@"Sametime");
}
- (NSString *)serviceClass{
	return(@"Sametime");
}
- (NSString *)shortDescription{
	return(@"Sametime");
}
- (NSString *)longDescription{
	return(@"Lotus Sametime");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@.,_-()='/ "]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(1000);
}
- (BOOL)caseSensitive{
	return(YES);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}
- (BOOL)canCreateGroupChats{
	return(YES);
}

@end
