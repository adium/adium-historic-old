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
 *Cocoa wrapper for accessing the system keychain
 */

#import "AIKeychain.h"
#import "AIStringAdditions.h"
#import "AIWiredData.h"
#import "AIWiredString.h"
#include <CoreServices/CoreServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>

static AIKeychain *lastKnownDefaultKeychain = nil;

#define AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err) \
	NSLocalizedStringFromTableInBundle([[NSNumber numberWithLong:(err)] stringValue], @"SecErrorMessages", [NSBundle bundleWithIdentifier:@"com.apple.security"], /*comment*/ nil)

@implementation AIKeychain

+ (void)lockAllKeychains_error:(out NSError **)outError
{
	OSStatus err = SecKeychainLockAll();
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainLockAll], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainLockAll", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
}

+ (void)lockDefaultKeychain_error:(out NSError **)outError
{
	OSStatus err = SecKeychainLock(/*keychain*/ NULL);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainLock], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainLock", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
}
+ (BOOL)unlockDefaultKeychain_error:(out NSError **)outError
{
	OSStatus err = SecKeychainUnlock(/*keychain*/ NULL, /*passwordLength*/ 0, /*password*/ NULL, /*usePassword*/ false);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainUnlock], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainUnlock", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
	return err == noErr;
}
+ (BOOL)unlockDefaultKeychainWithPassword:(NSString *)password error:(out NSError **)outError
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	AIWiredString *str = [AIWiredString stringWithString:password];
	AIWiredData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
	OSStatus err = SecKeychainUnlock(/*keychain*/ NULL, [data length], [data bytes], /*usePassword*/ true);

	[pool release];

	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainUnlock], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainUnlock", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
	return err == noErr;
}

+ (BOOL)allowsUserInteraction_error:(out NSError **)outError
{
	Boolean state = false;

	OSStatus err = SecKeychainGetUserInteractionAllowed(&state);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainGetUserInteractionAllowed], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainGetUserInteractionAllowed", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}

	return state;
}
+ (void)setAllowsUserInteraction:(BOOL)flag error:(out NSError **)outError
{
	OSStatus err = SecKeychainSetUserInteractionAllowed(flag);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainSetUserInteractionAllowed], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainSetUserInteractionAllowed", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				[NSNumber numberWithBool:flag], AIKEYCHAIN_ERROR_USERINFO_USERINTERACTIONALLOWEDSTATE,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
}

+ (u_int32_t)keychainServicesVersion_error:(out NSError **)outError
{
	UInt32 version;
	//will this function EVER return an error? well, it can, so we should be prepared for it. --boredzo
	OSStatus err = SecKeychainGetVersion(&version);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainGetVersion], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainGetVersion", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
	return version;
}

#pragma mark -

+ (SecKeychainRef)copyDefaultSecKeychainRef_error:(out NSError **)outError
{
	SecKeychainRef aKeychainRef = NULL;

	OSStatus err = SecKeychainCopyDefault(&aKeychainRef);
	if (err != noErr) {
		if (err == errSecNoDefaultKeychain) {
			/* XXX - SecKeychainCreate() to an appropriate path here, followed by SecKeychainSetDefault(), would
			 * be very nice.  However, it really should not be necessary in general, since a default keychain is created
			 * at login. The only way we can get here is if the user deleted his default keychain during this OS X session
			 * and didn't create a new one.  He may not deserve password storage, anyways.
			 */
		}
		
		if (err != errSecNoDefaultKeychain) {
			if (outError) {
				NSError *error = nil;
				if (err != noErr) {
					NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSValue valueWithPointer:SecKeychainCopyDefault], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
						@"SecKeychainCopyDefault", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
						AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
						nil];
					error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
				}
				*outError = error;
			}
		}
		
		if (aKeychainRef) CFRelease(aKeychainRef);
		
		return nil;
	}
	
	return aKeychainRef;
}

+ (AIKeychain *)defaultKeychain_error:(out NSError **)outError
{
	/* ensure there is a default keychain which can be accessed */
	SecKeychainRef aKeychainRef = [self copyDefaultSecKeychainRef_error:outError];

	if (aKeychainRef) {
		if (!lastKnownDefaultKeychain ||
			([lastKnownDefaultKeychain keychainRef] && (aKeychainRef != [lastKnownDefaultKeychain keychainRef]))) {
			[lastKnownDefaultKeychain release];
			lastKnownDefaultKeychain = [[self alloc] init];
		}

		CFRelease(aKeychainRef);

		return [[lastKnownDefaultKeychain retain] autorelease];

	} else {
		NSLog(@"No default keychain!");
		return nil;
	}
}

