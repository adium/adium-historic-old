//
//  IOConsolePlugin.h
//  Adium
//
//  Created by David Smith on 12/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>
#import <Adium/AIContentControllerProtocol.h>
#include "IoState.h"

@interface IOConsolePlugin : AIPlugin <AIContentFilter> {
	IoState *s;

}

- (void) runIOString:(NSString *)string;

@end
