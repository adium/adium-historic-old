//
//  AINetworkConnectivity.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 8/17/04.
//

/*
 AINetworkConnectivity posts the notification AINetwork_ConnectivityChanged when the system's internet connection on any
 available interface goes up or down.  The notification has an NSNumber object of either YES or NO which reflects the
 new connectivity state.  
 
 + (void)refreshReachabilityAndNotify is offerred to immediately refresh reachability, although
 this should not generally be needed (it is used in Adium to force an update when waking from sleep, for example, in case
									  the system doesn't believe that network connectivity was ever lost).
 
 + (BOOL)networkIsReachable always reflects the last network reachability state retrieved by AINetworkCnonnectivity.
 The notification should be relied upon whenever possible; this method exists primarily to assist in debugging.
 */
 
#import "AINetworkConnectivity.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define	GENERIC_REACHABILITY_CHECK	"www.google.com"
#define	AGGREGATE_INTERVAL			3.0

#define	USE_10_3_METHODS_CHECK		[NSApplication isOnPantherOrBetter]

@interface AINetworkConnectivity (PRIVATE)
+ (void)handleConnectivityUsingCheckGenericReachability;

//10.3 and above
+ (void)scheduleReachabilityCheckFor:(const char *)nodename context:(void *)context;
@end

@implementation AINetworkConnectivity

static OSStatus CreateIPAddressListChangeCallbackSCF(SCDynamicStoreCallBack callback,
													 void *contextPtr,
													 SCDynamicStoreRef *storeRef,
													 CFRunLoopSourceRef *sourceRef);
static void localIPsChangedCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);
static void networkReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info);

static AINetworkConnectivity				*myself = nil;
//static NSMutableArray						*customReachabilityRefArray = nil;

static NSTimer								*aggregatedChangesTimer = nil;
static BOOL									networkIsReachable = NO;

+ (void)load
{
	myself = self;
	if (USE_10_3_METHODS_CHECK){
		//Schedule our generic reachability check which will be used for most accounts
		//This is triggered as soon as it is added to the run loop, which is why we do it after doing [self autoConnectAccounts]
		[[AINetworkConnectivity class] scheduleReachabilityCheckFor:GENERIC_REACHABILITY_CHECK context:nil];

	}else{
		//10.2 method - the 10.3 method above is much more reliable.
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
	}
}

//Here's where the magic happens.  The timer is called after a clump of network updates culminating in a valid
//network state.  Handle connectivity and post a notification for all the other kids who want to play.
+ (void)aggregatedNetworkReachabilityChanged:(NSTimer *)inTimer
{
	[[NSNotificationCenter defaultCenter] postNotificationName:AINetwork_ConnectivityChanged
														object:[NSNumber numberWithInt:networkIsReachable]];
	
	[aggregatedChangesTimer release]; aggregatedChangesTimer = nil;
}

//Return the last state our network reachability testing determined
+ (BOOL)networkIsReachable
{
	return networkIsReachable;
}

+ (void)refreshReachabilityAndNotify
{
	[self handleConnectivityUsingCheckGenericReachability];
}

#pragma mark Aggregation and notification
static void gotNetworkChangedToReachable(BOOL reachable)
{
	networkIsReachable = reachable;

	if (aggregatedChangesTimer){
		[aggregatedChangesTimer invalidate]; [aggregatedChangesTimer release]; aggregatedChangesTimer = nil;
	}

	aggregatedChangesTimer = [[NSTimer scheduledTimerWithTimeInterval:AGGREGATE_INTERVAL
															   target:[AINetworkConnectivity class]
															 selector:@selector(aggregatedNetworkReachabilityChanged:)
															 userInfo:nil
															  repeats:NO] retain];
}


#pragma mark 10.3 reachability checking
//10.3 and above callback
//This gets called multiple times with flags = 7 and flags = 0 when the network goes down.  I have no idea why.
//The last call is accurate, so aggregate changes until we hit AGGREGATE_INTERVAL without a change
static void networkReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
	BOOL reachable = (flags & kSCNetworkFlagsReachable);
	
	gotNetworkChangedToReachable(reachable);
}

//10.3 and above: Schedule a check for the nodename (e.g. "www.google.com") with account as contextual information (may be NULL)
+ (void)scheduleReachabilityCheckFor:(const char *)nodename context:(void *)context
{
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(),
																						  nodename);
	SCNetworkReachabilityContext reachabilityContext = { 0, context, NULL, NULL, NULL };
	
	//Add it to the run loop so we will receive the notifications
	SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef,
											 CFRunLoopGetCurrent(),
											 kCFRunLoopDefaultMode);
	
	//Configure our callback
	SCNetworkReachabilitySetCallback (reachabilityRef, 
									  networkReachabilityChangedCallback, 
									  &reachabilityContext);
	
	/*
	//Add it to our array of references if we were passed an account context
	if (account){
		if (!customReachabilityRefArray){
			customReachabilityRefArray = [[NSMutableArray alloc] init];
		}
		[customReachabilityRefArray addObject:(id)reachabilityRef];
	}
	 */
}

#pragma mark 10.2 Reachability Checking
static BOOL checkReachabilityForHost(const char *host)
{
	
	SCNetworkConnectionFlags	status;
	BOOL						reachable = NO;
	
	if (SCNetworkCheckReachabilityByName(host, &status)){
		reachable = (status & kSCNetworkFlagsReachable);
		
		/*
		 NSLog(@"*** %s is %i : %i %i %i %i %i %i",host,status,
			   status & kSCNetworkFlagsTransientConnection,
			   status & kSCNetworkFlagsReachable,
			   status & kSCNetworkFlagsConnectionRequired,
			   status & kSCNetworkFlagsConnectionAutomatic,
			   status & kSCNetworkFlagsInterventionRequired,
			   status & kSCNetworkFlagsIsLocalAddress,
			   status & kSCNetworkFlagsIsDirect);
		 */
	}
	return reachable;
}

static BOOL checkGenericReachability()
{
	return checkReachabilityForHost(GENERIC_REACHABILITY_CHECK);
}

//Using the 10.2 compatible checkGenericReachability(), update all accounts
+ (void)handleConnectivityUsingCheckGenericReachability
{
	BOOL			reachable = checkGenericReachability();
	
	gotNetworkChangedToReachable(reachable);
}

//10.2 callback
static void localIPsChangedCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
	//The IPs changed, but DNS may not be up yet.  Delay 1 second to give the check a higher
	//degree of accuracy.
	[NSTimer scheduledTimerWithTimeInterval:1.0
									 target:[AINetworkConnectivity class]
								   selector:@selector(handleConnectivityUsingCheckGenericReachability)
								   userInfo:nil
									repeats:NO];
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
