//
//  ESEventBezelContactAlert.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESEventBezelContactAlert.h"


@implementation ESEventBezelContactAlert

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:@"Display the Event Bezel"
                                           target:self
                                           action:@selector(selectedAlert:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:CONTACT_ALERT_IDENTIFIER];
    
    return (menuItem);
}

//No further configuration is required
-(IBAction)selectedAlert:(id)sender
{
    [self configureWithSubview:nil];
}

@end
