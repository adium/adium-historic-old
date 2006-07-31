/*
 *  AIDebugControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import "AIControllerProtocol.h"

@protocol AIDebugController <AIController>
#ifdef DEBUG_BUILD
	- (NSArray *)debugLogArray;
	- (void)clearDebugLogArray;
#endif
@end
