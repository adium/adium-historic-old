//
//  AIExpandedRecursiveLock.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/20/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

/*!
 * @class AIExpandedRecursiveLock
 * @brief <tt>NSRecursiveLock</tt> subclass allowing non-locking and thread-sensitive tests of lockedness
 * 
 * This <tt>NSRecursiveLock</tt> subclass adds two methods.  The lock can be tested for being unlocked without actually obtaining the lock (unlike tryLock, which obtains the lock), and it may be immediately and fully unlocked by a thread (which can obtain the lock multiple simultaneous times).
 */
@interface AIExpandedRecursiveLock : NSRecursiveLock {
	int	locksByCurrentOwner;
}

/*!
 * @brief Check whether the <tt>AIExpandedRecursiveLock</tt> is locked
 *
 * Check the lockedness of the <tt>AIExpandedRecursiveLock</tt> without attempting to obtain the lock.  Returns YES if the recursiveLock is completely unlocked -- that is, it is not locked by any thread including the calling one. This may be needed because -(BOOL)tryLock will return YES if the lock is locked by the current thread (since this is an <tt>NSRecursiveLock</tt> subclass). 
 * @result	YES if the lock is completely unlocked; NO if the lock is locked by any thread.
 */ 
- (BOOL)isUnlocked;

/*!
 * @brief Remove all locks held by the current owner
 *
 * A thread may have multiple locks on the same <tt>AIExpandedRecursiveLock</tt>. This removes all of them immediately.
 */ 
- (void)completelyUnlock;

@end
