//
//  RAFjoscarDebugController.h
//  Adium
//
//  Created by Augie Fackler on 12/28/05.
//

#import <Adium/AIObject.h>

#define	KEY_JOSCAR_DEBUG_WRITE_LOG		@"Write joscar Debug Log"
#define	GROUP_JOSCAR_DEBUG				@"joscar Debug Group"

@interface RAFjoscarDebugController : AIObject {
	NSMutableArray			*debugLogArray;
	NSFileHandle			*debugLogFile;
}

#ifdef DEBUG_BUILD
+ (RAFjoscarDebugController *)sharedDebugController;
- (void)activateDebugController;
- (NSArray *)debugLogArray;
- (NSFileHandle *)debugLogFile;
- (void)clearDebugLogArray;
#endif

@end
