//
//  AIDockAccountStatusPlugin.h
//  Adium
//
//  Created by Adam Iser on Fri Apr 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface AIDockAccountStatusPlugin : AIPlugin {
    AIIconState			*onlineState;
    AIIconState			*awayState;
    AIIconState			*idleState;
    AIIconState			*connectingState;
    
}

@end
