//
//  ESContactAlertsActionColumn.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Aug 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "ESContactAlerts.h"

@interface ESContactAlertsActionColumn : NSTableColumn {
    ESContactAlerts *	instance;
}

- (void)setInstance:(ESContactAlerts *)inInstance;

@end
