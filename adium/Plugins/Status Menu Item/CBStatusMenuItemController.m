//
//  CBStatusMenuItemController.m
//  Adium XCode
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemController.h"

//@interface CBStatusMenuItemController (PRIVATE)
//- (void)preferencesChanged:(NSNotification *)notification;
//- (void)accountsChanged:(NSNotification *)notification;
//- (void)contactsChanged:(NSNotification *)notification;
//- (IBAction)toggleConnection:(id)sender;
//- (IBAction)messageContact:(id)sender;
//- (void)buildMenu;
//@end

@implementation CBStatusMenuItemController

CBStatusMenuItemController *sharedInstance = nil;

+ (CBStatusMenuItemController *)statusMenuItemController
{
    if (!sharedInstance) {
//		sharedInstance = [[self alloc] init];
    }
    return (sharedInstance);
}

//- (id)init
//{
//    if(self = [super init])
//    {        
//        //alloc and init our arrays
//        accountsMenuItems = [[NSMutableArray alloc] init];
//        groupsMenuItems = [[NSMutableDictionary alloc] init];
//        
//        //Create and set up the Status Item.
//        statusItem = [[[NSStatusBar systemStatusBar]
//            statusItemWithLength:NSSquareStatusItemLength] retain];
//    
//        [statusItem setHighlightMode:YES];
//        [statusItem setImage:[AIImageUtilities imageNamed:@"adium.png" forClass:[self class]]];
//        if([NSApp isOnPantherOrBetter])
//        {
//            [statusItem setAlternateImage:[AIImageUtilities imageNamed:@"adiumHighlight.png" forClass:[self class]]];
//        }
//        
//        //Create our menu
//        theMenu = [[NSMenu alloc] initWithTitle:@""];
//        [theMenu setAutoenablesItems:NO];
//
//        [statusItem setMenu:theMenu];
//        [statusItem setEnabled:YES];
//        
//        //Install our observers
//        [[adium notificationCenter] addObserver:self selector:@selector(accountsChanged:) name:Account_ListChanged object:nil];
//        [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
//        [[adium notificationCenter] addObserver:self selector:@selector(contactsChanged:) name:ListObject_StatusChanged object:nil];
//    }
//    
//    return self;
//}

//- (void)dealloc
//{
//    [[adium notificationCenter] removeObserver:self];
//    [accountsMenuItems release];
//    [groupsMenuItems release];
//    [statusItem release];
//    [theMenu release];
//    [super dealloc];
//}
//
//- (void)preferencesChanged:(NSNotification *)notification
//{
//    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
//    
//    if([group compare:GROUP_ACCOUNT_STATUS] == 0){
//		[self accountsChanged:nil];
//    }
//}
//
//- (void)accountsChanged:(NSNotification *)notification
//{
//    //we'll be building from scratch for now, so clear the array out.
//    [accountsMenuItems release];
//    accountsMenuItems = [[NSMutableArray alloc] init];
//    
//    AIAccount *account = nil;        
//    NSEnumerator *numer = [[[adium accountController] accountArray] objectEnumerator];
//    NSMenuItem *item;
//	
//    //Add and install menu items for each account
//    while(account = [numer nextObject])
//    {
//        item = [[[NSMenuItem alloc] initWithTitle:[account displayName] target:self action:@selector(toggleConnection:) keyEquivalent:@""] autorelease];
//        [item setRepresentedObject:[account retain]];
//		
//		if([[[account statusArrayForKey:@"Online"] objectWithOwner:account] boolValue]){
//			[item setImage:[AIImageUtilities imageNamed:@"Account_Online.tiff" forClass:[self class]]];
//			[item setEnabled:YES];
//		}else if([[[account statusArrayForKey:@"Connecting"] objectWithOwner:account] boolValue]){
//			[item setImage:[AIImageUtilities imageNamed:@"Account_Connecting.tiff" forClass:[self class]]];
//			[item setEnabled:NO];
//		}else if([[[account statusArrayForKey:@"Disconnecting"] objectWithOwner:account] boolValue]){
//			[item setImage:[AIImageUtilities imageNamed:@"Account_Connecting.tiff" forClass:[self class]]];
//			[item setEnabled:NO];
//			break;
//		}else{
//			[item setImage:[AIImageUtilities imageNamed:@"Account_Offline.tiff" forClass:[self class]]];
//			[item setEnabled:YES];
//		}
//        
//        [accountsMenuItems addObject:item];
//    }
//    
//    [self buildMenu];
//}
//
//#warning Adam: Rebuilding this menu on every status change is slow
//- (void)contactsChanged:(NSNotification *)notification
//{
//    if([[notification object] isKindOfClass:[AIAccount class]]) //do it in the other method
//    {
//        [self accountsChanged:nil];
//    }
//    else //we don't care about accounts
//    {
//        //snag the contact from the notification
//        AIListObject    *contact;
//        if (contact = [notification object]){
//            
//            NSString        *containingGroupUID;
//            if (containingGroupUID = [[contact containingGroup] UID]) {
//                
//                //see if there's already a group menu for this contact
//                NSMenuItem *groupItem = [groupsMenuItems objectForKey:containingGroupUID];
//                
//                if(!groupItem) //No group menu item!
//                {
//                    //so we create one
//                    groupItem = [[[NSMenuItem alloc] initWithTitle:containingGroupUID action:nil keyEquivalent:@""] autorelease];
//                    [groupItem setRepresentedObject:[contact containingGroup]];
//                    [groupItem setEnabled:YES];
//                    
//                    //and add it to our dict
//                    [groupsMenuItems setObject:groupItem forKey:containingGroupUID];
//                }
//                
//                if(![groupItem hasSubmenu]) //No submenuon the group menu item
//                {
//                    //so we add them
//                    [groupItem setSubmenu:[[NSMenu alloc] initWithTitle:containingGroupUID]];
//                } /* small WoA: the reason I didn't combine this with the above is in case Something Weird happens
//                and we don't have a menu for the existing group (bad reference counting, or just plain
//                                                                 Wackyness). I don't actually expect this case to happen without the (!groupItem) statement being
//                evaluated, but hey, you never know -chb */
//                
//                //active iff online ^ ~(away v idle)
//                BOOL isActive = [[contact statusArrayForKey:@"Online"] greatestIntegerValue] && !([[contact statusArrayForKey:@"Away"] greatestIntegerValue] || [[contact statusArrayForKey:@"Idle"] greatestIntegerValue]);
//                int indexOfItem = [[groupItem submenu] indexOfItemWithRepresentedObject:contact];
//                
//                //add if active and not in menu.
//                if(isActive && indexOfItem == -1)
//                {
//                    //What we're doing here is the following:
//                    //  A) If we have items already,
//                    //      1) build an array of ListObjects
//                    //      2) send that array to the Sort Method
//                    //      3) find out what index our contact is in that array
//                    //      4) and insert him in the same place in our menu
//                    //  B) Otherwise, just insert him at the top, it doesn't matter
//                    
//                    NSMutableArray *sortArray = [NSMutableArray arrayWithObject:contact];
//                    NSMenuItem *menuItemObj = nil;
//                    NSMenuItem *contactMenuItem = [[[NSMenuItem alloc] initWithTitle:[contact displayName] target:self action:@selector(messageContact:) keyEquivalent:@""] autorelease];
//                    [contactMenuItem setRepresentedObject:contact];
//                    [contactMenuItem setEnabled:YES];
//                    
//                    if([[[groupItem submenu] itemArray] count] > 0)
//                    {
//                        NSEnumerator *numer = [[[groupItem submenu] itemArray] objectEnumerator];
//                        while(menuItemObj = [numer nextObject])
//                        {
//                            [sortArray addObject:[menuItemObj representedObject]];
//                        }
//                        
//                        [[[adium contactController] activeSortController] sortListObjects:sortArray];
//                        
//                        [[groupItem submenu] insertItem:contactMenuItem atIndex:[sortArray indexOfObjectIdenticalTo:contact]];
//                    }
//                    else
//                    {
//                        [[groupItem submenu] addItem:contactMenuItem];
//                    }
//                    
//                    //GO GO GO!
//                    [self buildMenu];
//        }
//                
//                //remove if not active and in menu
//                else if(!isActive && indexOfItem != -1)
//                {
//                    [[groupItem submenu] removeItemAtIndex:indexOfItem];
//                    
//                    //GO GO GO!
//                    [self buildMenu];
//                }
//                
//                //if this group is empty, remove it!
//                if([[[groupItem submenu] itemArray] count] == 0)
//                {
//                    [groupsMenuItems removeObjectForKey:containingGroupUID];
//                    
//                    //GO GO GO!
//                    [self buildMenu];
//                }
//            }
//        }
//    }
//}

