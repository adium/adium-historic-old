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

#import "ESGaimAntepoAccount.h"

@implementation ESGaimAntepoAccount

- (void)configureGaimAccount
{
	[super configureGaimAccount];

	gaim_account_set_bool(account, "auth_plain_in_clear", TRUE);
}

- (void)createNewGaimAccount
{
	[super createNewGaimAccount];

	//Antepo uses a full email address; need to enable our special case within libgaim for not
	//parsing the @blah.com into a desired host name
	gaim_account_set_bool(account, "use_full_username", TRUE);
}

/*!
* @brief Connect Host
 *
 * Convenience method for retrieving the connect host for this account
 *
 * Overridden here to return Antepo the default behavior, since normal Jabber overrides this method.
 */
- (NSString *)host
{
	return([self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS]);
}

@end
