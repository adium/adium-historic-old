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

/*
    Cocoa wrapper for accessing the system keychain
 */

#import "AIKeychain.h"
#import "AIWiredData.h"
#import "AIWiredString.h"
#include <CoreServices/CoreServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>

@implementation AIKeychain

//Convenience accessor for SecKeychainFindGenericPassword
OSStatus GetPasswordKeychain(const char *service,const char *account,void **passwordData,UInt32 *passwordLength,SecKeychainItemRef *itemRef)
{
	OSStatus	ret;
	
	ret = SecKeychainFindInternetPassword (NULL,			// default keychain
										   strlen(service), service,
										   0, NULL,			// securityDomain
										   strlen(account), account,
										   0, NULL,			//path
										   0,				//port
										   'AdIM',
										   kSecAuthenticationTypeDefault,
										   passwordLength,	// length of password - NULL if unneedeed, along with passwordData
										   passwordData,	// pointer to password data - NULL if unneedeed, along with passwordLength
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
	char				*passwordBytes = nil;
	UInt32				passwordLength = nil;
	
	NSAssert((service && [service length] > 0),@"getPasswordFromKeychainForService: service wasn't acceptable!");
	NSAssert((account && [account length] > 0),@"getPasswordFromKeychainForService: account wasn't acceptable!");
	
	ret = GetPasswordKeychain([service UTF8String],[account UTF8String],(void **)&passwordBytes,&passwordLength,NULL);
	
	if (ret == noErr){
		NSData	*passwordData = [AIWiredData dataWithBytes:passwordBytes length:passwordLength];
		passwordString = [[[AIWiredString alloc] initWithData:passwordData
													 encoding:NSUTF8StringEncoding] autorelease];			
	}
	if(passwordBytes)
		SecKeychainItemFreeContent(/*attrList*/ NULL, passwordBytes);

    return passwordString;
}

// Puts a password on the keychain for the specified service and account
+ (BOOL)putPasswordInKeychainForService:(NSString *)service account:(NSString *)account password:(NSString *)password
{
	NSData				*passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    OSStatus			ret;
	SecKeychainItemRef  itemRef = nil;	
	const char			*serviceUTF8String = [service UTF8String];
	const char			*accountUTF8String = [account UTF8String];
	BOOL				success = NO;

	ret = GetPasswordKeychain(serviceUTF8String,accountUTF8String,NULL,NULL,&itemRef);
	
	if (ret == errSecItemNotFound){
		//No item in the keychain, so add a new password
		
		ret = SecKeychainAddInternetPassword (NULL,		// default keychain
											  strlen(serviceUTF8String), serviceUTF8String,
											  0, NULL, // securityDomain
											  strlen(accountUTF8String), accountUTF8String,
											  0, NULL, //path
											  0,		//port,
											  'AdIM',
											  kSecAuthenticationTypeDefault,
											  [passwordData length],	// length of password - NULL if unneedeed, along with passwordData
											  [passwordData bytes],		// pointer to password data - NULL if unneedeed, along with passwordLength
											  NULL						// the item reference - NULL if unneedeed
											  );
		
		if(ret == noErr) success = YES;
		
	}else if (ret == noErr){
		//Item already present, so change it to the new password
		ret = SecKeychainItemModifyAttributesAndData (itemRef,					// the item reference
													  NULL,						// no change to attributes
													  [passwordData length],	// length of password
													  [passwordData bytes]		// pointer to password data
													  );
		
		if(ret == noErr) success = YES;
	}

	//Cleanup
	if(itemRef) CFRelease(itemRef);
	
	NSLog(@"putPassword of length %i forService: %@ account: %@ -- Successful? %@",
		  [password length],
		  service,
		  account,
		  (success ? @"Yes" : @"No"));

	return(success);
}

// Removes a password from the keychain
+ (BOOL)removePasswordFromKeychainForService:(NSString *)service account:(NSString *)account
{	
	SecKeychainItemRef  itemRef = nil;
	OSStatus			ret;
	
	//Password and password length are irrelevent; we only care about finding an itemRef
	ret = GetPasswordKeychain([service UTF8String],[account UTF8String],NULL,NULL,&itemRef);

	//If we found an keychain item, delete it
    if (ret == noErr) SecKeychainItemDelete(itemRef);
	
	//Cleanup
	if(itemRef) CFRelease(itemRef);
	return(ret == noErr);
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
			if(data && [data bytes]) {
				server = [NSString stringWithUTF8String:[data bytes]];
			}
			
			if([key isEqualToString:server]) {
				NSString    *username;
				NSString    *password;
				
				data = OWKCGetItemAttribute(item, kSecAccountItemAttr);
				if(data && [data bytes]){
					username = [NSString stringWithUTF8String:[data bytes]];
				}else{
					username = @"";
				}
				
				if((SecKeychainItemCopyContent(item, NULL, NULL, &length, &itemData) == noErr) &&
				   (itemData) && 
				   (length > 0)){
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
