//
//  NEHGrowlPlugin.h
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//

@interface NEHGrowlPlugin : AIPlugin {
	NSDictionary * events;
}

- (void)handleEvent:(NSNotification*)notification;
@end
