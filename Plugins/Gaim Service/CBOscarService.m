//
//  CBOscarService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "CBGaimOscarAccount.h"
#import "CBOscarService.h"
#import "AIGaimOscarAccountViewController.h"
#import "DCGaimOscarJoinChatViewController.h"

@implementation CBOscarService

//Account Creation
- (Class)accountClass{
	return([CBGaimOscarAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([AIGaimOscarAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimOscarJoinChatViewController joinChatView]);
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
- (NSCharacterSet *)allowedCharactersForUIDs{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "]);	
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@" "]);
}
- (int)allowedLength{
	return(28);
}
- (int)allowedLengthForUIDs{
	return(28);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceUnsupported);
}
- (BOOL)canCreateGroupChats{
	return(YES);
}
- (NSString *)userNameLabel{
    return(AILocalizedString(@"Screen Name",nil)); //ScreenName
}

@end
