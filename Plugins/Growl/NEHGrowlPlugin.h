//
//  NEHGrowlPlugin.h
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//

@interface NEHGrowlPlugin : AIPlugin <AIActionHandler> {
	NSDictionary	*events;
	BOOL			 showWhileAway;
}

- (void)registerAdium:(void*)context;
- (void)handleEvent:(NSNotification*)notification;
- (void)preferencesChanged:(NSNotification*)notification;
@end
