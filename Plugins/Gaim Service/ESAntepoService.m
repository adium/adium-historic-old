//
//  ESAntepoService.m
//  Adium
//
//  Created by Evan Schoenberg on 11/21/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "ESAntepoService.h"
#import "ESGaimAntepoAccount.h"
#import "ESGaimAntepoAccountViewController.h"

@implementation ESAntepoService

//Account Creation
- (Class)accountClass{
	return([ESGaimAntepoAccount class]);
}
- (AIAccountViewController *)accountViewController{
    return([ESGaimAntepoAccountViewController accountViewController]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Antepo");
}
- (NSString *)serviceID{
	return(@"Antepo");
}
- (NSString *)serviceClass{
	return(@"Antepo");
}
- (NSString *)shortDescription{
	return(@"Antepo");
}
- (NSString *)longDescription{
	return(@"Antepo OPN");
}

- (AIServiceImportance)serviceImportance{
	return(AIServiceUnsupported);
}
- (BOOL)canRegisterNewAccounts{
	return(NO);
}

- (NSString *)userNameLabel{
    return(AILocalizedString(@"Username",nil)); //Antepo Username
}

@end
