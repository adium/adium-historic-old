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

        contactListItems = [ [ NSMutableArray alloc ] init ];

        //contactsMenuItems = [ [ NSMutableArray alloc ] init ];
        
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

        /* BEG -- Added by Sean Gilbertson (prell), 2003-12-27 @ 1957. */

        [ [ adium contactController ] registerListObjectObserver:self ];

        /* END -- Added by Sean Gilbertson (prell), 2003-12-27 @ 1957. */
    }
    
    return self;
}

- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [accountsMenuItems release];
    //[groupsMenuItems release];

    [ contactListItems release ];

    //[ contactsMenuItems release ];

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
//        [item setRepresentedObject:[account retain]];
        [ item setRepresentedObject:account ];

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

/*
 * Method  :  removeContactFromMenu:
 *
 * Created :  2003-12-28 @ 0000
 *      by :  Sean Gilbertson
 */
- ( void ) removeContactFromMenu:( NSString* )contact
{
    NSEnumerator* contactListEnumerator;

    contactListEnumerator = [ contactListItems objectEnumerator ];

    id currentContactListItem;

    while ( currentContactListItem = [ contactListEnumerator nextObject ] ) {
        if ( [ [ currentContactListItem displayName ] isEqualToString:contact ] ) {
            [ contactListItems removeObject:currentContactListItem ];
        }
    }
}

- ( BOOL ) contactIsInContactList:( NSString* )contact
{
    NSEnumerator* contactListEnumerator;
    
    contactListEnumerator = [ contactListItems objectEnumerator ];
    
    id currentContactListItem;
    
    BOOL foundContact = FALSE;
    
    while ( currentContactListItem = [ contactListEnumerator nextObject ] ) {
        if ( [ [ currentContactListItem displayName ] isEqualToString:contact ] ) {
            foundContact = TRUE;

            break;
        }
    } 

    return foundContact;
}

- ( void ) sortContactList
{
    [ [ [ adium contactController ] activeSortController ] sortListObjects:contactListItems ];
}

/*
 * Method  :  addContactToMenu:representedListObject:
 *
 * Created :  2003-12-28 @ 0000
 *      by :  Sean Gilbertson
 */
- ( void ) addContactToMenu:( NSString* )contact
      representedListObject:( AIListObject* )listObject
{
    BOOL foundContact;

    foundContact = [ self contactIsInContactList:contact ];

    if ( !foundContact ) {
        [ contactListItems addObject:listObject ];

        [ self sortContactList ];
    } else {
        return;
    }
}

/*
 * Method  :  updateListObject:keys:delayed:silent
 *
 * Created :  2003-12-27 @ 2100
 *      by :  Sean Gilbertson
 */
- ( NSArray* ) updateListObject:( AIListObject* )inObject
                           keys:( NSArray* )inModifiedKeys
                        delayed:( BOOL )delayed
                         silent:( BOOL )silent
{
    /* TODO: Do this conditiional without class reflection. */
    if ( inModifiedKeys
         && ( [ [ inObject statusArrayForKey:@"Online" ] greatestIntegerValue ] > 0 )
         && [ inObject isKindOfClass:[ AIListContact class ] ]
         /*&& ( [ inModifiedKeys containsObject:@"Online" ]  )*/
         && ( [ [ inObject statusArrayForKey:@"Away" ] greatestIntegerValue ] == 0
              && [ [ inObject statusArrayForKey:@"Idle" ] greatestDoubleValue ] == 0 ) )
    {
        /* If someone (not us) is not idle or away, display them. */

        [ self addContactToMenu:[ inObject displayName ]
          representedListObject:inObject ];
    } else if ( inModifiedKeys
                && ( [ [ inObject statusArrayForKey:@"Away" ] greatestIntegerValue ] > 0
                     || [ [ inObject statusArrayForKey:@"Idle" ] greatestDoubleValue ] > 0
                     || ( [ inModifiedKeys containsObject:@"Online" ]
                          && ( [ [ inObject statusArrayForKey:@"Online" ] greatestIntegerValue ] == 0 ) ) ) )
    {
        /* If someone went away or idle, or signed off, take them off the menu. */

        [ self removeContactFromMenu:[ inObject displayName ] ];
    }

    /* Build here for now. */
    [ self buildMenu ];

    return nil;
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

- ( IBAction ) sendMessageToContact:( id )sender
{
    AIChat* newIM;

    newIM = [ [ adium contentController ] openChatOnAccount:nil
                                             withListObject:[ sender representedObject ] ];

    [ [ adium interfaceController ] setActiveChat:newIM ];
}

- ( IBAction ) showContactListInterface:( id ) sender
{
    //[ [ adium interfaceController ] openInterface ];

    /*
    [ [ [ [ adium interfaceController ] contactListViewController ] contactListView ] setHidden:FALSE ];

    [ [ [ [ adium interfaceController ] contactListViewController ] contactListView ] display ];

    [ [ [ [ [ adium interfaceController ] contactListViewController ] contactListView ] window ] makeKeyAndOrderFront:nil ];
     */

    /* Write the code for this when the capability is public, or I discover
     * that it already is, somewhere. */
}

- (void)buildMenu
{
    //clear out the old menu
    //[theMenu release];
    //theMenu = [[NSMenu alloc] init];

    NSEnumerator* menuItemsEnumerator;

    menuItemsEnumerator = [ [ theMenu itemArray ] objectEnumerator ];

    id menuItem;

    while ( menuItem = [ menuItemsEnumerator nextObject ] ) {
        [ theMenu removeItem:menuItem ];
    }

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

    if ( contactListItems && [ contactListItems count ] > 0 ) {
        /* Separator between accounts and contacts. */
        [ theMenu addItem:[ NSMenuItem separatorItem ] ];
    }

    NSEnumerator* contactListItemsEnumerator;

    contactListItemsEnumerator = [ contactListItems objectEnumerator ];

    id contactListItem;

    while ( contactListItem = [ contactListItemsEnumerator nextObject ] ) {
        NSMenuItem* newContactMenuItem;

        newContactMenuItem = [ [ NSMenuItem alloc ] initWithTitle:[ contactListItem displayName ]
                                                           action:@selector( sendMessageToContact: )
                                                    keyEquivalent:@"" ];
        
        [ newContactMenuItem setTarget:self ];
        
        [ newContactMenuItem setRepresentedObject:contactListItem ];

        [ theMenu addItem:newContactMenuItem ];
        
        [ newContactMenuItem release ];        
    }

    /* Add a separator between everything and the shortcut to the buddy list view. */
    [ theMenu addItem:[ NSMenuItem separatorItem ] ];

    NSMenuItem* showContactListItem;

    /*
    showContactListItem = [ [ NSMenuItem alloc ] initWithTitle:@"Show Buddy List"
                                                      action:@selector( showContactListInterface: )
                                               keyEquivalent:@"" ];

    [ showContactListItem setTarget:self ];
     */

    /* No action, because this is disabled for now (see showContactListInterface:) */
    showContactListItem = [ [ NSMenuItem alloc ] initWithTitle:@"Show Contact List"
                                                        action:nil
                                                 keyEquivalent:@"" ];

    [ showContactListItem setEnabled:FALSE ];

    [ theMenu addItem:showContactListItem ];

    [ showContactListItem release ];

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
