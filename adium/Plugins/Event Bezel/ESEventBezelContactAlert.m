//
//  ESEventBezelContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//

#import "ESEventBezelContactAlert.h"

#define DISPLAY_EVENT_BEZEL AILocalizedString(@"Display the Event Bezel",nil)

@implementation ESEventBezelContactAlert

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:DISPLAY_EVENT_BEZEL
                                           target:self
                                           action:@selector(selectedAlert:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:BEZEL_CONTACT_ALERT_IDENTIFIER];
    
    return (menuItem);
}

//No further configuration is required
- (void)configureView
{
    [self configureWithSubview:nil];
}

@end