+ (void)setDefaultKeychain:(AIKeychain *)newDefaultKeychain error:(out NSError **)outError
{
	NSParameterAssert(newDefaultKeychain != nil);

	OSStatus err = ([newDefaultKeychain keychainRef] ? SecKeychainSetDefault([newDefaultKeychain keychainRef]) : noErr);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainSetDefault], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainSetDefault", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
	if (err == noErr) {
		[lastKnownDefaultKeychain release];
		lastKnownDefaultKeychain = [newDefaultKeychain retain];
	}
}

+ (AIKeychain *)keychainWithContentsOfFile:(NSString *)path error:(out NSError **)outError
{
	return [[[self alloc] initWithContentsOfFile:path error:outError] autorelease];
}
- (id)initWithContentsOfFile:(NSString *)path error:(out NSError **)outError
{
	if ((self = [super init])) {
		OSStatus err = SecKeychainOpen([path fileSystemRepresentation], &keychainRef);
		if (outError) {
			NSError *error = nil;
			if (err != noErr) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSValue valueWithPointer:SecKeychainOpen], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
					@"SecKeychainOpen", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
					AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
					nil];
				error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
			}
			*outError = error;
		}
		if (err != noErr) {
			[self release];
			self = nil;
		}
	}

	return self;
}

//SecKeychainCreate
+ (AIKeychain *)keychainWithPath:(NSString *)path password:(NSString *)password promptUser:(BOOL)prompt initialAccess:(SecAccessRef)initialAccess error:(out NSError **)outError
{
	return [[[self alloc] initWithPath:path password:password promptUser:prompt initialAccess:initialAccess error:outError] autorelease];
}
- (id)initWithPath:(NSString *)path password:(NSString *)password promptUser:(BOOL)prompt initialAccess:(SecAccessRef)initialAccess error:(out NSError **)outError
{
	if ((self = [super init])) {
		/*we create our own copy of the string (if any) using AIWiredString to
		 *	ensure that the NSData that we create is an AIWiredData.
		 *we create our own pool to ensure that both objects are released ASAP.
		 */
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		void     *passwordBytes  = NULL;
		u_int32_t passwordLength = 0;

		if (password) {
			AIWiredString *str = [AIWiredString stringWithString:password];
			AIWiredData  *data = [str dataUsingEncoding:NSUTF8StringEncoding];
			passwordBytes      = (void *)[data bytes];
			passwordLength     = [data length];
		}

		OSStatus err = SecKeychainCreate([path fileSystemRepresentation], passwordLength, passwordBytes, prompt, initialAccess, &keychainRef);

		[pool release];

		if (outError) {
			NSError *error = nil;
			if (err != noErr) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSValue valueWithPointer:SecKeychainCreate], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
					@"SecKeychainCreate", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
					AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
					nil];
				error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
			}
			*outError = error;
		}
		if (err != noErr) {
			[self release];
			self = nil;
		}

	}

	return self;
}

+ (AIKeychain *)keychainWithKeychainRef:(SecKeychainRef)newKeychainRef
{
	return [[[self alloc] initWithKeychainRef:newKeychainRef] autorelease];
}

- (id)initWithKeychainRef:(SecKeychainRef)newKeychainRef
{
	if ((self = [super init])) {
		keychainRef = (newKeychainRef ? (SecKeychainRef)CFRetain(newKeychainRef) : NULL);
	}

	return self;
}

#pragma mark -

- (void)getSettings:(out struct SecKeychainSettings *)outSettings error:(out NSError **)outError
{
	NSParameterAssert(outSettings != NULL);
	SecKeychainRef targetKeychainRef = (keychainRef ? (SecKeychainRef)CFRetain(keychainRef) : NULL);

	if (!targetKeychainRef) targetKeychainRef = [[self class] copyDefaultSecKeychainRef_error:outError];

	if (targetKeychainRef) {
		OSStatus err = SecKeychainCopySettings(targetKeychainRef, outSettings);
		if (outError) {
			NSError *error = nil;
			if (err != noErr) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSValue valueWithPointer:outSettings], AIKEYCHAIN_ERROR_USERINFO_SETTINGSPOINTER,
					[NSValue valueWithPointer:SecKeychainCopySettings], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
					@"SecKeychainCopySettings", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
					AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
					nil];
				error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
			}
			*outError = error;
		}
		
		CFRelease(targetKeychainRef);
	}
}
- (void)setSettings:(in struct SecKeychainSettings *)newSettings error:(out NSError **)outError
{
	NSParameterAssert(newSettings != NULL);

	/* If keychainRef is NULL, we'll get the default keychain's settings */
	OSStatus err = SecKeychainSetSettings(keychainRef, newSettings);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:newSettings], AIKEYCHAIN_ERROR_USERINFO_SETTINGSPOINTER,
				[NSValue valueWithPointer:SecKeychainSetSettings], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainSetSettings", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
}

