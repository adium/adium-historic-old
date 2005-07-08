/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#include <Security/Security.h>

/*NOTE: it is **STRONGLY** recommended that you use AIWiredString, rather than
 *	the Apple-supplied NSString or CFString, to supply passwords to AIKeychain.
 *AIKeychain uses AIWiredString itself for all handling of passwords.
 */
@class AIWiredString;

#pragma mark AIKeychain errors

/*all AIKeychain methods return by reference an NSError object when the
 *	Keychain Services function that backs that method returns an OSStatus
 *	other than noErr.
 *the domain of the error is AIKEYCHAIN_ERROR_DOMAIN.
 *the error code is the OSStatus returned by Keychain Services.
 *you may pass NULL for the error argument, in which case the error will be
 *	silently dropped.
 */

#define AIKEYCHAIN_ERROR_DOMAIN @"AIKeychainError"

//the function that returned the error
#define AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION @"SecurityFrameworkFunction"
#define AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME @"SecurityFrameworkFunctionName"
//description of the error (from SecErrorMessages.strings)
#define AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION @"SecurityFrameworkErrorDescription"
//the AIKeychain that was involved
#define AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN @"Keychain"
//for +allowsUserInteraction, +setAllowsUserInteraction
#define AIKEYCHAIN_ERROR_USERINFO_USERINTERACTIONALLOWEDSTATE @"UserInteractionAllowed"
//for -getSettings:, -setSettings:
#define AIKEYCHAIN_ERROR_USERINFO_SETTINGSPOINTER @"PointerToSettingsStructure"
//for -{add,find}{Internet,Generic}Password:...
#define AIKEYCHAIN_ERROR_USERINFO_SERVICE            @"GenericPasswordService"
#define AIKEYCHAIN_ERROR_USERINFO_SERVER             @"InternetPasswordServer"
#define AIKEYCHAIN_ERROR_USERINFO_DOMAIN             @"InternetPasswordSecurityDomain"
#define AIKEYCHAIN_ERROR_USERINFO_ACCOUNT            @"PasswordAccount"
#define AIKEYCHAIN_ERROR_USERINFO_PROTOCOL           @"PasswordProtocol"
#define AIKEYCHAIN_ERROR_USERINFO_AUTHENTICATIONTYPE @"PasswordAuthenticationType"

/*!
 * @class AIKeychain
 * @brief Cocoa wrapper for accessing keychains
 *
 * Cocoa wrapper which offers class methods for accessing the default keychain and others, and instance methods for accessing data from the keychains.
 */
@interface AIKeychain: NSObject {
	SecKeychainRef keychainRef;
}

//SecKeychainLockAll
+ (void)lockAllKeychains_error:(out NSError **)outError;
//SecKeychainLock (with keychain=NULL)
+ (void)lockDefaultKeychain_error:(out NSError **)outError;
//SecKeychainUnlock (with keychain=NULL)
+ (void)unlockDefaultKeychain_error:(out NSError **)outError;
+ (void)unlockDefaultKeychainWithPassword:(NSString *)password error:(out NSError **)outError;

//SecKeychainGetUserInteractionAllowed
//returns YES if an error occurs.
+ (BOOL)allowsUserInteraction_error:(out NSError **)outError;
//SecKeychainSetUserInteractionAllowed
+ (void)setAllowsUserInteraction:(BOOL)flag error:(out NSError **)outError;

//SecKeychainGetVersion
+ (u_int32_t)keychainServicesVersion_error:(out NSError **)outError;

#pragma mark -

//SecKeychainCopyDefault
+ (AIKeychain *)defaultKeychain_error:(out NSError **)outError;
//SecKeychainSetDefault
+ (void)setDefaultKeychain:(AIKeychain *)newDefaultKeychain error:(out NSError **)outError;

//SecKeychainOpen
+ (AIKeychain *)keychainWithContentsOfFile:(NSString *)path error:(out NSError **)outError;
- (id)initWithContentsOfFile:(NSString *)path error:(out NSError **)outError;

