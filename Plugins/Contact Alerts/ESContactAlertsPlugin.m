//
//  ESContactAlertsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESContactAlertsPlugin.h"
#import "ESContactAlertsPane.h"
#import "CSNewContactAlertWindowController.h"

@implementation ESContactAlertsPlugin

- (void)installPlugin
{    
	[ESContactAlertsPane contactInfoPane];
}

@end

