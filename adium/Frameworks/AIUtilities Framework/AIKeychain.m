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
    Cocoa wrapper for accessing the system keychain
 */

#import "AIKeychain.h"
#include <CoreServices/CoreServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>

@implementation AIKeychain

//Convenience accessor for SecKeychainFindGenericPassword
OSStatus GetPasswordKeychain(const char *service,const char *account,void *passwordData,UInt32 *passwordLength,SecKeychainItemRef *itemRef)
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
	
	//These will be filled in by GetPasswordKeychain
	char				*passwordData = nil;
	UInt32				passwordLength = nil;

	ret = GetPasswordKeychain([service UTF8String],[account UTF8String],&passwordData,&passwordLength,NULL);
	
    if (ret == noErr){
        passwordString = [NSString stringWithCString:passwordData length:passwordLength];
		
		//Cleanup
		SecKeychainItemFreeContent(NULL,passwordData);
	}
	
    return passwordString;
}

// Puts a password on the keychain for the specified service and account
+ (void)putPasswordInKeychainForService:(NSString *)service account:(NSString *)account password:(NSString *)password
{
    OSStatus			ret;
	SecKeychainItemRef  itemRef = nil;
	
	const char			*serviceUTF8String = [service UTF8String];
	const char			*accountUTF8String = [account UTF8String];
	const char			*passwordUTF8String = [password UTF8String];
	
	ret = GetPasswordKeychain(serviceUTF8String,accountUTF8String,NULL,NULL,&itemRef);

	if (ret == errSecItemNotFound){
			//No item in the keychain, so add a new generic password
		
			ret = SecKeychainAddGenericPassword (NULL,							// default keychain
												 strlen(serviceUTF8String),		// length of service name
												 serviceUTF8String,				// service name
												 strlen(accountUTF8String),		// length of account name
												 accountUTF8String,				// account name
												 strlen(passwordUTF8String),	// length of password
												 passwordUTF8String,			// pointer to password data
												 NULL							// the item reference
												 );
		
	}else if (ret == noErr){
			//Item already present, so change it to the new password
		
			// Set up attribute vector (each attribute consists of {tag, length, pointer}):
			SecKeychainAttribute attrs[] = { 
			{ kSecAccountItemAttr, strlen(accountUTF8String), (void *)accountUTF8String },
			{ kSecServiceItemAttr, strlen(serviceUTF8String), (void *)serviceUTF8String } };
			
			const SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
			ret = SecKeychainItemModifyAttributesAndData (itemRef,						// the item reference
														  &attributes,					// no change to attributes
														  strlen(passwordUTF8String),	// length of password
														  passwordUTF8String			// pointer to password data
														  );
	}
	
	//Cleanup
	if (itemRef) CFRelease(itemRef);
}

// Removes a password from the keychain
+ (void)removePasswordFromKeychainForService:(NSString *)service account:(NSString *)account
{	
	SecKeychainItemRef  itemRef = nil;
	OSStatus			ret;
	
	//Password and password length are irrelevent; we only care about finding an itemRef
	ret = GetPasswordKeychain([service UTF8String],[account UTF8String],NULL,NULL,&itemRef);

	//If we found an keychain item, delete it
    if (ret == noErr) SecKeychainItemDelete(itemRef);
	
	//Cleanup
	if (itemRef) CFRelease(itemRef);
}

//Next two functions are from the http-mail project.
static NSData *OWKCGetItemAttribute(KCItemRef item, KCItemAttr attrTag)
{
    SecKeychainAttribute    attr;
    OSStatus                keychainStatus;
    UInt32                  actualLength;
    void                    *freeMe = NULL;
    
    attr.tag = attrTag;
    actualLength = 256;
    attr.length = actualLength; 
    attr.data = alloca(actualLength);
    
    keychainStatus = KCGetAttribute(item, &attr, &actualLength);
    if (keychainStatus == errKCBufferTooSmall) {
        /* the attribute length will have been placed into actualLength */
        freeMe = NSZoneMalloc(NULL, actualLength);
        attr.length = actualLength;
        attr.data = freeMe;
        keychainStatus = KCGetAttribute(item, &attr, &actualLength);
    }
    if (keychainStatus == noErr) {
        NSData *retval = [NSData dataWithBytes:attr.data length:actualLength];
        if (freeMe != NULL)
            NSZoneFree(NULL, freeMe);
        return retval;
    }
    
    if (freeMe != NULL)
        NSZoneFree(NULL, freeMe);
    
    if (keychainStatus == errKCNoSuchAttr) {
        /* An expected error. Return nil for nonexistent attributes. */
        return nil;
    }
    
    /* We shouldn't make it here */
    [NSException raise:@"Error Reading Keychain" format:@"Error number %d.", keychainStatus];
    
    return nil;  // appease the dread compiler warning gods
}

+ (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key
{
    NSData              *data;
    KCSearchRef         grepstate; 
    KCItemRef           item;
    UInt32              length;
    void                *itemData;
    NSMutableDictionary *result = nil;
    
    SecKeychainRef      keychain;
    SecKeychainCopyDefault(&keychain);
    
	if(KCFindFirstItem(keychain, NULL, &grepstate, &item)==noErr) {  
		do {
			NSString    *server = nil;
			
			data = OWKCGetItemAttribute(item, kSecLabelItemAttr);
			if(data) {
				server = [NSString stringWithCString:[data bytes] length:[data length]];
			}
			
			if([key isEqualToString:server]) {
				NSString    *username;
				NSString    *password;
				
				data = OWKCGetItemAttribute(item, kSecAccountItemAttr);
				if(data){
					username = [NSString stringWithCString:[data bytes] length:[data length]];
				}else{
					username = @"";
				}
				
				if(SecKeychainItemCopyContent(item, NULL, NULL, &length, &itemData) == noErr) {
					password = [NSString stringWithCString:itemData length:length];
					SecKeychainItemFreeContent(NULL, itemData);
				} else {
					password = @"";
				} 
				
				result = [NSDictionary dictionaryWithObjectsAndKeys:username,@"username",password,@"password",nil];
				
				KCReleaseItem(&item);
				
				break;
			}
			
			KCReleaseItem(&item);
		} while( KCFindNextItem(grepstate, &item)==noErr);
		
		KCReleaseSearch(&grepstate);
	}
    
	CFRelease(keychain);
    return result;   
}

@end
