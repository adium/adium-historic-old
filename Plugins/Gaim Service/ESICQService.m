//
//  ESICQService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//

#import "ESICQService.h"
#import "ESGaimICQAccount.h"
#import "ESGaimICQAccountViewController.h"

@implementation ESICQService

//Account Creation
- (Class)accountClass{
	return([ESGaimICQAccount class]);
}

- (AIAccountViewController *)accountView{
    return([ESGaimICQAccountViewController accountView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-oscar-ICQ");
}
- (NSString *)serviceID{
	return(@"ICQ");
}
- (NSString *)shortDescription{
	return(@"ICQ");
}
- (NSString *)longDescription{
	return(@"ICQ");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"0123456789"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(16);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}

@end
