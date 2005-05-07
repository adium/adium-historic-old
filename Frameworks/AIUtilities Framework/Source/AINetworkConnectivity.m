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
 
 + (BOOL)networkIsReachable always reflects the last network reachability state retrieved by AINetworkCnonnectivity.
 The notification should be relied upon whenever possible; this method exists primarily to assist in debugging.
 */
 
#import "AINetworkConnectivity.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define	GENERIC_REACHABILITY_CHECK	"www.google.com"
#define	AGGREGATE_INTERVAL			3.0
#define	CONNECTIVITY_DEBUG			FALSE

@interface AINetworkConnectivity (PRIVATE)
+ (void)scheduleReachabilityCheckFor:(const char *)nodename context:(void *)context;
@end

@implementation AINetworkConnectivity

static void networkReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info);

static NSTimer								*aggregatedChangesTimer = nil;
static BOOL									networkIsReachable = NO;

+ (void)load
{
	//Schedule our generic reachability check which will be used for most accounts
	//This is triggered as soon as it is added to the run loop, which means our networkIsReachable flag will be set.
	[[AINetworkConnectivity class] scheduleReachabilityCheckFor:GENERIC_REACHABILITY_CHECK context:nil];
}

#pragma mark -

//Here's where the magic happens.  The timer is called after a clump of network updates culminating in a valid
//network state.  Handle connectivity and post a notification for all the other kids who want to play.
+ (void)aggregatedNetworkReachabilityChanged:(NSTimer *)inTimer
{
#if CONNECTIVITY_DEBUG
	NSLog(@"aggregatedNetworkReachabilityChanged: %u",networkIsReachable);
#endif
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AINetwork_ConnectivityChanged
														object:[NSNumber numberWithBool:networkIsReachable]];
	
	[aggregatedChangesTimer release]; aggregatedChangesTimer = nil;
}

//Return the last state our network reachability testing determined
+ (BOOL)networkIsReachable
{
	return networkIsReachable;
}

static void gotNetworkChangedToReachable(BOOL reachable)
{
	networkIsReachable = reachable;

	//We want to group a set of network changed calls, as we get quite a few 
	//and only the last in the group is at all reliable.
	if (aggregatedChangesTimer){
		[aggregatedChangesTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:AGGREGATE_INTERVAL]];
		
	}else{
		aggregatedChangesTimer = [[NSTimer scheduledTimerWithTimeInterval:AGGREGATE_INTERVAL
																   target:[AINetworkConnectivity class]
																 selector:@selector(aggregatedNetworkReachabilityChanged:)
																 userInfo:nil
																  repeats:NO] retain];
	}

#if CONNECTIVITY_DEBUG
	NSLog(@"gotNetworkChangedToReachable %i",reachable);
#endif
}

//This gets called multiple times with flags = 7 and flags = 0 when the network goes down.  I have no idea why.
//The last call is accurate, so aggregate changes until we hit AGGREGATE_INTERVAL without a change
static void networkReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
	BOOL reachable = ((flags & kSCNetworkFlagsReachable) != 0);

#if CONNECTIVITY_DEBUG
	NSLog(@"*** networkReachabilityChangedCallback is: %i : %i %i %i %i %i %i %i = %i",flags,
		  flags & kSCNetworkFlagsTransientConnection,
		  flags & kSCNetworkFlagsReachable,
		  flags & kSCNetworkFlagsConnectionRequired,
		  flags & kSCNetworkFlagsConnectionAutomatic,
		  flags & kSCNetworkFlagsInterventionRequired,
		  flags & kSCNetworkFlagsIsLocalAddress,
		  flags & kSCNetworkFlagsIsDirect,
		  reachable);
#endif

	gotNetworkChangedToReachable(reachable);
}

// Schedule a check for the nodename (e.g. "www.google.com") with account as contextual information (may be NULL)
+ (void)scheduleReachabilityCheckFor:(const char *)nodename context:(void *)context
{
	SCNetworkReachabilityRef		reachabilityRef;
	SCNetworkReachabilityContext	reachabilityContext = {
		.version = 0,
		.info = context,
		.retain = NULL,
		.release = NULL,
		.copyDescription = NULL,
	};

	reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,
														  nodename);

	//Add it to the run loop so we will receive the notifications
	SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef,
											 CFRunLoopGetCurrent(),
											 kCFRunLoopDefaultMode);
	
	//Configure our callback
	SCNetworkReachabilitySetCallback (reachabilityRef, 
									  networkReachabilityChangedCallback, 
									  &reachabilityContext);
}

@end
