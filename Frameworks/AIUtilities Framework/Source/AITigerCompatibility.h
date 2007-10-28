/*
 *  AITigerCompatibility.h
 *  AIUtilities.framework
 *
 *  Created by David Smith on 10/28/07.
 *  Copyright 2007 The Adium Team. All rights reserved.
 *
 */

#import <AvailabilityMacros.h>

#ifndef MAC_OS_X_VERSION_10_5

#define NS_REQUIRES_NIL_TERMINATION

#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif

#define NSIntegerMax    LONG_MAX
#define NSIntegerMin    LONG_MIN
#define NSUIntegerMax   ULONG_MAX

#define NSINTEGER_DEFINED 1

#endif //MAC_OS_X_VERSION_10_5