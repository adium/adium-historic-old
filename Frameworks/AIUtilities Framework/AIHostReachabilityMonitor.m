//
//  AIHostReachabilityMonitor.m
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIHostReachabilityMonitor.h"
#import <SystemConfiguration/SystemConfiguration.h>

static AIHostReachabilityMonitor *singleton = nil;

@interface AIHostReachabilityMonitor (PRIVATE)

- (SCNetworkReachabilityRef)scheduledReachabilityCheckForHost:(NSString *)nodename;

@end

@implementation AIHostReachabilityMonitor

#pragma mark Shared instance management

+ (void)initialize
{
	if(!singleton)
		singleton = [[AIHostReachabilityMonitor alloc] init];
}

+ (id)defaultMonitor
{
	return singleton;
}

#pragma mark -
#pragma mark Birth and death

- (id)init
{
	if((self = [super init])) {
		hostAndObserverListLock = [[NSLock alloc] init];

		[hostAndObserverListLock lock];
		hosts          = [[NSMutableArray alloc] init];
		observers      = [[NSMutableArray alloc] init];
		reachabilities = [[NSMutableArray alloc] init];
		[hostAndObserverListLock unlock];
	}
	return self;
}

- (void)dealloc
{
	[hostAndObserverListLock lock];
	[hosts          release]; hosts          = nil;
	[observers      release]; observers      = nil;
	[reachabilities release]; reachabilities = nil;
	[hostAndObserverListLock unlock];

	[hostAndObserverListLock release];

	[super dealloc];
}

#pragma mark -
#pragma mark Observer management

- (void)addObserver:(id <AIHostReachabilityObserver>)newObserver forHost:(NSString *)host
{
	NSParameterAssert(host != nil);
	NSParameterAssert(newObserver != nil);

	NSString *hostCopy = [host copy];

	[hostAndObserverListLock lock];
	[hosts          addObject:hostCopy];
	[observers      addObject:newObserver];
	[reachabilities addObject:(id)[self scheduledReachabilityCheckForHost:host]];
	[hostAndObserverListLock unlock];

	[hostCopy release];
}
- (void)removeObserver:(id <AIHostReachabilityObserver>)newObserver forHost:(NSString *)host
{
	//nil cannot observe, so it must not be in the list.
	if(!newObserver) return;

	[hostAndObserverListLock lock];

	unsigned numObservers = [observers count];
	for(unsigned i = 0; i < numObservers; ) {
		BOOL removed = NO;
		if(newObserver == [observers objectAtIndex:i]) {
			if((!host) || (host == [hosts objectAtIndex:i])) {
				[hosts          removeObjectAtIndex:i];
				[observers      removeObjectAtIndex:i];
				[reachabilities removeObjectAtIndex:i];
				removed = YES;
			}
		}
		i += !removed;
	}

	[hostAndObserverListLock unlock];
}

#pragma mark -
#pragma mark Reachability monitoring

- (void)gotNetworkChangedToReachable:(BOOL)isReachable byReachability:(SCNetworkReachabilityRef)reachability
{
	[hostAndObserverListLock lock];

	unsigned i = [reachabilities indexOfObjectIdenticalTo:(id)reachability];
	NSString *host = [hosts objectAtIndex:i];
	id <AIHostReachabilityObserver> observer = [observers objectAtIndex:i];

	if(isReachable) [observer hostReachabilityMonitor:self hostIsReachable:host];
	else            [observer hostReachabilityMonitor:self hostIsNotReachable:host];

	[hostAndObserverListLock unlock];
}

static void hostReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
	BOOL reachable = ((flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired));
	
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

	AIHostReachabilityMonitor *self = info;
	[self gotNetworkChangedToReachable:reachable byReachability:target];
}

- (SCNetworkReachabilityRef)scheduledReachabilityCheckForHost:(NSString *)nodename
{
	SCNetworkReachabilityRef		reachabilityRef;
	SCNetworkReachabilityContext	reachabilityContext = {
		.version         = 0,
		.info            = self,
		.retain          = CFRetain,
		.release         = CFRelease,
		.copyDescription = CFCopyDescription,
	};
	
	reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,
														  [nodename UTF8String]);
	
	//Add it to the run loop so we will receive the notifications
	SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef,
											 CFRunLoopGetCurrent(),
											 kCFRunLoopDefaultMode);
	
	//Configure our callback
	SCNetworkReachabilitySetCallback(reachabilityRef, 
									 hostReachabilityChangedCallback, 
									 &reachabilityContext);

	return (SCNetworkReachabilityRef)[(NSObject *)reachabilityRef autorelease];
}

@end