- (SecKeychainStatus)status_error:(out NSError **)outError
{
	SecKeychainStatus status;
	/* If keychainRef is NULL, we'll get the default keychain's status */
	OSStatus err = SecKeychainGetStatus(keychainRef, &status);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainGetStatus], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainGetStatus", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
	return status;
}

- (char *)getPathFileSystemRepresentation:(out char *)outBuf length:(inout u_int32_t *)outLength error:(out NSError **)outError
{
	NSParameterAssert(outBuf != NULL);
	NSParameterAssert((outLength != NULL) && (*outLength > 0));

	SecKeychainRef targetKeychainRef = (keychainRef ? (SecKeychainRef)CFRetain(keychainRef) : NULL);
	
	if (!targetKeychainRef) targetKeychainRef = [[self class] copyDefaultSecKeychainRef_error:outError];
	
	if (targetKeychainRef) {		
		OSStatus err = SecKeychainGetPath(targetKeychainRef, (UInt32 *)outLength, outBuf);
		
		NSError *error = nil;
		
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainGetPath], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainGetPath", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				targetKeychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			if (outError)
				error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
			outBuf = NULL;
		}
		
		if (outError) *outError = error;

		CFRelease(targetKeychainRef);

	} else {
		outBuf = NULL;	
	}

	return outBuf;
}
- (NSString *)path
{
	NSMutableData *data = [NSMutableData dataWithLength:PATH_MAX];
	u_int32_t size = PATH_MAX;
	[self getPathFileSystemRepresentation:[data mutableBytes]
								   length:&size
									error:NULL];
	[data setLength:size];
	return [NSString stringWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark -

- (void)lockKeychain_error:(out NSError **)outError
{
	/* If keychainRef is NULL, the default keychain will locked */
	OSStatus err = SecKeychainLock(keychainRef);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainLock], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainLock", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
}

- (BOOL)unlockKeychain_error:(out NSError **)outError
{
	/* If keychainRef is NULL, the default keychain will unlocked */
	OSStatus err = SecKeychainUnlock(keychainRef, /*passwordLength*/ 0, /*password*/ NULL, /*usePassword*/ false);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainUnlock], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainUnlock", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
	return err == noErr;
}
- (BOOL)unlockKeychainWithPassword:(NSString *)password error:(out NSError **)outError
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	AIWiredString *str = [AIWiredString stringWithString:password];
	AIWiredData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
	
	/* If keychainRef is NULL, the default keychain will unlocked */
	OSStatus err = SecKeychainUnlock(keychainRef, [data length], [data bytes], /*usePassword*/ true);

	[pool release];

	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainUnlock], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainUnlock", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
	return err == noErr;
}

#pragma mark -

- (void)deleteKeychain_error:(out NSError **)outError
{
	SecKeychainRef targetKeychainRef = (keychainRef ? (SecKeychainRef)CFRetain(keychainRef) : NULL);
	
	if (!targetKeychainRef) targetKeychainRef = [[self class] copyDefaultSecKeychainRef_error:outError];
	
	if (targetKeychainRef) {				
		/* In 10.2, passing NULL to SecKeychainDelete deletes the default keychain.
		* In 10.3+, passing NULL returns errSecInvalidKeychain.
		*/
		OSStatus err = SecKeychainDelete(targetKeychainRef);
		if (outError) {
			NSError *error = nil;
			if (err != noErr) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSValue valueWithPointer:SecKeychainDelete], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
					@"SecKeychainDelete", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
					AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
					targetKeychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
					nil];
				error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
			}
			*outError = error;
		}

		CFRelease(targetKeychainRef);
	}
}

#pragma mark -