//Toggle the connection of the selected account (called by the connect/disconnnect menu item)
//MUST be called by a menu item with an account as its represented object!
//- (IBAction)toggleConnection:(id)sender
//{
//    AIAccount   *targetAccount = [sender representedObject];
//
//    //Toggle the connection
//    BOOL newOnlineProperty = !([[targetAccount statusObjectForKey:@"Online"] boolValue]);
//    [targetAccount setPreference:[NSNumber numberWithBool:newOnlineProperty] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
//}
//
////Send a message to a contact.
////MUST be called by a menu item with an AIListObject as its represented object!
//- (IBAction)messageContact:(id)sender
//{
//    AIListObject    *contact = [sender representedObject];
//    AIChat          *ourChat = [AIChat chatForAccount:[[adium accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:contact]];
//    
//    [ourChat addParticipatingListObject:contact];
//    [[adium interfaceController] openChat:ourChat];
//    [[adium interfaceController] setActiveChat:ourChat];
//}
//
//- (void)buildMenu
//{
//    //clear out the old menu
//    [theMenu release];
//    theMenu = [[NSMenu alloc] init];
//    
//    NSEnumerator *numer;
//    NSMenuItem *item;
//    
//    /* //If people really miss this, I'll put it back in. doesn't seem necessary. It's pretty obvious that they're your SNs...
//    //add a descriptor
//    item = [[[NSMenuItem alloc] initWithTitle:@"Accounts" action:nil keyEquivalent:@""] autorelease];
//    [item setEnabled:NO];
//    [theMenu addItem:item];
//    */
//    
//    //traverse the accounts array
//    numer = [accountsMenuItems objectEnumerator];
//    while(item = [numer nextObject])
//    {
//        [[item menu] removeItem:item];
//        [theMenu addItem:item];
//    }
//    
//    if([groupsMenuItems count] > 0)
//    {
//        //add a divider
//        [theMenu addItem:[NSMenuItem separatorItem]];
//        
//        //add the group objects to an array
//        NSMutableArray *groupArray = [NSMutableArray array];
//        numer = [groupsMenuItems objectEnumerator];
//        while(item = [numer nextObject])
//        {
//            [groupArray addObject:[item representedObject]];
//        }
//        
//        //sort the array
//        [[[adium contactController] activeSortController] sortListObjects:groupArray];
//        
//        //traverse the groupsItems dict in the correct order
//        numer = [groupArray objectEnumerator];
//        while(item = [groupsMenuItems objectForKey:[(AIListObject *)[numer nextObject] UID]])
//        {
//            [[item menu] removeItem:item];
//            [theMenu addItem:item];
//        }
//    }
//    
//    //install our menu
//    [statusItem setMenu:theMenu];
//}

@end
