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

#import "AIGaimGTalkAccount.h"

@implementation AIGaimGTalkAccount

- (void)createNewGaimAccount
{
	[super createNewGaimAccount];
	
	NSString	 *userNameWithGmailDotCom = nil;

	if (([UID rangeOfString:@"@gmail.com"
					options:(NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch)].location != NSNotFound)) {
		userNameWithGmailDotCom = UID;
	} else {
		userNameWithGmailDotCom = [UID stringByAppendingString:@"@gmail.com"];
	}

	gaim_account_set_username(account, [userNameWithGmailDotCom UTF8String]);
}

- (NSString *) serverSuffix
{
	AILog(@"using gmail");
	return @"@gmail.com";
}

@end