- (void)addInternetPassword:(NSString *)password
				  forServer:(NSString *)server
			 securityDomain:(NSString *)domain //can pass nil
					account:(NSString *)account
					   path:(NSString *)path
					   port:(u_int16_t)port //can pass 0
				   protocol:(SecProtocolType)protocol
		 authenticationType:(SecAuthenticationType)authType
			   keychainItem:(out SecKeychainItemRef *)outKeychainItem
					  error:(out NSError **)outError
{
	NSParameterAssert(password != nil);
	NSParameterAssert(server != nil);
	//domain is optional

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	AIWiredString *passwordStr  = [AIWiredString stringWithString:password];
	AIWiredData   *passwordData = [passwordStr dataUsingEncoding:NSUTF8StringEncoding];

	NSData *serverData  = [server  dataUsingEncoding:NSUTF8StringEncoding];
	NSData *domainData  = [domain  dataUsingEncoding:NSUTF8StringEncoding];
	NSData *accountData = [account dataUsingEncoding:NSUTF8StringEncoding];
	NSData *pathData    = [path    dataUsingEncoding:NSUTF8StringEncoding];

	/* If keychainRef is NNULL, the password will be added to the default keychain */
	OSStatus err = SecKeychainAddInternetPassword(keychainRef,
												  [serverData length],  [serverData bytes],
												  //domain is optional, so be sure to handle domain == nil
												  domainData ? [domainData length] : 0,
												  domainData ? [domainData bytes]  : NULL,
												  //account appears optional, even though it isn't so documented
												  accountData ? [accountData length] : 0,
												  accountData ? [accountData bytes]  : NULL,
												  //path appears optional, even though it isn't so documented
												  pathData ? [pathData length] : 0,
												  pathData ? [pathData bytes]  : NULL,
												  port,
												  protocol,
												  authType,
												  [passwordData length], [passwordData bytes],
												  outKeychainItem);

	[pool release];

	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainAddInternetPassword], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainAddInternetPassword", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				server,  AIKEYCHAIN_ERROR_USERINFO_SERVER,
				domain,  AIKEYCHAIN_ERROR_USERINFO_DOMAIN,
				account, AIKEYCHAIN_ERROR_USERINFO_ACCOUNT,
				NSFileTypeForHFSTypeCode(protocol), AIKEYCHAIN_ERROR_USERINFO_PROTOCOL,
				NSFileTypeForHFSTypeCode(authType), AIKEYCHAIN_ERROR_USERINFO_AUTHENTICATIONTYPE,
				keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
}

- (void)addInternetPassword:(NSString *)password forServer:(NSString *)server account:(NSString *)account protocol:(SecProtocolType)protocol error:(out NSError **)outError
{
	[self addInternetPassword:password
					forServer:server
			   securityDomain:nil
					  account:account
						 path:nil
						 port:0
					 protocol:protocol
		   authenticationType:kSecAuthenticationTypeDefault
				 keychainItem:NULL
						error:outError];
}

//------------------------------------------------------------------------------

- (NSString *)findInternetPasswordForServer:(NSString *)server
							 securityDomain:(NSString *)domain //can pass nil
									account:(NSString *)account
									   path:(NSString *)path
									   port:(u_int16_t)port //can pass 0
								   protocol:(SecProtocolType)protocol
						 authenticationType:(SecAuthenticationType)authType
							   keychainItem:(out SecKeychainItemRef *)outKeychainItem
									  error:(out NSError **)outError
{
	void  *passwordData   = NULL;
	UInt32 passwordLength = 0;

	NSData *serverData  = [server  dataUsingEncoding:NSUTF8StringEncoding];
	NSData *domainData  = [domain  dataUsingEncoding:NSUTF8StringEncoding];
	NSData *accountData = [account dataUsingEncoding:NSUTF8StringEncoding];
	NSData *pathData    = [path    dataUsingEncoding:NSUTF8StringEncoding];
	AIWiredString *passwordString = nil;

	/* If keychainRef is NULL, the users's default keychain search list will be used */
	OSStatus err = SecKeychainFindInternetPassword(keychainRef,
												   [serverData length],  [serverData bytes],
												   //domain is optional, so be sure to handle domain == nil
												   domainData ? [domainData length] : 0,
												   domainData ? [domainData bytes]  : NULL,
												   //account appears optional, even though it isn't so documented
												   accountData ? [accountData length] : 0,
												   accountData ? [accountData bytes]  : NULL,
												   //path appears optional, even though it isn't so documented
												   pathData ? [pathData length] : 0,
												   pathData ? [pathData bytes]  : NULL,
												   port,
												   protocol,
												   authType,
												   &passwordLength,
												   &passwordData,
												   outKeychainItem);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainFindInternetPassword], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainFindInternetPassword", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				server,  AIKEYCHAIN_ERROR_USERINFO_SERVER,
				domain,  AIKEYCHAIN_ERROR_USERINFO_DOMAIN,
				account, AIKEYCHAIN_ERROR_USERINFO_ACCOUNT,
				NSFileTypeForHFSTypeCode(protocol), AIKEYCHAIN_ERROR_USERINFO_PROTOCOL,
				NSFileTypeForHFSTypeCode(authType), AIKEYCHAIN_ERROR_USERINFO_AUTHENTICATIONTYPE,
				keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}

	passwordString = [AIWiredString stringWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
	SecKeychainItemFreeContent(NULL, passwordData);
	return passwordString;
}

