/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIStatusController.h"
#import "DCGaimJabberJoinChatViewController.h"
#import "ESGaimJabberAccount.h"
#import "ESGaimJabberAccountViewController.h"
#import "ESJabberService.h"

@implementation ESJabberService

//Account Creation
- (Class)accountClass{
	return([ESGaimJabberAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimJabberAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimJabberJoinChatViewController joinChatView]);
}

- (BOOL)canCreateGroupChats{
	return YES;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Jabber");
}
- (NSString *)serviceID{
	return(@"Jabber");
}
- (NSString *)serviceClass{
	return(@"Jabber");
}
- (NSString *)shortDescription{
	return(@"Jabber");
}
- (NSString *)longDescription{
	return(@"Jabber");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-()|"]);
}
- (NSCharacterSet *)allowedCharactersForUIDs{ 
	/* Allow % for use in transport names, username%hotmail.com@msn.blah.jabber.org */
	/* Allow / for specifying a resource */
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-()%/|"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(129);
}

//Generally, Jabber is NOT case sensitive, but handles in group chats are case sensitive, so return YES
//and do custom handling as needed in the account code
- (BOOL)caseSensitive{
	return(YES);
}
- (AIServiceImportance)serviceImportance{
	return(AIServicePrimary);
}
- (BOOL)canRegisterNewAccounts{
	return(YES);
}
- (NSString *)userNameLabel{
    return(AILocalizedString(@"Jabber ID",nil)); //Jabber ID
}

- (void)registerStatuses{
	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:STATUS_DESCRIPTION_AVAILABLE
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_AWAY
							 withDescription:STATUS_DESCRIPTION_AWAY
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_FREE_FOR_CHAT
							 withDescription:STATUS_DESCRIPTION_FREE_FOR_CHAT
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_DND
							 withDescription:STATUS_DESCRIPTION_DND
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_EXTENDED_AWAY
							 withDescription:STATUS_DESCRIPTION_EXTENDED_AWAY
									  ofType:AIAwayStatusType
								  forService:self];
}

@end
