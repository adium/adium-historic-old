//
//  ESContactAlertsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
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