- (NSString *)internetPasswordForServer:(NSString *)server account:(NSString *)account protocol:(SecProtocolType)protocol error:(out NSError **)outError
{
	NSString *password = [self findInternetPasswordForServer:server
											  securityDomain:nil
													 account:account
														path:nil
														port:0
													protocol:protocol
										  authenticationType:kSecAuthenticationTypeDefault
												keychainItem:NULL
													   error:outError];

	return password;
}

- (NSDictionary *)dictionaryFromKeychainForServer:(NSString *)server protocol:(SecProtocolType)protocol error:(out NSError **)outError
{
	NSDictionary *result = nil;

	//search for keychain items whose server is our key.
	SecKeychainSearchRef search = NULL;

	struct SecKeychainAttribute searchAttrs[] = {
		{
			.tag    = kSecServerItemAttr,
			.length = [server length],
			.data   = (void *)[server UTF8String],
		},
		{
			.tag    = kSecProtocolItemAttr,
			.length = sizeof(SecProtocolType),
			.data   = &protocol,
		}
	};
	struct SecKeychainAttributeList searchAttrList = {
		.count = 2,
		.attr  = searchAttrs,
	};
	/* If keychainRef is NULL, the users's default keychain search list will be used */
	OSStatus err = SecKeychainSearchCreateFromAttributes(keychainRef, kSecInternetPasswordItemClass, &searchAttrList, &search);
	if (err == noErr) {
		SecKeychainItemRef item = NULL;
			
		err = SecKeychainSearchCopyNext(search, &item);
		if (err == errSecItemNotFound) {
			//No matching server found
		} else if (err == noErr) {
			//Output storage.
			struct SecKeychainAttributeList *attrList = NULL;
			UInt32 passwordLength = 0U;
			void  *passwordBytes = NULL;

			//First, grab the username.
			UInt32    tags[] = { kSecAccountItemAttr };
			UInt32 formats[] = { CSSM_DB_ATTRIBUTE_FORMAT_STRING };
			struct SecKeychainAttributeInfo info = {
				.count  = 1,
				.tag    = tags,
				.format = formats,
			};
			err = SecKeychainItemCopyAttributesAndData(item,
													   &info,
													   /*itemClass*/ NULL,
													   &attrList,
													   &passwordLength,
													   &passwordBytes);
			if (err == noErr) {
				NSString *username = [NSString stringWithBytes:attrList->attr[0].data length:attrList->attr[0].length encoding:NSUTF8StringEncoding];
				AIWiredString *password = [AIWiredString stringWithBytes:passwordBytes length:passwordLength encoding:NSUTF8StringEncoding];
				result = [NSDictionary dictionaryWithObjectsAndKeys:
					username, @"Username",
					password, @"Password",
					nil];
			} else {
				NSLog(@"Error extracting infomation from keychain item");
			}

			SecKeychainItemFreeAttributesAndData(attrList, passwordBytes);
			if (item) CFRelease(item);

		} else {
			NSLog(@"%@: Eror in SecKeychainSearchCopyNext(); err is %i",self,err);	
		}
		if (search)	CFRelease(search);

	} else {
		NSLog(@"%@: Could not create search; err is %i",self,err);
	}

	return result;
}

//------------------------------------------------------------------------------

