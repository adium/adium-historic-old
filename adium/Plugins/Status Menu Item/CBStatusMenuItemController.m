//
//  CBStatusMenuItemController.m
//  Adium XCode
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBStatusMenuItemController.h"

@interface CBStatusMenuItemController (PRIVATE)
- (void)accountsChanged:(NSNotification *)notification;
- (IBAction)toggleConnection:(id)sender;
- (void)buildMenu;
@end

@implementation CBStatusMenuItemController

CBStatusMenuItemController *sharedInstance = nil;

+ (CBStatusMenuItemController *)statusMenuItemController
{
    if (!sharedInstance) {
        sharedInstance = [[self alloc] init];
    }
    return (sharedInstance);
}

- (id)init
{
    if(self = [super init])
    {        
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
        [[adium notificationCenter] addObserver:self selector:@selector(accountsChanged:) name:Account_ListChanged object:nil];
        [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [accountsMenuItems release];
    //[groupsMenuItems release];
    [statusItem release];
    [theMenu release];
    [super dealloc];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    
    if([group compare:GROUP_ACCOUNT_STATUS] == 0){
	[self accountsChanged:nil];
    }
}

- (void)accountsChanged:(NSNotification *)notification
{
    //we'll be building from scrach for now, so clear the array out.
    [accountsMenuItems release];
    accountsMenuItems = [[NSMutableArray alloc] init];
    
    AIAccount *account = nil;        
    NSEnumerator *numer = [[[adium accountController] accountArray] objectEnumerator];
    NSMenuItem *item;
        
    //Add and install menu items for each account
    while(account = [numer nextObject])
    {
        item = [[[NSMenuItem alloc] initWithTitle:[account displayName] target:self action:@selector(toggleConnection:) keyEquivalent:@""] autorelease];
        [item setRepresentedObject:[account retain]];

	if([[[account statusArrayForKey:@"Online"] objectWithOwner:account] boolValue]){
	    [item setImage:[AIImageUtilities imageNamed:@"Account_Online.tiff" forClass:[self class]]];
	    [item setEnabled:YES];
	}else if([[[account statusArrayForKey:@"Connecting"] objectWithOwner:account] boolValue]){
	    [item setImage:[AIImageUtilities imageNamed:@"Account_Connecting.tiff" forClass:[self class]]];
	    [item setEnabled:NO];
	}else if([[[account statusArrayForKey:@"Disconnecting"] objectWithOwner:account] boolValue]){
	    [item setImage:[AIImageUtilities imageNamed:@"Account_Connecting.tiff" forClass:[self class]]];
	    [item setEnabled:NO];
	    break;
	}else{
	    [item setImage:[AIImageUtilities imageNamed:@"Account_Offline.tiff" forClass:[self class]]];
	    [item setEnabled:YES];
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

    //Toggle the connection
    BOOL newOnlineProperty = !([[targetAccount statusObjectForKey:@"Online"] boolValue]);
    [targetAccount setPreference:[NSNumber numberWithBool:newOnlineProperty] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
}

- (void)buildMenu
{
    //clear out the old menu
    [theMenu release];
    theMenu = [[NSMenu alloc] init];
    
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

    [statusItem setMenu:theMenu];
}

@end
