//
//  AWRendezvousService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AWRendezvousService.h"
#import "AWRendezvousAccount.h"

@implementation AWRendezvousService

//Account Creation
- (Class)accountClass{
	return([AWRendezvousAccount class]);
}

- (AIAccountViewController *)accountView{
    return(nil);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"rvous-libezv");
}
- (NSString *)serviceID{
	return(@"Rendezvous");
}
- (NSString *)serviceClass{
	return(@"Rendezvous");
}
- (NSString *)shortDescription{
	return(@"Rendezvous");
}
- (NSString *)longDescription{
	return(@"Rendezvous");
}
- (NSCharacterSet *)allowedCharacters{
	return([[NSCharacterSet illegalCharacterSet] invertedSet]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(999);
}
- (BOOL)caseSensitive{
	return(NO);
}

@end
