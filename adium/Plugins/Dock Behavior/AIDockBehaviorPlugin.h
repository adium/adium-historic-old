//
//  AIDockBehaviorPreferencesPlugin.h
//  Adium
//
//  Created by Colin Barrett on Tue Jan 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface AIDockBehaviorPlugin : AIPlugin {

}

- (void)installPlugin;
- (void)messageIn:(id)anObject;

@end