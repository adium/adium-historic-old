//
//  ESDebugController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/27/04.
//

#import <Cocoa/Cocoa.h>

@interface ESDebugController : NSObject {
	IBOutlet	AIAdium		*adium;
	NSMutableArray			*debugLogArray;
}

- (void)initController;
- (void)closeController;

#ifdef DEBUG_BUILD
	+ (ESDebugController *)sharedDebugController;
	- (NSArray *)debugLogArray;
#endif

@end
