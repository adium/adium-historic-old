//
//  ESDotMacService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//

#import "ESDotMacService.h"
#import "ESGaimDotMacAccountViewController.h"
#import "ESGaimDotMacAccount.h"

@implementation ESDotMacService

//Account Creation
- (Class)accountClass{
	return([ESGaimDotMacAccount class]);
}

//
- (AIAccountViewController *)accountViewController{
    return([ESGaimDotMacAccountViewController accountViewController]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-oscar-Mac");
}
- (NSString *)serviceID{
	return(@"Mac");
}
- (NSString *)shortDescription{
	return(@".Mac");
}
- (NSString *)longDescription{
	return(@".Mac");
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@" "]);
}
- (int)allowedLength{
	return(28);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}
- (NSString *)userNameLabel{
    return(AILocalizedString(@".Mac Name",nil)); //.Mac Member Name
}
@end
