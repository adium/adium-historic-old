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

#import "ESTrepiaService.h"
#import "ESGaimTrepiaAccount.h"
#import "ESGaimTrepiaAccountViewController.h"
#import "DCGaimTrepiaJoinChatViewController.h"

@implementation ESTrepiaService

//Account Creation
- (Class)accountClass{
	return([ESGaimTrepiaAccount class]);
}

- (AIAccountViewController *)accountViewController{
    return([ESGaimTrepiaAccountViewController accountViewController]);
}

- (DCJoinChatViewController *)joinChatView{
	return([DCGaimTrepiaJoinChatViewController joinChatView]);
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return(@"libgaim-Trepia");
}
- (NSString *)serviceID{
	return(@"Trepia");
}
- (NSString *)serviceClass{
	return(@"Trepia");
}
- (NSString *)shortDescription{
	return(@"Trepia");
}
- (NSString *)longDescription{
	return(@"Trepia");
}
- (NSCharacterSet *)allowedCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._"]);
}
- (NSCharacterSet *)ignoredCharacters{
	return([NSCharacterSet characterSetWithCharactersInString:@""]);
}
- (int)allowedLength{
	return(24);
}
- (BOOL)caseSensitive{
	return(NO);
}
- (AIServiceImportance)serviceImportance{
	return(AIServiceSecondary);
}

@end