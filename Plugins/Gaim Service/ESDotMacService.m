//
//  ESDotMacService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//

#import "ESDotMacService.h"
#import "ESGaimDotMacAccountViewController.h"

@implementation ESDotMacService

//
- (AIAccountViewController *)accountView{
    return([ESGaimDotMacAccountViewController accountView]);
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
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "]);
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

@end
