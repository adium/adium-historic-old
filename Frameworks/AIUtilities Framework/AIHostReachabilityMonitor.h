//
//  AIHostReachabilityMonitor.h
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIHostReachabilityMonitor;

@protocol AIHostReachabilityObserver <NSObject>

- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsReachable:(NSString *)host;
- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsNotReachable:(NSString *)host;

@end

@interface AIHostReachabilityMonitor: NSObject
{
	NSMutableArray *hosts;
	NSMutableArray *observers;
	NSMutableArray *reachabilities;
	NSLock *hostAndObserverListLock;
}

/*!
 *	@brief	Returns a shared instance, usable for most purposes.
 *	@return A shared <tt>AIHostReachabilityMonitor</tt> instance.
 */
+ (id)defaultMonitor;

#pragma mark -

/*!
 *	@brief	Begins observing a host's reachability for an object.
 */
- (void)addObserver:(id <AIHostReachabilityObserver>)newObserver forHost:(NSString *)host;
/*!
 *	@brief	Stops an object's observation of a host's reachability.
 *
 *	When <tt>host</tt> is non-nil, stops observing that host's reachability for the given observer.
 *	When <tt>host</tt> is nil, stops observing all hosts' reachability for the given observer.
 */
- (void)removeObserver:(id <AIHostReachabilityObserver>)observer forHost:(NSString *)host;

@end
