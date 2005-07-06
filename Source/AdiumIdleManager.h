//
//  AdiumIdleManager.h
//  Adium
//
//  Created by Evan Schoenberg on 7/5/05.
//

#import <Adium/AIObject.h>

@interface AdiumIdleManager : AIObject {
	BOOL					machineIsIdle;
	double					lastSeenIdle;
	NSTimer					*idleTimer;	
}

@end
