//
//  ESExpandedRecursiveLock.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/20/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESExpandedRecursiveLock.h"


@implementation ESExpandedRecursiveLock

- (id)init
{
	[super init];
	locksByCurrentOwner = 0;
	return(self);
}
- (void)lock
{
	[super lock];
	locksByCurrentOwner++;
}

- (void)unlock
{
	[super unlock];
	locksByCurrentOwner--;	
}

- (BOOL)lockBeforeDate:(NSDate *)limit
{
	BOOL obtainedLock;
	
	if(obtainedLock = [super lockBeforeDate:limit]){
		locksByCurrentOwner++;
	}
	
	return(obtainedLock);
}

- (BOOL)tryLock
{
	BOOL obtainedLock;
	
	if(obtainedLock = [super tryLock]){
		locksByCurrentOwner++;
	}
	
	return(obtainedLock);	
}

/*
 Returns YES if the recursiveLock is completely unlocked -- that is, 
 is not locked by any thread including the calling one. This may be needed because -(BOOL)tryLock will return YES
 if the lock is locked by the current thread.
 */
- (BOOL)isUnlocked
{
	return(locksByCurrentOwner == 0);
}

//Relinquish all locks by the present owner
- (void)completelyUnlock
{
	int i;
	int initialNumberOfLocksByCurrentOwner = locksByCurrentOwner;
	
	for (i = 0; i < initialNumberOfLocksByCurrentOwner; i++){
		[self unlock];
	}
}

@end