- (void)setInternetPassword:(NSString *)password
				  forServer:(NSString *)server
			 securityDomain:(NSString *)domain //can pass nil
					account:(NSString *)account
					   path:(NSString *)path
					   port:(u_int16_t)port //can pass 0
				   protocol:(SecProtocolType)protocol
		 authenticationType:(SecAuthenticationType)authType
			   keychainItem:(out SecKeychainItemRef *)outKeychainItem
					  error:(out NSError **)outError
{
	if (!password) {
		//remove the password.
		[self deleteInternetPasswordForServer:server
							   securityDomain:domain
									  account:account
										 path:path
										 port:port
									 protocol:protocol
						   authenticationType:authType
								 keychainItem:outKeychainItem
										error:outError];
	} else {
		//add it if it does not exist.
		NSError *error = nil;
		[self addInternetPassword:password
						forServer:server
				   securityDomain:domain
						  account:account
							 path:path
							 port:port
						 protocol:protocol
			   authenticationType:authType
					 keychainItem:outKeychainItem
							error:&error];
		if (error) {
			OSStatus err = [error code];

			if (err == errSecDuplicateItem) {
				/*we already have an item for this, so find it and change it.
				 *we create an autorelease pool because of the string that
				 *	-findInternetPasswordForServer:... returns.
				 */

				SecKeychainItemRef item = NULL;
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

				[self findInternetPasswordForServer:server
									 securityDomain:domain
											account:account
											   path:path
											   port:port
										   protocol:protocol
								 authenticationType:authType
									   keychainItem:&item
											  error:&error];
				[(NSObject *)item autorelease]; //might as well.

				if (error) {
					//Retain this because of the autorelease pool.
					if (outError) *outError = [error retain];
				} else {
					AIWiredString *passwordStr  = [AIWiredString stringWithString:password];
					AIWiredData   *passwordData = [passwordStr dataUsingEncoding:NSUTF8StringEncoding];

					//change the password.
					err = SecKeychainItemModifyAttributesAndData(item,
																 /*attrList*/ NULL,
																 [passwordData length],
																 [passwordData bytes]);
					if (outError) {
						if (err == noErr) {
							error = nil;
						} else {
							NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSValue valueWithPointer:SecKeychainItemModifyAttributesAndData], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
								@"SecKeychainItemModifyAttributesAndData", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
								AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
								server,  AIKEYCHAIN_ERROR_USERINFO_SERVER,
								domain,  AIKEYCHAIN_ERROR_USERINFO_DOMAIN,
								account, AIKEYCHAIN_ERROR_USERINFO_ACCOUNT,
								NSFileTypeForHFSTypeCode(protocol), AIKEYCHAIN_ERROR_USERINFO_PROTOCOL,
								NSFileTypeForHFSTypeCode(authType), AIKEYCHAIN_ERROR_USERINFO_AUTHENTICATIONTYPE,
								keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
								nil];
							//Retain this because of the autorelease pool.
							error = [[NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo] retain];
						}
						*outError = error;
					} //if (outError)
				} //if (!error) (findInternetPasswordForServer:...)

				[pool release];
				[error autorelease];
			} //if (err == errSecDuplicateItem)
		} //if (error) (addInternetPassword:...)
	} //if (password)
}

- (void)setInternetPassword:(NSString *)password
				  forServer:(NSString *)server
					account:(NSString *)account
				   protocol:(SecProtocolType)protocol
					  error:(out NSError **)outError
{
	[self setInternetPassword:password
					forServer:server
			   securityDomain:nil
					  account:account
						 path:nil
						 port:0
					 protocol:protocol
		   authenticationType:kSecAuthenticationTypeDefault
				 keychainItem:NULL
						error:outError];
}

//------------------------------------------------------------------------------

