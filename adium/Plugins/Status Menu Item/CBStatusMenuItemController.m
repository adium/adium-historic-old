//
//  CBStatusMenuItemController.m
//  Adium XCode
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBStatusMenuItemController.h"

@interface CBStatusMenuItemController (PRIVATE)
- (id)initWithOwner:(AIAdium *)inOwner;
@end

@implementation CBStatusMenuItemController

CBStatusMenuItemController *sharedInstance = nil;

+ (CBStatusMenuItemController *)statusMenuItemControllerForOwner:(id)inOwner
{
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initWithOwner:inOwner];
    }
    return (sharedInstance);
}

- (id)initWithOwner:(AIAdium *)inOwner
{
    if(self = [super init])
    {
        owner = [inOwner retain];
        
        //Create and set up the Status Item.
        statusItem = [[[NSStatusBar systemStatusBar]
            statusItemWithLength:NSSquareStatusItemLength] retain];
    
        [statusItem setHighlightMode:YES];
        [statusItem setImage:[AIImageUtilities imageNamed:@"adium.png" forClass:[self class]]];
        if([NSApp isOnPantherOrBetter])
        {
            [statusItem setAlternateImage:[AIImageUtilities imageNamed:@"adiumHighlight.png" forClass:[self class]]];
        }
        
        //Create our menu
        theMenu = [[NSMenu alloc] initWithTitle:@""];
        [theMenu setAutoenablesItems:NO];
        
        AIAccount *account;        
        NSEnumerator *numer = [[[owner accountController] accountArray] objectEnumerator];
        NSMenuItem *item;
        
        //Add and install menu items for each account
        while(account = [numer nextObject])
        {
            item = [[NSMenuItem alloc] initWithTitle:[account accountDescription] target:self action:nil keyEquivalent:@""];
            [item setRepresentedObject:[account retain]];
            [theMenu addItem:item];
            [theMenu update];
        }

        [statusItem setMenu:theMenu];
        [statusItem setEnabled:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [owner release];
    [statusItem release];
    [theMenu release];
    [super dealloc];
}

- (void)accountsChanged:(NSNotification *)notification
{

}

@end
