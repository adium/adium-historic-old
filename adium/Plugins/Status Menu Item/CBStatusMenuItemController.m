//
//  CBStatusMenuItemController.m
//  Adium XCode
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBStatusMenuItemController.h"

//BOOL isPanther = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2);

@implementation CBStatusMenuItemController

- (id)initWithOwner:(AIAdium *)inOwner
{
    if(self = [super init])
    {
        owner = [inOwner retain];
        
        statusItem = [[[NSStatusBar systemStatusBar]
            statusItemWithLength:NSSquareStatusItemLength] retain];
    
        [statusItem setHighlightMode:YES];
        [statusItem setImage:[AIImageUtilities imageNamed:@"adium.png" forClass:[self class]]];
        //[statusItem setMenu:itemMenu];
        [statusItem setEnabled:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [statusItem release];
    //[itemMenu release];
    [owner release];
}

@end
