//
//  CBStatusMenuItemController.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemController.h"

@interface CBStatusMenuItemController (PRIVATE)
- (void)activateAdium:(id)sender;
- (void)menuNeedsUpdate:(NSMenu *)menu;
@end

@implementation CBStatusMenuItemController

CBStatusMenuItemController *sharedStatusMenuInstance = nil;

//Returns the shared instance, possibly initializing and creating a new one.
+ (CBStatusMenuItemController *)statusMenuItemController
{
    //Standard singelton stuff.
    if (!sharedStatusMenuInstance){
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
        if([NSApp isOnPantherOrBetter]){
            [theMenu setDelegate:self];
        }

        //Register ourself
        [[adium accountController] registerAccountMenuPlugin:self];
        
        //Setup for unviewed content catching
        accountMenuItemsArray = [[NSMutableArray alloc] init];
        unviewedObjectsArray = [[NSMutableArray alloc] init];
        unviewedState = NO;
        needsUpdate = YES;

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
    //Stick 'em in!
    [accountMenuItemsArray addObjectsFromArray:menuItemArray];
    
    //We need to update next time we're clicked
    needsUpdate = YES;
}

- (void)removeAccountMenuItems:(NSArray *)menuItemArray
{
    //Pull 'em out!
    [accountMenuItemsArray removeObjectsInArray:menuItemArray];
    
    //We need to update next time we're clicked
    needsUpdate = YES;
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
    if([inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
        //If there is new unviewed content
        if([inObject integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]){
            //Add it, we're watching it
            [unviewedObjectsArray addObject:inObject];
            //We need to update our menu
            needsUpdate = YES;
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
                //We need to update our menu
                needsUpdate = YES;
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

//Menu Delegate --------------------------------------------------------
#pragma mark Menu Delegate
- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if(needsUpdate){
        NSEnumerator    *enumerator;
        NSMenuItem      *menuItem;
        AIListObject    *listObject;
        
        //Clear out all the items, start from scratch
        [menu removeAllItems];
        
        //Add the account menu items
        enumerator = [accountMenuItemsArray objectEnumerator];
        menuItem = nil;
        while(menuItem = [enumerator nextObject]){
            [menu addItem:menuItem];
        }
        
        //Prepare to add any unviewed objects
        enumerator = [unviewedObjectsArray objectEnumerator];
        listObject = nil;
        
        /*
        //If there exist any of unviewed objects, prepare to add them
        if([unviewedObjectsArray count] > 0){
            //Add a seperator
            [menu addItem:[NSMenuItem separatorItem]];
            //Create and add the menu items
            while(listObject = [enumerator nextObject]){
                NSLog(@"adding menu item for: %@", [listObject displayName]);
                //Create a menu item from the list object
                menuItem = [[[NSMenuItem alloc] initWithTitle:[listObject displayName] 
                                                      action:NULL 
                                               keyEquivalent:@""] autorelease];
                //Set the image
                //[menuItem setImage:[NSImage imageNamed:@"unviewedContent.png" forClass:[self class]]];
                NSLog(@"menu item: %@", menuItem);
                //Add it to the menu
                [menu addItem:menuItem];
            }
        }
        */
        
        //Add our last two items
        [menu addItem:[NSMenuItem separatorItem]];
        [menu addItemWithTitle:@"Bring Adium to Front"
                        target:self
                        action:@selector(activateAdium:)
                 keyEquivalent:@""];
        
        //Only update next time if we need to
        needsUpdate = NO;
    }
}

@end