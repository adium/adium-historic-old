//
//  NEHGrowlPlugin.h
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//

@interface NEHGrowlPlugin : AIPlugin <AIActionHandler> {
	BOOL			 showWhileAway;
}

- (void)growlLaunched:(void *)context;
- (void)handleEvent:(NSNotification*)notification;
@end
