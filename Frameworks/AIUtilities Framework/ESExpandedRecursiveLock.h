//
//  ESExpandedRecursiveLock.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/20/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ESExpandedRecursiveLock : NSRecursiveLock {
	int	locksByCurrentOwner;
}

- (BOOL)isUnlocked;
- (void)completelyUnlock;

@end
