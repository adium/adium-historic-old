//
//  ESGaduGaduService.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaduGaduService.h"
#import "ESGaimGaduGaduAccount.h"
#import "ESGaimGaduGaduAccountViewController.h"
#import "DCGaimGaduGaduJoinChatViewController.h"

@implementation ESGaduGaduService

//Account Creation
- (Class)accountClass{
	return([ESGaimGaduGaduAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimGaduGaduAccountViewController accountView]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimGaduGaduJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Gadu-Gadu");
}
- (NSString *)serviceID{
	return(@"Gadu-Gadu");
}
- (NSString *)serviceClass{
	return(@"Gadu-Gadu");
}
- (NSString *)shortDescription{
	return(@"Gadu-Gadu");
}
- (NSString *)longDescription{
	return(@"Gadu-Gadu");
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

@end
