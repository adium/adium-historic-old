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

#import "CBGaimAccount.h"

#define KEY_JABBER_CONNECT_SERVER		@"Jabber:Connect Server"
#define KEY_JABBER_PRIORITY_AVAILABLE	@"Jabber:Priority when Available"
#define KEY_JABBER_PRIORITY_AWAY		@"Jabber:Priority when Away"
#define KEY_JABBER_RESOURCE				@"Jabber:Resource"
#define KEY_JABBER_USE_TLS				@"Jabber:Use TLS"
#define KEY_JABBER_FORCE_OLD_SSL		@"Jabber:Force Old SSL"
#define KEY_JABBER_ALLOW_PLAINTEXT		@"Jabber:Allow Plaintext Authentication"

@interface ESGaimJabberAccount : CBGaimAccount <AIAccount_Files> {

}

- (NSString *)serverSuffix;

@end
