/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
    Cocoa wrapper for accessing the system keychain
 */

#import "AIKeychain.h"
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

@interface AIKeychain (PRIVATE)
+ (KCItemRef)getKCItemRefWithAccount:(NSString *)account service:(NSString *)service;
@end


@implementation AIKeychain

/* getPasswordFromKeychainForService
*   gets a password from the keychain for the specified service & account
*/
+ (NSString *)getPasswordFromKeychainForService:(NSString *)service account:(NSString *)account
{
    OSStatus ret;
    UInt32 len;
    void *p = (void *)malloc(128 * sizeof(char));
    NSString *string = nil;
    
    ret = kcfindgenericpassword([service cString], [account cString], 127, p, &len, NULL);
	
    if (!ret){
        string = [NSString stringWithCString:(const char*)p length:len];
	}
	
    free(p); 
    return string;
}

// puts a password on the keychain for the specified service and account
+ (void)putPasswordInKeychainForService:(NSString *)service account:(NSString *)account password:(NSString *)password
{
    OSStatus	ret;
    KCItemRef   itemref = NULL;
	
    if ((itemref = [self getKCItemRefWithAccount:account service:service])){
		KCDeleteItem(itemref);
	}
    ret = kcaddgenericpassword([service cString], [account cString], [password cStringLength], 
							   [password cString], NULL);
}

// removes a password from the keychain
+ (void)removePasswordFromKeychainForService:(NSString *)service account:(NSString *)account
{
	KCItemRef itemref = NULL;
	if ((itemref = [self getKCItemRefWithAccount:account service:service])){
		KCDeleteItem(itemref);
	}
}

//returns a keychain item ref
+ (KCItemRef)getKCItemRefWithAccount:(NSString *)account service:(NSString *)service
{
	KCItemRef itemref = NULL;
	kcfindgenericpassword([service cString], [account cString], NULL, NULL, NULL, &itemref);
	return itemref;
}

@end
