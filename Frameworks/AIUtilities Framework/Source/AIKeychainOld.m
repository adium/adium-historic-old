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

/*
    Deprecated from AIUtilities, kept for upgrading purposes:
	Cocoa wrapper for accessing the system keychain
 */

#import "AIKeychainOld.h"
#include <CoreServices/CoreServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>

@implementation AIKeychainOld

//Convenience accessor for SecKeychainFindGenericPassword
OSStatus GetPasswordKeychainOld(const char *service,const char *account,void *passwordData,UInt32 *passwordLength,SecKeychainItemRef *itemRef)
{
	OSStatus	ret;
	
	ret = SecKeychainFindGenericPassword (NULL,				// default keychain
										  strlen(service),	// length of service name
										  service,			// service name
										  strlen(account),	// length of account name
										  account,			// account name
										  passwordLength,   // length of password - NULL if unneedeed, along with passwordData
										  passwordData,		// pointer to password data - NULL if unneedeed, along with passwordLength
										  itemRef			// the item reference - NULL if unneedeed
										  );
	
	return ret;
}

// Retrieves a password from the keychain for the specified service and account
// Returns nil if no password is found
+ (NSString *)getPasswordFromKeychainForService:(NSString *)service account:(NSString *)account
{
	NSString			*passwordString = nil;
	OSStatus			ret;
	
	//These will be filled in by GetPasswordKeychainOld
	char				*passwordData = nil;
	UInt32				passwordLength = nil;

	NSAssert((service && [service length] > 0),@"getPasswordFromKeychainForService: service wasn't acceptable!");
	NSAssert((account && [account length] > 0),@"getPasswordFromKeychainForService: account wasn't acceptable!");
	
	ret = GetPasswordKeychainOld([service UTF8String],[account UTF8String],&passwordData,&passwordLength,NULL);
	
    if (ret == noErr){
        passwordString = [NSString stringWithCString:passwordData length:passwordLength];
		
		//Cleanup
		SecKeychainItemFreeContent(NULL,passwordData);
	}
	
    return passwordString;
}

@end
