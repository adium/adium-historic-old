//
//  ESAIMService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "ESAIMService.h"


@implementation ESAIMService

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-oscar-AIM");
}
- (NSString *)serviceID{
	return(@"AIM");
}
- (NSString *)shortDescription{
	return(@"AIM");
}
- (NSString *)longDescription{
	return(@"AOL Instant Messenger");
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@" "]);
}
- (int)allowedLength{
	return(16);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServicePrimary);
}

@end
