//
//  AIStressTestService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIStressTestService.h"
#import "AIStressTestAccount.h"
#import "DCStressTestJoinChatViewController.h"

@implementation AIStressTestService

//Account Creation
- (Class)accountClass{
	return([AIStressTestAccount class]);
}

- (AIAccountViewController *)accountView{
    return(nil);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCStressTestJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"Stress-Test");
}
- (NSString *)serviceID{
	return(@"Stress Test");
}
- (NSString *)serviceClass{
	return(@"Stress Test");
}
- (NSString *)shortDescription{
	return(@"Stress Test");
}
- (NSString *)longDescription{
	return(@"Stress Test (Das ist verboten)");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(20);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceUnsupported);
}

@end
