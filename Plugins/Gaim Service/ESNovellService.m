//
//  ESNovellService.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESNovellService.h"
#import "ESGaimNovellAccount.h"
#import "ESGaimNovellAccountViewController.h"
#import "DCGaimNovellJoinChatViewController.h"

@implementation ESNovellService

//Account Creation
- (Class)accountClass{
	return([ESGaimNovellAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimNovellAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimNovellJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-GroupWise");
}
- (NSString *)serviceID{
	return(@"GroupWise");
}
- (NSString *)serviceClass{
	return(@"GroupWise");
}
- (NSString *)shortDescription{
	return(@"GroupWise");
}
- (NSString *)longDescription{
	return(@"Novell GroupWise");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@-._ "]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(40);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}

@end
