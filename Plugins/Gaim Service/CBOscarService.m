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

#import "AIGaimOscarAccountViewController.h"
#import "AIStatusController.h"
#import "CBGaimOscarAccount.h"
#import "CBOscarService.h"
#import "DCGaimOscarJoinChatViewController.h"

@implementation CBOscarService

//Account Creation
- (Class)accountClass{
	return([CBGaimOscarAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([AIGaimOscarAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimOscarJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-oscar");
}
- (NSString *)serviceID{
	return(@"");
}
- (NSString *)serviceClass{
	return(@"AIM-compatible");
}
- (NSString *)shortDescription{
	return(@"");
}
- (NSString *)longDescription{
	return(@"");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "]);
}
- (NSCharacterSet *)allowedCharactersForUIDs{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "]);	
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@" "]);
}
- (int)allowedLength{
	return(999);
}
- (int)allowedLengthForUIDs{
	return(999);
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
- (NSString *)userNameLabel{
    return(AILocalizedString(@"Screen Name",nil)); //ScreenName
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
}

@end
