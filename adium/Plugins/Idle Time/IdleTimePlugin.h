//
//  Idle Time.h
//  Adium
//
//  Created by Greg Smith on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@protocol AIMiniToolbarItemDelegate;

@class IdleTimeWindowController;

@interface AIIdleTimePlugin : AIPlugin <AIMiniToolbarItemDelegate> {
    NSTimer	*idleTimer;
    NSTimer	*unidleTimer;
}
- (IBAction)showIdleTimeWindow:(id)sender;
- (void)installIdleTimer;
- (void)installUnidleTimer;
- (void)removeTimer:(NSTimer *)timer;
- (void)goIdle;
- (void)unIdle;
@end