//SecKeychainCreate
+ (AIKeychain *)keychainWithPath:(NSString *)path password:(NSString *)password promptUser:(BOOL)prompt initialAccess:(SecAccessRef)initialAccess error:(out NSError **)outError;
- (id)initWithPath:(NSString *)path
		  password:(NSString *)password //can be nil if promptUser is true
		promptUser:(BOOL)prompt
	 initialAccess:(SecAccessRef)initialAccess //can be NULL
			 error:(out NSError **)outError;

+ (AIKeychain *)keychainWithKeychainRef:(SecKeychainRef)newKeychainRef;
- (id)initWithKeychainRef:(SecKeychainRef)newKeychainRef;

#pragma mark -

//SecKeychainCopySettings
- (void)getSettings:(out struct SecKeychainSettings *)outSettings error:(out NSError **)outError;
//SecKeychainSetSettings
- (void)setSettings:( in struct SecKeychainSettings *)newSettings error:(out NSError **)outError;

//SecKeychainGetStatus
- (SecKeychainStatus)status_error:(out NSError **)outError;
//SecKeychainGetPath
- (char *)getPathFileSystemRepresentation:(out char *)outBuf length:(inout u_int32_t *)outLength error:(out NSError **)outError;
- (NSString *)path;

#pragma mark -

//SecKeychainLock
- (void)lockKeychain_error:(out NSError **)outError;
//SecKeychainUnlock
- (void)unlockKeychain_error:(out NSError **)outError;
- (void)unlockKeychainWithPassword:(NSString *)password error:(out NSError **)outError;

#pragma mark -

//SecKeychainDelete
- (void)deleteKeychain_error:(out NSError **)outError;

#pragma mark -

/*working with keychain items
 *
 *like all AIKeychain methods, outError is optional (can be NULL).
 *outKeychainItem is also optional. if it is non-NULL, you must release the
 *	keychain item.
 */

//------------------------------------------------------------------------------
/*add a password.
 *
 *if the password exists, the error object's code will be errSecDuplicateItem.
 */

//SecKeychainAddInternetPassword
- (void)addInternetPassword:(NSString *)password
				  forServer:(NSString *)server
			 securityDomain:(NSString *)domain //can pass nil
					account:(NSString *)account
					   path:(NSString *)path
					   port:(u_int16_t)port //can pass 0
				   protocol:(SecProtocolType)protocol
		 authenticationType:(SecAuthenticationType)authType
			   keychainItem:(out SecKeychainItemRef *)outKeychainItem
					  error:(out NSError **)outError;

//convenience version: domain = path = nil; port = 0; authType = default; does not return keychain item
- (void)addInternetPassword:(NSString *)password
				  forServer:(NSString *)server
					account:(NSString *)account
				   protocol:(SecProtocolType)protocol
					  error:(out NSError **)outError;

//------------------------------------------------------------------------------
/*search for a password.
 *
 *if the password does not exist, the error object's code will be
 *	errSecItemNotFound.
 */

//SecKeychainFindInternetPassword
- (NSString *)findInternetPasswordForServer:(NSString *)server
							 securityDomain:(NSString *)domain //can pass nil
									account:(NSString *)account
									   path:(NSString *)path
									   port:(u_int16_t)port //can pass 0
								   protocol:(SecProtocolType)protocol
						 authenticationType:(SecAuthenticationType)authType
							   keychainItem:(out SecKeychainItemRef *)outKeychainItem
									  error:(out NSError **)outError;

//convenience version: domain = path = nil; port = 0; authType = default; does not return keychain item
- (NSString *)internetPasswordForServer:(NSString *)server
								account:(NSString *)account
							   protocol:(SecProtocolType)protocol
								  error:(out NSError **)outError;

//keys in this dictionary: @"Username" (account), @"Password".
- (NSDictionary *)dictionaryFromKeychainForServer:(NSString *)server error:(out NSError **)outError;

//------------------------------------------------------------------------------
/*set a password
 *
 *if you pass non-nil:
 *	if the password exists:
 *		it is changed.
 *	if the password does not exist:
 *		it is added.
 *if you pass nil:
 *	the password is removed.
 */

