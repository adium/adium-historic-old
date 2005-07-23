//
//  AIDockBadger.h
//  Adium
//
//  Created by David Smith on 7/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>

@class AIIconState;

@protocol AIChatObserver;

@interface AIDockBadger : AIPlugin <AIChatObserver> {
    NSMutableArray				*overlayObjectsArray;
    AIIconState					*overlayState;
	
    BOOL	showStatus;
    BOOL	showContent;
    BOOL	overlayPosition;
}

@end
