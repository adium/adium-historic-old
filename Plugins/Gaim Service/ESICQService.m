//
//  ESICQService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "ESICQService.h"


@implementation ESICQService

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

@end
