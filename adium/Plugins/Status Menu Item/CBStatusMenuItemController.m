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
- (void)accountsChanged:(NSNotification *)notification;
- (IBAction)toggleConnection:(id)sender;
- (void)buildMenu;
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
        
        //alloc and init our arrays
        accountsMenuItems = [[NSMutableArray alloc] init];
        //groupsMenuItems = [[NSMutableArray alloc] init];
        
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

        [statusItem setMenu:theMenu];
        [statusItem setEnabled:YES];
        
        //Install our observers
        [[owner notificationCenter] addObserver:self selector:@selector(accountsChanged:) name:Account_ListChanged object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(accountsChanged:) name:Account_PropertiesChanged object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [owner release];
    [accountsMenuItems release];
    //[groupsMenuItems release];
    [statusItem release];
    [theMenu release];
    [super dealloc];
}

- (void)accountsChanged:(NSNotification *)notification
{
    //we'll be building from scrach for now, so clear the array out.
    accountsMenuItems = [[NSMutableArray alloc] init];
    
    AIAccount *account = nil;        
    NSEnumerator *numer = [[[owner accountController] accountArray] objectEnumerator];
    NSMenuItem *item;
        
    //Add and install menu items for each account
    while(account = [numer nextObject])
    {
        item = [[[NSMenuItem alloc] initWithTitle:[account accountDescription] target:self action:@selector(toggleConnection:) keyEquivalent:@""] autorelease];
        [item setRepresentedObject:[account retain]];
        
        switch([[[owner accountController] propertyForKey:@"Status" account:account] intValue])
        {
            case STATUS_OFFLINE:
                [item setImage:[AIImageUtilities imageNamed:@"Account_Offline.tiff" forClass:[self class]]];
                [item setEnabled:YES];
                break;
            case STATUS_CONNECTING:
                [item setImage:[AIImageUtilities imageNamed:@"Account_Connecting.tiff" forClass:[self class]]];
                [item setEnabled:NO];
                break;
            case STATUS_ONLINE:
                [item setImage:[AIImageUtilities imageNamed:@"Account_Online.tiff" forClass:[self class]]];
                [item setEnabled:YES];
                break;
            case STATUS_DISCONNECTING:
                [item setImage:[AIImageUtilities imageNamed:@"Account_Connecting.tiff" forClass:[self class]]];
                [item setEnabled:NO];
                break;
            default:
                [item setEnabled:NO];
                break;
        }
        
        [accountsMenuItems addObject:item];
    }
    
    [self buildMenu];
}

//Togle the connection of the selected account (called by the connect/disconnnect menu item)
//MUST be called by a menu item with an account as its represented object!
- (IBAction)toggleConnection:(id)sender
{
    AIAccount   *targetAccount = [sender representedObject];
    NSNumber    *status = [[owner accountController] propertyForKey:@"Status" account:targetAccount];

    //Toggle the connection
    BOOL newOnlineProperty = !([status intValue] == STATUS_ONLINE);
    [[owner accountController] setProperty:[NSNumber numberWithBool:newOnlineProperty] 
                                    forKey:@"Online" account:targetAccount];
}

- (void)buildMenu
{
    NSEnumerator *numer;
    NSMenuItem *item;
    
    //add a descriptor
    item = [[[NSMenuItem alloc] initWithTitle:@"Accounts" action:nil keyEquivalent:@""] autorelease];
    [item setEnabled:NO];
    [theMenu addItem:item];
    
    //traverse the accounts array
    numer = [accountsMenuItems objectEnumerator];
    while(item = [numer nextObject])
        [theMenu addItem:item];
    
    //add a divider
    //[theMenu addItem:[NSMenuItem separatorItem]];

    //add a descriptor
    //item = [[[NSMenuItem alloc] initWithTitle:@"Accounts" action:nil keyEquivalent:nil] autorelease];
    //[item setEnabled:NO];
    //[theMenu addItem:item];
    
    //traverse the groups array
    //numer = [accountsMenuItems objectEnumerator];
    //while(item = [numer nextObject])
    //    [theMenu addItem:item];
}

@end