- (void)setInternetPassword:(NSString *)password
				  forServer:(NSString *)server
			 securityDomain:(NSString *)domain //can pass nil
					account:(NSString *)account
					   path:(NSString *)path
					   port:(u_int16_t)port //can pass 0
				   protocol:(SecProtocolType)protocol
		 authenticationType:(SecAuthenticationType)authType
			   keychainItem:(out SecKeychainItemRef *)outKeychainItem
					  error:(out NSError **)outError;

//convenience version: domain = path = nil; port = 0; authType = default; does not return keychain item
- (void)setInternetPassword:(NSString *)password
				  forServer:(NSString *)server
					account:(NSString *)account
				   protocol:(SecProtocolType)protocol
					  error:(out NSError **)outError;

//------------------------------------------------------------------------------
//remove a password.

- (void)deleteInternetPasswordForServer:(NSString *)server
						 securityDomain:(NSString *)domain //can pass nil
								account:(NSString *)account
								   path:(NSString *)path
								   port:(u_int16_t)port //can pass 0
							   protocol:(SecProtocolType)protocol
					 authenticationType:(SecAuthenticationType)authType
						   keychainItem:(out SecKeychainItemRef *)outKeychainItem
								  error:(out NSError **)outError;

//convenience version: domain = path = nil; port = 0; authType = default; does not return keychain item
- (void)deleteInternetPasswordForServer:(NSString *)server
								account:(NSString *)account
							   protocol:(SecProtocolType)protocol
								  error:(out NSError **)outError;

#pragma mark -

//SecKeychainAddGenericPassword
- (void)addGenericPassword:(NSString *)password
				forService:(NSString *)service
				   account:(NSString *)account
			  keychainItem:(out SecKeychainItemRef *)outKeychainItem
					 error:(out NSError **)outError;

//SecKeychainFindGenericPassword
- (NSString *)findGenericPasswordForService:(NSString *)service
									account:(NSString *)account
							   keychainItem:(out SecKeychainItemRef *)outKeychainItem
									  error:(out NSError **)outError;

#pragma mark -

//returns the Keychain Services object that backs this object.
- (SecKeychainRef)keychainRef;

#pragma mark -

/*!
 * @brief Retrieve a password from the keychain for a specified service/account combination
 *
 * Retreives a password from the default keychain for a specified service/account combination, requesting authorization to access the keychain if necessary.  Uses the Internet Password mechanisms.
 * @param service An <tt>NSString</tt> identifying the service for this password
 * @param account An <tt>NSString</tt> identifying the account for this password
 * @return The requested password as an <tt>NSString</tt>, or nil if no password was found or the user denied keychain access
*/
+ (NSString *)getPasswordFromKeychainForService:(NSString *)service account:(NSString *)account;

/*!
 * @brief Store a password for a specified service/account combination
 *
 * Stores a password in the default keychain for a specified service/account combination, requesting authorization to access the keychain if necessary. Uses the Internet Password mechanisms.
 * @param service An <tt>NSString</tt> identifying the service for this password
 * @param account An <tt>NSString</tt> identifying the account for this password
 * @param password A <tt>NSString</tt> of the password to store.
 * @return YES if storage was successful; NO if not.
 */
+ (BOOL)putPasswordInKeychainForService:(NSString *)service account:(NSString *)account password:(NSString *)password;

/*!
 * @brief Remove a password from the keychain for a specified service/account combination
 *
 * Remove a password from the default keychain for a specified service/account combination, requesting authorization to access the keychain if necessary. Uses the Internet Password mechanisms.
 * @param service An <tt>NSString</tt> identifying the service for this password
 * @param account An <tt>NSString</tt> identifying the account for this password
 * @return YES if removal was successful; NO if the service/account combination was not found or removal was unsuccessful.
 */
+ (BOOL)removePasswordFromKeychainForService:(NSString *)service account:(NSString *)account;

/*!
 * @brief Retrieve a keychain dictionary for a given key
 *
 * Retrieve a keychain dictionary for a given key.  See <tt>AISystemNetworkDefaults</tt> for an example useage.
 * @param key The key by which to retrieve the dictionary
 * @return An <tt>NSDictionary</tt> of the values from the keychain.
 */
+ (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key;

@end
