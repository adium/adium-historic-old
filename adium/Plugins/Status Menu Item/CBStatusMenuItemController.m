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
        
        //Setup for unviewed content catching
        unviewedObjectsArray = [[NSMutableArray alloc] init];
        unviewedState = NO;

        //Register as a contact observer (So we can catch the unviewed content status flag)
        [[adium contactController] registerListObjectObserver:self];

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
    [unviewedObjectsArray release];
        
    //To the superclass, Robin!
    [super dealloc];
}

- (void)activateAdium:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp arrangeInFront:nil];
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

//Twiddle visibility --------------------------------------------------------
#pragma mark Twiddle visibility
- (void)showStatusItem
{
	//Kinda cheap hack, but it works
    [statusItem setLength:NSSquareStatusItemLength];
}

- (void)hideStatusItem
{
	//See above
    [statusItem setLength:0];
}

//Contact Observer --------------------------------------------------------
#pragma mark Contact Observer
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	//If the contact's unviewed content state has changed
    if([inModifiedKeys containsObject:@"UnviewedContent"]){
        //If there is new unviewed content
        if([inObject integerStatusObjectForKey:@"UnviewedContent"]){
            [unviewedObjectsArray addObject:inObject];
            //If this is the first contact with unviewed content, set our icon to unviewed content
            if(!unviewedState){
                //Set the image, with the highlight for 10.3 peoples.
                [statusItem setImage:[NSImage imageNamed:@"adiumRed.png" forClass:[self class]]];
                if([NSApp isOnPantherOrBetter]){
                    [statusItem setAlternateImage:[NSImage imageNamed:@"adiumRedHighlight.png" forClass:[self class]]];
                }
                //Set our state variable
                unviewedState = YES;
            }
        //If they've viewed the content
        }else{
            //If we're tracking this object
            if([unviewedObjectsArray containsObject:inObject]){
                //Remove it, it's not unviewed anymore
                [unviewedObjectsArray removeObject:inObject];
                //If there are no more contacts with unviewed content, set our icon to normal
                if([unviewedObjectsArray count] == 0 && unviewedState){
                    //Set the image, with the highlight for 10.3 peoples.
                    [statusItem setImage:[NSImage imageNamed:@"adium.png" forClass:[self class]]];
                    if([NSApp isOnPantherOrBetter]){
                        [statusItem setAlternateImage:[NSImage imageNamed:@"adiumHighlight.png" forClass:[self class]]];
                    }
                    //Set our state variable
                    unviewedState = NO;
                }
            }
        }
    }
	//We didn't modify contacts, so return nil 
    return(nil);
}

@end