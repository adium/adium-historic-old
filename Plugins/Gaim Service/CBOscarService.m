//
//  CBOscarService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimOscarAccount.h"
#import "CBOscarService.h"
#import "AIGaimOscarAccountViewController.h"
#import "DCGaimOscarJoinChatViewController.h"

@implementation CBOscarService

//Account Creation
- (Class)accountClass{
	return([CBGaimOscarAccount class]);
}

- (AIAccountViewController *)accountView{
    return([AIGaimOscarAccountViewController accountView]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimOscarJoinChatViewController joinChatView]);
}

- (BOOL)canCreateGroupChats{
	return YES;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-oscar");
}
- (NSString *)serviceID{
	return(@"");
}
- (NSString *)serviceClass{
	return(@"AIM-compatible");
}
- (NSString *)shortDescription{
	return(@"");
}
- (NSString *)longDescription{
	return(@"");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@" "]);
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
