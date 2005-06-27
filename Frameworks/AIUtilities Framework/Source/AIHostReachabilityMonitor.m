//
//  AIHostReachabilityMonitor.m
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-11.
//

#import "AIHostReachabilityMonitor.h"
#import <SystemConfiguration/SystemConfiguration.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>

#define CONNECTIVITY_DEBUG TRUE

static AIHostReachabilityMonitor *singleton = nil;

@interface AIHostReachabilityMonitor (PRIVATE)
- (void)gotReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef forHost:(NSString *)host observer:(id)observer;
- (void)scheduleReachabilityCheckForHost:(NSString *)nodename observer:(id)observer;
- (void)removeUnconfiguredHost:(NSString *)host observer:(id)observer;

@end

@implementation AIHostReachabilityMonitor

#pragma mark Shared instance management

+ (void)initialize
{
	if (!singleton)
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
	if ((self = [super init])) {
		hostAndObserverListLock = [[NSLock alloc] init];

		[hostAndObserverListLock lock];
		hosts          = [[NSMutableArray alloc] init];
		observers      = [[NSMutableArray alloc] init];
		reachabilities = [[NSMutableArray alloc] init];
		
		unconfiguredHostsAndObservers = [[NSMutableSet alloc] init];
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
	
	[unconfiguredHostsAndObservers release]; unconfiguredHostsAndObservers = nil;
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

	NSString	*hostCopy = [host copy];
	[self scheduleReachabilityCheckForHost:hostCopy
								   observer:newObserver];
	[hostCopy release];
}
- (void)removeObserver:(id <AIHostReachabilityObserver>)newObserver forHost:(NSString *)host
{
	//nil cannot observe, so it must not be in the list.
	if (!newObserver) return;

	[hostAndObserverListLock lock];

	unsigned numObservers = [observers count];
	for (unsigned i = 0; i < numObservers; ) {
		BOOL removed = NO;
		if (newObserver == [observers objectAtIndex:i]) {
			if ((!host) || (host == [hosts objectAtIndex:i])) {
				[hosts          removeObjectAtIndex:i];
				[observers      removeObjectAtIndex:i];
				[reachabilities removeObjectAtIndex:i];
				
				[self removeUnconfiguredHost:host
									observer:newObserver];
				
				removed = YES;
				--numObservers;
			}
		}
		i += !removed;
	}

	[hostAndObserverListLock unlock];
}

/*
 * @brief Add an unconfigured host and observer to unconfiguredHostsAndObservers *
 */
- (void)addUnconfiguredHost:(NSString *)host observer:(id)observer
{
	[hostAndObserverListLock lock];

	[unconfiguredHostsAndObservers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		observer, @"observer",
		host, @"host",
		nil]];
	[hostAndObserverListLock unlock];
	
#if CONNECTIVITY_DEBUG
	NSLog(@"Could not add a reachability monitor for %@.  We need to set up local IP address monitoring to try again later.",
		  host);
#endif
}

/*
 * @brief Remove an unconfigured host and observer from unconfiguredHostsAndObservers
 *
 * Must be called with the hostAndObserverListLock already obtained.
 */
- (void)removeUnconfiguredHost:(NSString *)host observer:(id)observer
{
	[unconfiguredHostsAndObservers removeObject:[NSDictionary dictionaryWithObjectsAndKeys:
		observer, @"observer",
		host, @"host",
		nil]];
}


#pragma mark -
#pragma mark Reachability monitoring

/*
 * @brief A host's reachability changed
 *
 * @param reachability The SCNetworkReachabilityRef for the host which changed
 * @param isReachable YES if the host is now reachable; NO if it is not reachable
 */
- (void)reachability:(SCNetworkReachabilityRef)reachability changedToReachable:(BOOL)isReachable
{
	[hostAndObserverListLock lock];

	unsigned i = [reachabilities indexOfObjectIdenticalTo:(id)reachability];
	NSString *host = [hosts objectAtIndex:i];
	id <AIHostReachabilityObserver> observer = [observers objectAtIndex:i];

	if (isReachable) {
		[observer hostReachabilityMonitor:self hostIsReachable:host];
	} else {
		[observer hostReachabilityMonitor:self hostIsNotReachable:host];
	}

	[hostAndObserverListLock unlock];
}

/*
 * @brief Callback for changes in a host's reachability (SCNetworkReachability)
 */
static void hostReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
	BOOL reachable = ((flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired));

#if CONNECTIVITY_DEBUG
	NSLog(@"*** hostReachabilityChangedCallback got flags: %c%c%c%c%c%c%c \n",  
 	      (flags & kSCNetworkFlagsTransientConnection)  ? 't' : '-',  
 	      (flags & kSCNetworkFlagsReachable)            ? 'r' : '-',  
 	      (flags & kSCNetworkFlagsConnectionRequired)   ? 'c' : '-',  
 	      (flags & kSCNetworkFlagsConnectionAutomatic)  ? 'C' : '-',  
 	      (flags & kSCNetworkFlagsInterventionRequired) ? 'i' : '-',  
 	      (flags & kSCNetworkFlagsIsLocalAddress)       ? 'l' : '-',  
 	      (flags & kSCNetworkFlagsIsDirect)             ? 'd' : '-');
