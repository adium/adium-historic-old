//
//  ESMSNService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

//#import "CBGaimServicePlugin.h"

#import "ESMSNService.h"
#import "ESGaimMSNAccount.h"
#import "ESGaimMSNAccountViewController.h"
#import "DCGaimMSNJoinChatViewController.h"
#import "AIMSNServicePreferences.h"

@implementation ESMSNService

//Service specific preferences
- (id)init
{
	[super init];
	
	MSNServicePrefs = [[AIMSNServicePreferences preferencePane] retain];

	return(self);
}

//Account Creation
- (Class)accountClass{
	return([ESGaimMSNAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimMSNAccountViewController accountViewController]);
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
	return(@"MSN Messenger");
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
- (NSString *)userNameLabel{
    return(AILocalizedString(@"MSN Passport",""));    //Sign-in name
}
@end
