//
//  CBStatusMenuItemController.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemController.h"

@interface CBStatusMenuItemController (PRIVATE)
- (void)activateAdium:(id)sender;
@end

@implementation CBStatusMenuItemController

CBStatusMenuItemController *sharedStatusMenuInstance = nil;

//Returns the shared instance, possibly initializing and creating a new one.
+ (CBStatusMenuItemController *)statusMenuItemController
{
    //Standard singelton stuff.
    if (!sharedStatusMenuInstance) {
		sharedStatusMenuInstance = [[self alloc] init];
    }
    return (sharedStatusMenuInstance);
}

//Returns the (naked!) shared instance
+ (CBStatusMenuItemController *)sharedInstance
{
    return sharedStatusMenuInstance;
}

- (id)init
{
    if(self = [super init]){
        //Create and set up the Status Item.
        statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
        [statusItem setHighlightMode:YES];
        [statusItem setImage:[NSImage imageNamed:@"adium.png" forClass:[self class]]];
        if([NSApp isOnPantherOrBetter]){
            [statusItem setAlternateImage:[NSImage imageNamed:@"adiumHighlight.png" forClass:[self class]]];
        }
        
        //Create and install the menu
        theMenu = [[NSMenu alloc] init];
        [theMenu setAutoenablesItems:YES];
        [statusItem setMenu:theMenu];
        
        //Initial items
        [theMenu addItem:[NSMenuItem separatorItem]];
        [theMenu addItemWithTitle:@"Bring Adium to Front" 
                           target:self
                           action:@selector(activateAdium:)
                           keyEquivalent:@""];
        
        //Register ourself
        [[adium accountController] registerAccountMenuPlugin:self];
    }
    
    return self;
}

- (void)dealloc
{
    //Unregister ourself
    [[adium accountController] unregisterAccountMenuPlugin:self];
    
    //Release our objects
    [statusItem release];
    [theMenu release];
        
    //To the superclass, Robin!
    [super dealloc];
}

- (void)activateAdium:(id)sender
{
    //Go go gadget Adium!
    [NSApp activateIgnoringOtherApps:YES];
}

//AccountMenuPlugin --------------------------------------------------------
#pragma mark AccountMenuPlugin

- (NSString *)identifier
{
    //For once, I'm unimaginative. Go figure.
    return @"CBStatusMenuItemController";
}

- (void)addAccountMenuItems:(NSArray *)menuItemArray
{
    NSEnumerator    *enumerator;
    NSMenuItem      *menuItem;
    
    //Reverse it, so we can keep on inserting at the top.
    enumerator = [menuItemArray reverseObjectEnumerator];
    menuItem = nil;
    
    //Add each one at the top (see above)
    while(menuItem = [enumerator nextObject]){
        [theMenu insertItem:menuItem atIndex:0];
    }
}

- (void)removeAccountMenuItems:(NSArray *)menuItemArray
{
    NSEnumerator    *enumerator;
    NSMenuItem      *menuItem;
    
    enumerator = [menuItemArray objectEnumerator];
    menuItem = nil;
    
    //Remove the suckers
    while(menuItem = [enumerator nextObject]){
        [theMenu removeItem:menuItem];
    }
}

@end