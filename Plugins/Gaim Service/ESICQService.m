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
#import "ESGaimICQAccount.h"
#import "ESGaimICQAccountViewController.h"
#import "ESICQService.h"

@implementation ESICQService

//Account Creation
- (Class)accountClass{
	return([ESGaimICQAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimICQAccountViewController accountViewController]);
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
- (NSString *)userNameLabel{
    return(AILocalizedString(@"ICQ Number",nil));    //ICQ#
}

- (void)registerStatuses{
	[super registerStatuses];

	[[adium statusController] registerStatus:STATUS_NAME_FREE_FOR_CHAT
							 withDescription:STATUS_DESCRIPTION_FREE_FOR_CHAT
									  ofType:AIAvailableStatusType
								  forService:self];

	[[adium statusController] registerStatus:STATUS_NAME_DND
							 withDescription:STATUS_DESCRIPTION_DND
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_NOT_AVAILABLE
							 withDescription:STATUS_DESCRIPTION_NOT_AVAILABLE
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_OCCUPIED
							 withDescription:STATUS_DESCRIPTION_OCCUPIED
									  ofType:AIAwayStatusType
								  forService:self];
}
		
@end