- (void)deleteInternetPasswordForServer:(NSString *)server
						 securityDomain:(NSString *)domain //can pass nil
								account:(NSString *)account
								   path:(NSString *)path
								   port:(u_int16_t)port //can pass 0
							   protocol:(SecProtocolType)protocol
					 authenticationType:(SecAuthenticationType)authType
						   keychainItem:(out SecKeychainItemRef *)outKeychainItem
								  error:(out NSError **)outError
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	SecKeychainItemRef keychainItem = NULL;
	NSError *error = nil;

	[self findInternetPasswordForServer:server
						 securityDomain:domain
								account:account
								   path:path
								   port:port
							   protocol:protocol
					 authenticationType:authType
						   keychainItem:&keychainItem
								  error:&error];
	if (keychainItem) {
		OSStatus err = SecKeychainItemDelete(keychainItem);
		if (outError) {
			if (err == noErr) error = nil;
			else if (!error) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSValue valueWithPointer:SecKeychainFindInternetPassword], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
					@"SecKeychainFindInternetPassword", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
					AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
					server,  AIKEYCHAIN_ERROR_USERINFO_SERVER,
					account, AIKEYCHAIN_ERROR_USERINFO_ACCOUNT,
					NSFileTypeForHFSTypeCode(protocol), AIKEYCHAIN_ERROR_USERINFO_PROTOCOL,
					NSFileTypeForHFSTypeCode(kSecAuthenticationTypeDefault), AIKEYCHAIN_ERROR_USERINFO_AUTHENTICATIONTYPE,
					keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
					nil];
				error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
			}
			*outError = error;
		}
	}
	if (outKeychainItem) *outKeychainItem = keychainItem;
	else if (keychainItem) CFRelease(keychainItem);

	[pool release];
}

- (void)deleteInternetPasswordForServer:(NSString *)server account:(NSString *)account protocol:(SecProtocolType)protocol error:(out NSError **)outError
{
	[self deleteInternetPasswordForServer:server
						   securityDomain:nil
								  account:account
									 path:nil
									 port:0
								 protocol:protocol
					   authenticationType:kSecAuthenticationTypeDefault
							 keychainItem:NULL
									error:outError];
}

#pragma mark -

- (void)addGenericPassword:(NSString *)password
				forService:(NSString *)service
				   account:(NSString *)account
			  keychainItem:(out SecKeychainItemRef *)outKeychainItem
					 error:(out NSError **)outError
{
	NSParameterAssert(password != nil);
	NSParameterAssert(service != nil);
	NSParameterAssert(account != nil);

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	AIWiredString *passwordStr  = [AIWiredString stringWithString:password];
	AIWiredData   *passwordData = [passwordStr dataUsingEncoding:NSUTF8StringEncoding];

	NSData *serviceData = [service dataUsingEncoding:NSUTF8StringEncoding];
	NSData *accountData = [account dataUsingEncoding:NSUTF8StringEncoding];

	/* If keychainRef is NULL, the default keychain will be used */
	OSStatus err = SecKeychainAddGenericPassword(keychainRef,
												  [serviceData length],  [serviceData bytes],
												  [accountData length],  [accountData bytes],
												 [passwordData length], [passwordData bytes],
												 outKeychainItem);

	[pool release];

	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainAddGenericPassword], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainAddGenericPassword", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				service, AIKEYCHAIN_ERROR_USERINFO_SERVICE,
				account, AIKEYCHAIN_ERROR_USERINFO_ACCOUNT,
				keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}
}

- (NSString *)findGenericPasswordForService:(NSString *)service
									account:(NSString *)account
							   keychainItem:(out SecKeychainItemRef *)outKeychainItem
									  error:(out NSError **)outError
{
	void  *passwordData   = NULL;
	UInt32 passwordLength = 0;

	NSData *serviceData = [service dataUsingEncoding:NSUTF8StringEncoding];
	NSData *accountData = [account dataUsingEncoding:NSUTF8StringEncoding];
	AIWiredString *passwordString = nil;

	/* If keychainRef is NULL, the users's default keychain search list will be used */
	OSStatus err = SecKeychainFindGenericPassword(keychainRef,
												  [serviceData length],  [serviceData bytes],
												  [accountData length],  [accountData bytes],
												  &passwordLength,
												  &passwordData,
												  outKeychainItem);
	if (outError) {
		NSError *error = nil;
		if (err != noErr) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:SecKeychainFindGenericPassword], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
				@"SecKeychainFindGenericPassword", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
				AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
				service, AIKEYCHAIN_ERROR_USERINFO_SERVICE,
				account, AIKEYCHAIN_ERROR_USERINFO_ACCOUNT,
				keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
				nil];
			error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
		}
		*outError = error;
	}

	passwordString = [AIWiredString stringWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
	SecKeychainItemFreeContent(NULL, passwordData);
	return passwordString;	
}

