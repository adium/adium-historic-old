//
//  NEHGrowlPlugin.h
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//

@interface NEHGrowlPlugin : AIPlugin {
	NSDictionary	*events;
	BOOL			 showWhileAway;
}

- (void)handleEvent:(NSNotification*)notification;
- (void)preferencesChanged:(NSNotification*)notification;
@end
