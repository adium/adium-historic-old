/*
 *  AITigerCompatibility.h
 *  AIUtilities.framework
 *
 *  Created by David Smith on 10/28/07.
 *  Copyright 2007 The Adium Team. All rights reserved.
 *
 */
#ifndef AITigerCompatibility

#	define AITigerCompatibility

#	import <AvailabilityMacros.h>

#	if !MAC_OS_X_VERSION_10_5 || MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED

#		define NS_REQUIRES_NIL_TERMINATION

#		if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#		else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#		endif

#		define NSIntegerMax    LONG_MAX
#		define NSIntegerMin    LONG_MIN
#		define NSUIntegerMax   ULONG_MAX

#		define NSINTEGER_DEFINED 1

#		define NSDownloadsDirectory 15

#		define NSCellHitContentArea 1 << 0

#	else

#		if !defined(NS_REQUIRES_NIL_TERMINATION)
#			define NS_REQUIRES_NIL_TERMINATION __attribute__((sentinel))
#		endif

#	endif //MAC_OS_X_VERSION_10_5

#endif //AITigerCompatibility
