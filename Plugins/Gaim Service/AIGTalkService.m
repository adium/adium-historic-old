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

#import "AIGTalkService.h"
#import "AIGaimGTalkAccount.h"
#import "AIGaimGTalkAccountViewController.h"

@implementation AIGTalkService

//Account Creation
- (Class)accountClass{
	return [AIGaimGTalkAccount class];
}

//
- (AIAccountViewController *)accountViewController{
    return [AIGaimGTalkAccountViewController accountViewController];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libgaim-jabber-gtalk";
}
- (NSString *)serviceID{
	return @"GTalk";
}
//When GTalk has interserver communication, remove this so GTalk and Jabber share a serviceClass.
- (NSString *)serviceClass{
	return @"GTalk";
}
- (NSString *)shortDescription{
	return @"GTalk";
}
- (NSString *)longDescription{
	return @"Google Talk";
}
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@" "];
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@gmail.com","Sample name and server for new gmail accounts");
}
- (NSString *)userNameLabel{
    return AILocalizedString(@"GTalk ID",nil); //Jabber ID
}

@end
