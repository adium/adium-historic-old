//
//  ESAccountNetworkConnectivityPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 8/10/04.
//

#import "ESAccountNetworkConnectivityPlugin.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define	GENERIC_REACHABILITY_CHECK	"www.google.com"

@implementation ESAccountNetworkConnectivityPlugin

static OSStatus CreateIPAddressListChangeCallbackSCF(SCDynamicStoreCallBack callback,
													 void *contextPtr,
													 SCDynamicStoreRef *storeRef,
													 CFRunLoopSourceRef *sourceRef);
static void localIPsChangedCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

static NSMutableSet	*accountsToConnect;

- (void)installPlugin
{
	SCDynamicStoreRef	storeRef = nil;
	CFRunLoopSourceRef	sourceRef = nil;
	
	//Create the CFRunLoopSourceRef we will want to add to our run loop to have
	//localIPsChangedCallback() called when the IP list changes
	CreateIPAddressListChangeCallbackSCF(localIPsChangedCallback, 
										 nil,
										 &storeRef,
										 &sourceRef);
	
	//Add it to the run loop so we will receive the notifications
	CFRunLoopAddSource(CFRunLoopGetCurrent(),
					   sourceRef,
					   kCFRunLoopDefaultMode);

	accountsToConnect = [[NSMutableSet alloc] init];
	
	//Register our observers
    [[adium contactController] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
	[accountsToConnect release]; accountsToConnect = nil;
}

static BOOL checkReachabilityForHost(const char *host)
{
	
	SCNetworkConnectionFlags	status;
	BOOL						genericReachability = NO;
	
	if (SCNetworkCheckReachabilityByName(host, &status)){
		genericReachability = (status & kSCNetworkFlagsReachable);
	}
	
	return genericReachability;
}

static BOOL checkGenericReachability()
{
	return checkReachabilityForHost(GENERIC_REACHABILITY_CHECK);
}

static void localIPsChangedCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
	BOOL			genericReachability = checkGenericReachability();
	NSEnumerator	*enumerator = [[[[AIObject sharedAdiumInstance] accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while (account = [enumerator nextObject]){
		const char *customServerToCheckForReachability = [account customServerToCheckForReachability];
		BOOL		reachability = (customServerToCheckForReachability ?
									checkReachabilityForHost(customServerToCheckForReachability) :
									genericReachability);
		
		//If we are now online and are waiting to connect this account, do it if the account hasn't already
		//been taken care of.
		if (reachability){
			if ([accountsToConnect containsObject:account] &&
				![account integerStatusObjectForKey:@"Online"] &&
				![account integerStatusObjectForKey:@"Connecting"]){
				
				[account setPreference:[NSNumber numberWithBool:YES] 
								forKey:@"Online"
								 group:GROUP_ACCOUNT_STATUS];	
			}
		}else{
			if (([account integerStatusObjectForKey:@"Online"] ||
				[account integerStatusObjectForKey:@"Connecting"]) &&
				![account integerStatusObjectForKey:@"Disconnecting"]){
				
				[account setPreference:[NSNumber numberWithBool:NO] 
								forKey:@"Online"
								 group:GROUP_ACCOUNT_STATUS];
				[accountsToConnect addObject:account];
			}			
		}
	}
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{ 
	if ([inObject isKindOfClass:[AIAccount class]]){
		if ([inModifiedKeys containsObject:@"Online"] &&
			[inObject integerStatusObjectForKey:@"Online"]){
			
			//When an account successfully goes online, take it off our list of accounts to connect
			//so that we won't reconnect it after the user disconnects it manually
			[accountsToConnect removeObject:inObject];
		}
	}
	
	return nil;
}

/* CreateIPAddressListChangeCallbackSCF() is from Apple's
"Living in a Dynamic TCP/IP Environment, available at
http://developer.apple.com/technotes/tn/tn1145.html */

//Error Handling  ------------------------------------------------------------------------------------------------------
#pragma mark Error Handling

// Error Handling
// --------------
// SCF returns errors in two ways:
//
// o The function result is usually set to something
//   generic (like NULL or false) to indicate an error.
//
// o There is a call, SCError, that returns the error
//   code for the most recent function.  These error codes
//   are not in the OSStatus domain.
//
// We deal with this using two functions, MoreSCError
// and MoreSCErrorBoolean.  Both of these take a generic
// failure indicator (a pointer or a Boolean) and, if
// that indicates an error, they call SCError to get the
// real error code.  They also act as a bottleneck for
// mapping SC errors into the OSStatus domain, although
// I don't do that in this simple implementation.
//
// Note that I could have eliminated the failure indicator
// parameter and just called SCError but I'm worried
// about SCF returning an error indicator without setting
// the SCError.  There's no justification for this worry
// other than general paranoia (I know of no examples where
// this happens),

static OSStatus MoreSCErrorBoolean(Boolean success)
{
    OSStatus err;
    int scErr;
	
    err = noErr;
    if ( ! success ) {
        scErr = SCError();
        if (scErr == kSCStatusOK) {
            scErr = kSCStatusFailed;
        }
        // Return an SCF error directly as an OSStatus.
        // That's a little cheesy.  In a real program
        // you might want to do some mapping from SCF
        // errors to a range within the OSStatus range.
        err = scErr;
    }
    return err;
}

static OSStatus MoreSCError(const void *value)
{
    return MoreSCErrorBoolean(value != NULL);
}

static OSStatus CFQError(CFTypeRef cf)
// Maps Core Foundation error indications (such as they
// are) to the OSStatus domain.
{
    OSStatus err;
	
    err = noErr;
    if (cf == NULL) {
        err = coreFoundationUnknownErr;
    }
    return err;
}

static void CFQRelease(CFTypeRef cf)
// A version of CFRelease that's tolerant of NULL.
{
    if (cf != NULL) {
        CFRelease(cf);
    }
}

//CreateIPAddressListChangeCallbackSCF ----------------------------------------------------------------------------------
#pragma mark CreateIPAddressListChangeCallbackSCF()

static OSStatus CreateIPAddressListChangeCallbackSCF(SCDynamicStoreCallBack callback,
													 void *contextPtr,
													 SCDynamicStoreRef *storeRef,
													 CFRunLoopSourceRef *sourceRef)
// Create a SCF dynamic store reference and a
// corresponding CFRunLoop source.  If you add the
// run loop source to your run loop then the supplied
// callback function will be called when local IP
// address list changes.
{
    OSStatus                err;
    SCDynamicStoreContext   context = {0, NULL, NULL, NULL, NULL};
    SCDynamicStoreRef       ref;
    CFStringRef             pattern;
    CFArrayRef              patternList;
    CFRunLoopSourceRef      rls;
	
    assert(callback   != NULL);
    assert( storeRef  != NULL);
    assert(*storeRef  == NULL);
    assert( sourceRef != NULL);
    assert(*sourceRef == NULL);
	
    ref = NULL;
    pattern = NULL;
    patternList = NULL;
    rls = NULL;
	
    // Create a connection to the dynamic store, then create
    // a search pattern that finds all IPv4 entities.
    // The pattern is "State:/Network/Service/[^/]+/IPv4".
	
    context.info = contextPtr;
    ref = SCDynamicStoreCreate( NULL,
                                CFSTR("AddIPAddressListChangeCallbackSCF"),
                                callback,
                                &context);
    err = MoreSCError(ref);
    if (err == noErr) {
        pattern = SCDynamicStoreKeyCreateNetworkServiceEntity(
															  NULL,
															  kSCDynamicStoreDomainState,
															  kSCCompAnyRegex,
															  kSCEntNetIPv4);
        err = MoreSCError(pattern);
    }
	
    // Create a pattern list containing just one pattern,
    // then tell SCF that we want to watch changes in keys
    // that match that pattern list, then create our run loop
    // source.
	
    if (err == noErr) {
        patternList = CFArrayCreate(NULL,
                                    (const void **) &pattern, 1,
                                    &kCFTypeArrayCallBacks);
        err = CFQError(patternList);
    }
    if (err == noErr) {
        err = MoreSCErrorBoolean(
								 SCDynamicStoreSetNotificationKeys(
																   ref,
																   NULL,
																   patternList)
								 );
    }
    if (err == noErr) {
        rls = SCDynamicStoreCreateRunLoopSource(NULL, ref, 0);
        err = MoreSCError(rls);
    }
	
    // Clean up.
	
    CFQRelease(pattern);
    CFQRelease(patternList);
    if (err != noErr) {
        CFQRelease(ref);
        ref = NULL;
    }
    *storeRef = ref;
    *sourceRef = rls;
	
    assert( (err == noErr) == (*storeRef  != NULL) );
    assert( (err == noErr) == (*sourceRef != NULL) );
	
    return err;
}



@end
