/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/*!
	@class AIKeychain
	@abstract Cocoa wrapper for accessing the system keychain
	@discussion Cocoa wrapper which offers class methods for accessing the system keychain
*/
@interface AIKeychain : NSObject {

}

/*!
@method getPasswordFromKeychainForService:account:
	@abstract Retrieve a password from the keychain for a specified service/account combination
	@discussion Retreives a generic password from the default keychain for a specified service/account combination, requesting authorization to access the keychain if necessary.
	@param service An <tt>NSString</tt> identifying the service for this password
	@param account An <tt>NSString</tt> identifying the account for this password
	@result The requested password as an <tt>NSString</tt>, or nil if no password was found or the user denied keychain access
*/
+ (NSString *)getPasswordFromKeychainForService:(NSString *)service account:(NSString *)account;

/*!
	@method putPasswordInKeychainForService:account:password:
	@abstract Store a password for a specified service/account combination
	@discussion Stores a generic password in the default keychain for a specified service/account combination, requesting authorization to access the keychain if necessary.
	@param service An <tt>NSString</tt> identifying the service for this password
	@param account An <tt>NSString</tt> identifying the account for this password
	@prama password A <tt>NSString</tt> of the password to store.
	@result YES if storage was successful; NO if not.
*/
+ (BOOL)putPasswordInKeychainForService:(NSString *)service account:(NSString *)account password:(NSString *)password;

/*!
	@method removePasswordFromKeychainForService:account:
	@abstract Remove a password from the keychain for a specified service/account combination
	@discussion Remove a generic password from the default keychain for a specified service/account combination, requesting authorization to access the keychain if necessary.
	@param service An <tt>NSString</tt> identifying the service for this password
	@param account An <tt>NSString</tt> identifying the account for this password
	@result YES if removal was successful; NO if the service/account combination was not found or removal was unsuccessful.
*/
+ (BOOL)removePasswordFromKeychainForService:(NSString *)service account:(NSString *)account;

/*!
	@method getDictionaryFromKeychainForKey:
	@abstract Remove a password from the keychain for a specified service/account combination
	@discussion Remove a generic password from the default keychain for a specified service/account combination, requesting authorization to access the keychain if necessary.
	@param service An <tt>NSString</tt> identifying the service for this password
	@param account An <tt>NSString</tt> identifying the account for this password
	@result YES if removal was successful; NO if the service/account combination was not found or removal was unsuccessful.
*/
+ (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key;

@end
