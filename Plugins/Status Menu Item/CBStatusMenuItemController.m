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
- (void)accountStateChanged:(NSNotification *)notification;
@end

@implementation CBStatusMenuItemController

static	CBStatusMenuItemController	*sharedStatusMenuInstance = nil;
static	NSImage						*unviewedContentImage = nil;

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
        //Create and set up the status item
        statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
        [statusItem setHighlightMode:YES];
		if (!unviewedContentImage){
			unviewedContentImage = [[NSImage imageNamed:@"unviewedContent.png" forClass:[self class]] retain];
		}
		
		//Initialize our state
		iconState = -1;
		[self setIconState:OFFLINE];
		
        //Create and install the menu
        theMenu = [[NSMenu alloc] init];
        [theMenu setAutoenablesItems:YES];
        [statusItem setMenu:theMenu];
        [theMenu setDelegate:self];

        //Register ourself
        [[adium accountController] registerAccountMenuPlugin:self];
        
        //Setup for unviewed content catching
        accountMenuItemsArray = [[NSMutableArray alloc] init];
        unviewedObjectsArray = [[NSMutableArray alloc] init];
        needsUpdate = YES;

        //Register as a chat observer (So we can catch the unviewed content status flag)
        [[adium contentController] registerChatObserver:self];
				
		//Register to recieve connect/disconnect notifications
		[[adium notificationCenter] addObserver:self
									   selector:@selector(accountStateChanged:)
										   name:ACCOUNT_CONNECTED
										 object:nil];
		[[adium notificationCenter] addObserver:self
									   selector:@selector(accountStateChanged:)
										   name:ACCOUNT_DISCONNECTED
								         object:nil];

    }
    
    return self;
}

- (void)dealloc
{
    //Unregister ourself
    [[adium accountController] unregisterAccountMenuPlugin:self];
    
    //Release our objects
    [statusItem release];
    //[statusView release];
    [theMenu release];
    [unviewedObjectsArray release];
        
    //To the superclass, Robin!
    [super dealloc];
}

//Icon State --------------------------------------------------------
#pragma mark Icon State

- (void)setIconState:(SMI_Icon_State)state
{
	//If we're not already in that state
	if(state != iconState){
		//Set our state to the new one
		iconState = state;
		//And set the appropriate icon
		if(iconState == OFFLINE){
			[statusItem setImage:[NSImage imageNamed:@"adiumOffline.png" forClass:[self class]]];
			[statusItem setAlternateImage:[NSImage imageNamed:@"adiumOfflineHighlight.png" forClass:[self class]]];
		}else if(iconState == ONLINE){
			[statusItem setImage:[NSImage imageNamed:@"adium.png" forClass:[self class]]];
			[statusItem setAlternateImage:[NSImage imageNamed:@"adiumHighlight.png" forClass:[self class]]];
		}else{
			[statusItem setImage:[NSImage imageNamed:@"adiumRed.png" forClass:[self class]]];
			[statusItem setAlternateImage:[NSImage imageNamed:@"adiumRedHighlight.png" forClass:[self class]]];
		}
	}
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

//Chat Observer --------------------------------------------------------
#pragma mark Chat Observer

- (NSArray *)updateChat:(AIChat *)inChat keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	//If the contact's unviewed content state has changed
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
        //If there is new unviewed content
        if([inChat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]){
            //If we're not already watching it
            if(![unviewedObjectsArray containsObjectIdenticalTo:inChat]){
                //Add it, we're watching it now
                [unviewedObjectsArray addObject:inChat];
                //We need to update our menu
                needsUpdate = YES;
                //If this is the first contact with unviewed content, set our icon to unviewed content
                if(iconState != UNVIEWED){
                    //Set our state
					[self setIconState:UNVIEWED];
                }
            }
        //If they've viewed the content
        }else{
            //If we're tracking this object
            if([unviewedObjectsArray containsObjectIdenticalTo:inChat]){
                //Remove it, it's not unviewed anymore
                [unviewedObjectsArray removeObject:inChat];
                //We need to update our menu
                needsUpdate = YES;
                //If there are no more contacts with unviewed content, set our icon to normal
                if([unviewedObjectsArray count] == 0 && iconState == UNVIEWED){
                    //Set our state
					[self setIconState:ONLINE];
				}
            }
        }
    }
	//We didn't modify contacts, so return nil 
    return nil;
}

//Menu Delegate --------------------------------------------------------
#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    //If something has changed
    if(needsUpdate){
        NSEnumerator    *enumerator;
        NSMenuItem      *menuItem;
        AIChat          *chat;
        
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
        chat = nil;
        
        //If there exist any of unviewed objects, prepare to add them
        if([unviewedObjectsArray count] > 0){
            //Add a seperator
            [menu addItem:[NSMenuItem separatorItem]];
            //Create and add the menu items
            while(chat = [enumerator nextObject]){
                //Create a menu item from the list object
                menuItem = [[[NSMenuItem alloc] initWithTitle:[chat displayName] 
                                                       target:self
                                                       action:@selector(switchToChat:) 
                                                keyEquivalent:@""] autorelease];
                //Set the represented object
                [menuItem setRepresentedObject:chat];
                //Set the image
                [menuItem setImage:unviewedContentImage];
                //Add it to the menu
                [menu addItem:menuItem];
            }
        }
        
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

//Menu Actions --------------------------------------------------------
#pragma mark Menu Actions
- (void)switchToChat:(id)sender
{
    //If we're not the active app, activate 
    if(![NSApp isActive]){
        [self activateAdium:nil];
    }
    
    [[adium interfaceController] setActiveChat:[sender representedObject]];
}

- (void)activateAdium:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp arrangeInFront:nil];
}

//Offline Icon Control --------------------------------------------------------
#pragma mark Offline Icon Control

- (void)accountStateChanged:(NSNotification *)notification
{
	static int onlineCount = 0;
	
	//Increase our counter when accounts come online
	if([[notification name] isEqualToString:ACCOUNT_CONNECTED]){
		onlineCount++;
	//Decrease our counter when accounts go offline
	}else{
		onlineCount--;
	}
	
	//Set our Icon State accordingly
	[self setIconState:(onlineCount > 0 ? ONLINE : OFFLINE)];
}

@end