//
//  ESAntepoService.m
//  Adium
//
//  Created by Evan Schoenberg on 11/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESAntepoService.h"
#import "ESGaimAntepoAccount.h"

@implementation ESAntepoService

//Account Creation
- (Class)accountClass{
	return([ESGaimAntepoAccount class]);
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


@end