#endif

	AIHostReachabilityMonitor *self = info;
	[self reachability:target changedToReachable:reachable];
}

/*
 * @brief Callbacak for resolution of a host's name to an IP (CFHost)
 */
static void hostResolvedCallback(CFHostRef theHost, CFHostInfoType typeInfo,  const CFStreamError *error, void *info)
{
	NSDictionary				*infoDict = info;
	AIHostReachabilityMonitor	*self = [infoDict objectForKey:@"self"];
	id							observer = [infoDict objectForKey:@"observer"];
	NSString					*host = [infoDict objectForKey:@"host"];

	CFArrayRef addresses = CFHostGetAddressing(theHost, NULL);
	if (addresses && CFArrayGetCount(addresses)) {
		SCNetworkReachabilityRef		reachabilityRef;
		SCNetworkReachabilityContext	reachabilityContext = {
			.version         = 0,
			.info            = self,
			.retain          = CFRetain,
			.release         = CFRelease,
			.copyDescription = CFCopyDescription,
		};
		struct sockaddr_in	localAddr;
		struct sockaddr		*remoteAddr;

		/* Create a reachability reference pair with localhost and the remote host */
		
		//Our local address is 127.0.0.1
		bzero(&localAddr, sizeof(localAddr));
		localAddr.sin_len = sizeof(localAddr);
		localAddr.sin_family = AF_INET;
		inet_aton("127.0.0.1", &localAddr.sin_addr);
		
		//CFHostGetAddressing returns a CFArrayRef of CFDataRefs which wrap struct sockaddr
        CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, 0);
        remoteAddr = (struct sockaddr *)CFDataGetBytePtr(saData);
		
		//Create the pair
		reachabilityRef = SCNetworkReachabilityCreateWithAddressPair(NULL, 
																	 (struct sockaddr *)&localAddr, 
																	 remoteAddr);
		
		//Add it to the run loop so we will receive the notifications
		SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef,
												 CFRunLoopGetCurrent(),
												 kCFRunLoopDefaultMode);
		
		//Configure our callback
		SCNetworkReachabilitySetCallback(reachabilityRef, 
										 hostReachabilityChangedCallback, 
										 &reachabilityContext);
		
		//Note that we succesfully configured for reachability notifications
		[self gotReachabilityRef:(SCNetworkReachabilityRef)[(NSObject *)reachabilityRef autorelease]
						 forHost:host
						observer:observer];
	} else {
		/* We were not able to resolve the host name to an IP address.  This is most likely because we have no
		 * Internet connection or because the user is attempting to connect to MSN.
		 *
		 * Add to unconfiguredHostsAndObservers so we can try configuring again later.
		 */
		[self addUnconfiguredHost:host
						 observer:observer];

#if CONNECTIVITY_DEBUG
		NSLog(@"No addresses found for %@.", host);
#endif
	}
}

/*
 * @brief We obtained an SCNetweorkReachabilityRef for a host/observer pair
 *
 * We can now effectively monitor connectivity between us and the host.
 *
 * Add these three objects to our hosts, observers, and reachabilities arrays respectively so we can determine the
 * host and observer given the reachabilityRef in hostReachabilityChangedCallback() above.
 *
 * Remove the host/observer pair from the unconfigured dictionary.
 */
- (void)gotReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef forHost:(NSString *)host observer:(id)observer
{
	//Add to our arrays for tracking
	[hostAndObserverListLock lock];
	
	[hosts          addObject:host];
	[observers      addObject:observer];
	[reachabilities addObject:(id)reachabilityRef];
	
	//Remove from our unconfigured array
	[self removeUnconfiguredHost:host
						observer:observer];
	
	[hostAndObserverListLock unlock];

#if CONNECTIVITY_DEBUG
	NSLog(@"Obtained reachability ref %@ for %@ (%@).",reachabilityRef, host, observer);
#endif
}

/*
 * @brief Schedule a reachability check for a host, with an observer
 *
 * This method begins the process of scheduling the reachability check.  It actually creates a CFHost to schedules
 * an asynchronous IP lookup for nodename.  hostResolvedCallback() will be called when it succeeds or fails.
 *
 * @param nodename The name such as "www.adiumxtras.com"
 * @param observer The observer which will be notified when the reachability changes
 */
- (void)scheduleReachabilityCheckForHost:(NSString *)nodename observer:(id)observer
{
	//Resolve the remote host domain name to an IP asynchronously
	CFHostClientContext	hostContext = {
		.version		 = 0,
		.info			 = [NSDictionary dictionaryWithObjectsAndKeys:
							self, @"self",
							nodename, @"host",
							observer, @"observer",
							nil],
		.retain			 = CFRetain,
		.release		 = CFRelease,
		.copyDescription = CFCopyDescription,
	};
	CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault,
										  (CFStringRef)nodename);
	CFHostSetClient(host,
					hostResolvedCallback,
					&hostContext);
	CFHostScheduleWithRunLoop(host,
							  CFRunLoopGetCurrent(),
							  kCFRunLoopDefaultMode);
	CFHostStartInfoResolution(host,
							  kCFHostAddresses,
							  NULL);	
}

@end
