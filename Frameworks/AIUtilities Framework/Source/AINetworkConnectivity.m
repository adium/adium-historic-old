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
 */
 
#import "AINetworkConnectivity.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define	GENERIC_REACHABILITY_CHECK	"www.google.com"
#define	CONNECTIVITY_DEBUG			FALSE

@implementation AINetworkConnectivity

static void networkReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info);
static BOOL _networkIsReachableWithFlags(SCNetworkConnectionFlags flags);
static SCNetworkReachabilityRef		reachabilityRef = nil;

//
+ (void)load
{
	SCNetworkReachabilityContext	reachabilityContext = {
		.version = 0,
		.info = NULL,
		.retain = NULL,
		.release = NULL,
		.copyDescription = NULL,
	};
	
	reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, GENERIC_REACHABILITY_CHECK);
	
	//Configure our callback
	SCNetworkReachabilitySetCallback (reachabilityRef, 
									  networkReachabilityChangedCallback, 
									  &reachabilityContext);
	
	//Add it to the run loop so we will receive the notifications
	SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef,
											 CFRunLoopGetCurrent(),
											 kCFRunLoopDefaultMode);
}

//Return the current state of our network reachability
+ (BOOL)networkIsReachable
{
	SCNetworkConnectionFlags flags;
	SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
	
	return(_networkIsReachableWithFlags(flags));
}

//
static void networkReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
#if CONNECTIVITY_DEBUG
    NSLog(@"*** networkReachabilityChanged %c%c%c%c%c%c%c \n",
		  (flags & kSCNetworkFlagsTransientConnection)  ? 't' : '-',
		  (flags & kSCNetworkFlagsReachable)            ? 'r' : '-',
		  (flags & kSCNetworkFlagsConnectionRequired)   ? 'c' : '-',
		  (flags & kSCNetworkFlagsConnectionAutomatic)  ? 'C' : '-',
		  (flags & kSCNetworkFlagsInterventionRequired) ? 'i' : '-',
		  (flags & kSCNetworkFlagsIsLocalAddress)       ? 'l' : '-',
		  (flags & kSCNetworkFlagsIsDirect)             ? 'd' : '-');
#endif

	[[NSNotificationCenter defaultCenter] postNotificationName:AINetwork_ConnectivityChanged
														object:[NSNumber numberWithBool:_networkIsReachableWithFlags(flags)]];
}

//A network is reachable if kSCNetworkFlagsReachable is set, unless a non-automatic connection is required.
static BOOL _networkIsReachableWithFlags(SCNetworkConnectionFlags flags)
{
	return((flags & kSCNetworkFlagsReachable) &&
		   (!(flags & kSCNetworkFlagsConnectionRequired) || (flags & kSCNetworkFlagsConnectionAutomatic)));
}

@end
