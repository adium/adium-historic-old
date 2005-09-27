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

#import "ESDotMacService.h"
#import "ESGaimDotMacAccount.h"
#import "ESGaimDotMacAccountViewController.h"

@implementation ESDotMacService

//Account Creation
- (Class)accountClass{
	return [ESGaimDotMacAccount class];
}

//
- (AIAccountViewController *)accountViewController{
    return [ESGaimDotMacAccountViewController accountViewController];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libgaim-oscar-Mac";
}
- (NSString *)serviceID{
	return @"Mac";
}
- (NSString *)shortDescription{
	return @".Mac";
}
- (NSString *)longDescription{
	return @".Mac";
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
- (NSString *)userNameLabel{
    return AILocalizedString(@"Member Name",nil); //.Mac Member Name
}

/*!
 * @brief Filter a UID
 *
 * Add @mac.com to the end of a dotMac contact if it's not already present.  super's implementation will make the UID
 * lowercase, since [self caseSensitive] returns NO, so we can use -[NSString hasSuffix:] to check for the string.
 */
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored
{
	NSString	*filteredUID = [super filterUID:inUID removeIgnoredCharacters:removeIgnored];
	
	if (![filteredUID hasSuffix:@"@mac.com"]) {
		filteredUID = [filteredUID stringByAppendingString:@"@mac.com"];
	}
	
	return filteredUID;
}

@end