- (void)deleteGenericPasswordForService:(NSString *)service
								account:(NSString *)account
								  error:(out NSError **)outError
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	SecKeychainItemRef keychainItem = NULL;
	NSError *error = nil;

	[self findGenericPasswordForService:service
								account:account
						   keychainItem:&keychainItem
								  error:&error];
	
	if (keychainItem) {
		OSStatus err = SecKeychainItemDelete(keychainItem);
		if (outError) {
			if (err == noErr) error = nil;
			else if (!error) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										  [NSValue valueWithPointer:SecKeychainFindGenericPassword], AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTION,
										  @"SecKeychainFindGenerictPassword", AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME,
										  AI_LOCALIZED_SECURITY_ERROR_DESCRIPTION(err), AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION,
										  service,  AIKEYCHAIN_ERROR_USERINFO_SERVICE,
										  account, AIKEYCHAIN_ERROR_USERINFO_ACCOUNT,
										  NSFileTypeForHFSTypeCode(kSecAuthenticationTypeDefault), AIKEYCHAIN_ERROR_USERINFO_AUTHENTICATIONTYPE,
										  keychainRef, AIKEYCHAIN_ERROR_USERINFO_KEYCHAIN,
										  nil];
				error = [NSError errorWithDomain:AIKEYCHAIN_ERROR_DOMAIN code:err userInfo:userInfo];
			}
			*outError = error;
		}
	}
	
	if (keychainItem) CFRelease(keychainItem);
	
	[pool release];
}

#pragma mark -

//returns the Keychain Services object that backs this object.
- (SecKeychainRef)keychainRef
{
	return keychainRef;
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<AIKeychain %p (%@)>", self, keychainRef];
}

#pragma mark -
#pragma mark Old version

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
	char				*passwordBytes = NULL;
	UInt32				passwordLength = 0;
	
	NSAssert((service && [service length] > 0),@"getPasswordFromKeychainForService: service wasn't acceptable!");
	NSAssert((account && [account length] > 0),@"getPasswordFromKeychainForService: account wasn't acceptable!");
	
	ret = GetPasswordKeychain([service UTF8String],[account UTF8String],(void **)&passwordBytes,&passwordLength,NULL);
	if (ret != noErr) {
		//XXX localize me!
		NSLog(@"could not get password from keychain for account %@ on service %@: GetPasswordKeychain returned %li", account, service, (long)ret);
	} else {
		NSData	*passwordData = [AIWiredData dataWithBytes:passwordBytes length:passwordLength];
		passwordString = [[[AIWiredString alloc] initWithData:passwordData
													 encoding:NSUTF8StringEncoding] autorelease];
		if ([passwordString length] == 0) passwordString = nil;
	}

	if (passwordBytes)
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
	
	if (ret == errSecItemNotFound) {
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
		
		success = (ret == noErr);
		if (!success) {
			//XXX localize me!
			NSLog(@"could not add password in keychain for account %@ on service %@: SecKeychainAddInternetPassword returned %li", account, service, (long)ret);
		}
	} else if (ret == noErr) {
		//Item already present, so change it to the new password
		ret = SecKeychainItemModifyAttributesAndData (itemRef,					// the item reference
													  NULL,						// no change to attributes
													  [passwordData length],	// length of password
													  [passwordData bytes]		// pointer to password data
													  );
		success = (ret == noErr);
		if (!success) {
			//XXX localize me!
			NSLog(@"could not change password in keychain for account %@ on service %@: SecKeychainItemModifyAttributesAndData returned %li", account, service, (long)ret);
		}
	}

	//Cleanup
	if (itemRef) CFRelease(itemRef);
	
	return success;
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
	if (itemRef) CFRelease(itemRef);
	return ret == noErr;
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
    
	if (KCFindFirstItem(keychain, NULL, &grepstate, &item)==noErr) {  
		do {
			NSString    *server = nil;
			
			data = OWKCGetItemAttribute(item, kSecLabelItemAttr);
			if (data && [data bytes]) {
				server = [NSString stringWithUTF8String:[data bytes]];
			}
			
			if ([key isEqualToString:server]) {
				NSString    *username;
				NSString    *password;
				
				data = OWKCGetItemAttribute(item, kSecAccountItemAttr);
				if (data && [data bytes]) {
					username = [NSString stringWithUTF8String:[data bytes]];
				} else {
					username = @"";
				}
				
				if ((SecKeychainItemCopyContent(item, NULL, NULL, &length, &itemData) == noErr) &&
				   (itemData) && 
				   (length > 0)) {
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
		} while ( KCFindNextItem(grepstate, &item)==noErr);
		
		KCReleaseSearch(&grepstate);
	}
    
	CFRelease(keychain);
    return result;   
}

@end
