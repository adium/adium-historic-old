//
//  ESNapsterService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESNapsterService.h"
#import "ESGaimNapsterAccount.h"
#import "ESGaimNapsterAccountViewController.h"
#import "DCGaimNapsterJoinChatViewController.h"

@implementation ESNapsterService

//Account Creation
- (Class)accountClass{
	return([ESGaimNapsterAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimNapsterAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimNapsterJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Napster");
}
- (NSString *)serviceID{
	return(@"Napster");
}
- (NSString *)serviceClass{
	return(@"Napster");
}
- (NSString *)shortDescription{
	return(@"Napster");
}
- (NSString *)longDescription{
	return(@"Napster");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._ "]);
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
	return(AIServiceUnsupported);
}

@end
