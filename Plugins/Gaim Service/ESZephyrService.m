//
//  ESZephyrService.m
//  Adium
//
//  Created by Evan Schoenberg on 8/12/04.
//

#import "ESZephyrService.h"
#import "ESGaimZephyrAccount.h"
#import "ESGaimZephyrAccountViewController.h"
#import "DCGaimZephyrJoinChatViewController.h"

@implementation ESZephyrService

//Account Creation
- (Class)accountClass{
	return([ESGaimZephyrAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimZephyrAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimZephyrJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-zephyr");
}
- (NSString *)serviceID{
	return(@"Zephyr");
}
- (NSString *)serviceClass{
	return(@"Zephyr");
}
- (NSString *)shortDescription{
	return(@"Zephyr");
}
- (NSString *)longDescription{
	return(@"Zephyr");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-"]);
}
- (NSCharacterSet *)allowedCharactersForUIDs{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._@-"]);	
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(255);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceUnsupported);
}
- (BOOL)canCreateGroupChats{
	return(YES);
}

#warning Zephyr invisible = "Hidden"
- (void)registerStatuses{
	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:STATUS_DESCRIPTION_AVAILABLE
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_AWAY
							 withDescription:STATUS_DESCRIPTION_AWAY
									  ofType:AIAwayStatusType
								  forService:self];
	/*
		 m = g_list_append(m, _("Online"));
		 m = g_list_append(m, GAIM_AWAY_CUSTOM);
		 m = g_list_append(m, _("Hidden"));
	 */
}
@end
