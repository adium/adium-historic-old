//
//  ESRendezvousAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 1/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESRendezvousAccountViewController.h"

//Use the default profile view, but override optionsView to be nil so isn't displayed
@implementation ESRendezvousAccountViewController

//Account specific views -----------------------------------------------------------------------------------------------
#pragma mark Account specific views
//Options view
- (NSView *)optionsView
{
    return(nil);
}

@end
