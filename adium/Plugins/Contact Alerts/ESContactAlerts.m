//
//  ESContactAlerts.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
// notes: saveEventActionArray is probably being called too often

#import "ESContactAlerts.h"
#import "ESContactAlertsPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"


#define CONTACT_ALERT_ACTIONS_NIB 	@"ContactAlertsActions"
#define	EVENT_SOUND_PREF_NIB		@"EventSoundPrefs"
#define EVENT_SOUND_PREF_TITLE		@"Sounds"
#define SOUND_MENU_ICON_SIZE		16

@interface ESContactAlerts (PRIVATE)
- (void)configureForTextDetails:(NSString *)instructions;
- (void)configureForMenuDetails:(NSString *)instructions menuToDisplay:(NSMenu *)detailsMenu;
- (void)configureWithSubview:(NSView *)view_inView;
- (void)saveEventActionArray;
- (void)testSelectedEvent;

- (NSMenu *)accountMenu;
- (NSMenu *)accountForOpenMessageMenu;
- (NSMenu *)behaviorListMenu;
- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name;
- (NSMenuItem *)eventMenuItem:(NSString *)event withDisplay:(NSString *)displayName;
- (NSMenu *)sendToContactMenu;
- (NSMenu *)soundListMenu;
@end


int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context);

@implementation ESContactAlerts

- (id)initWithDetailsView:(NSView *)inView withTable:(AIAlternatingRowTableView*)inTable withPrefView:(NSView *)inPrefView owner:(id)inOwner
{
    [NSBundle loadNibNamed:CONTACT_ALERT_ACTIONS_NIB owner:self];
    cachedAlertsDict = [[[NSMutableDictionary alloc] init] retain];

    owner = inOwner;
    [owner retain];

    tableView_actions = inTable;
    [tableView_actions retain];

    view_main = inView;
    [view_main retain];

    view_pref = inPrefView;
    [view_pref retain];

    view_blank = [[NSView alloc] init];
    [view_blank retain];
    
    if ( view_main && [[view_main subviews] count] == 0 ) //there are no subviews yet
        [view_main addSubview:view_blank];
    
    //nothing's selected, obviously, so row = -1
    row = -1;
    
    [super init];
    return self;
}

- (void)configForObject:(AIListObject *)inObject
{
    [activeContactObject release];
    activeContactObject = inObject;
    [activeContactObject retain];

    //unregister old observers?
    //   [[owner notificationCenter] removeObserver:self name:One_Time_Event_Fired object:activeContactObject];

    [self reload:activeContactObject usingCache:YES];
}

- (void)dealloc
{
    //remove observer
    [[owner notificationCenter] removeObserver:self name:One_Time_Event_Fired object:activeContactObject];

    [owner release];
    [activeContactObject release];
    [eventActionArray release];
    [view_blank release];
}

- (void)currentRowIs:(int)currentRow
{
    row = currentRow;
    if (row != -1) selectedActionDict = [[eventActionArray objectAtIndex:row] mutableCopy];
}

- (int)currentRow
{
    return row;
}
- (NSMutableArray *)eventActionArray
{
    return eventActionArray;
}

- (NSMutableDictionary *)dictAtIndex:(int)inRow
{
    return ([eventActionArray objectAtIndex:inRow]);
}

-(BOOL)hasAlerts
{
    if ([eventActionArray count])
        return YES;
    else
        return NO;
}

-(int)count
{
    return ([eventActionArray count]);
}

-(void)replaceDictAtIndex:(int)inRow withDict:(NSDictionary *)newDict
{
    [eventActionArray replaceObjectAtIndex:inRow withObject:newDict];
    [self saveEventActionArray];
}

- (AIListObject *)activeObject
{
    return activeContactObject;
}

- (void)reload:(AIListObject *)object usingCache:(BOOL)useCache
{
    if (object) //nil objects can't be loaded, clearly
    {
        NSMutableArray * newActionArray =  [[[NSMutableArray alloc] init] autorelease];
        NSString * UID = [object UID];

        if (useCache)
            newActionArray = [cachedAlertsDict objectForKey:UID];

        if (!newActionArray) //not cached yet or not using cache
        {
            newActionArray = [[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:object]; //load from prefs
            if (newActionArray)
                [cachedAlertsDict setObject:newActionArray forKey:UID]; //cache it
            else
                [cachedAlertsDict removeObjectForKey:UID]; //pref is now clear - remove from our cache
        }

        if (!newActionArray)
            newActionArray = [[NSMutableArray alloc] init];

        if ([[object UID] compare:[activeContactObject UID]] == 0) //this is our currently active contact
        {
            [eventActionArray release];
            eventActionArray = newActionArray;
            [eventActionArray retain];
        }
    }
}

//Actions!
- (NSMenu *)actionListMenu //menu of possible actions
{
    if (!actionListMenu_cached)
    {
        NSMenu		*actionListMenu = [[NSMenu alloc] init];
        NSMenuItem		*menuItem;

        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Play a sound"
                                               target:self
                                               action:@selector(actionPlaySound:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:@"Sound"];
        [actionListMenu addItem:menuItem];

        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Send a message"
                                               target:self
                                               action:@selector(actionSendMessage:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:@"Message"];
        [actionListMenu addItem:menuItem];

        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Show an alert"
                                               target:self
                                               action:@selector(actionDisplayAlert:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:@"Alert"];
        [actionListMenu addItem:menuItem];

        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Bounce the dock"
                                               target:self
                                               action:@selector(actionBounceDock:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:@"Bounce"];
        [actionListMenu addItem:menuItem];

        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Speak text"
                                               target:self
                                               action:@selector(actionSpeakText:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:@"Speak"];
        [actionListMenu addItem:menuItem];

        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Open empty message window"
                                               target:self
                                               action:@selector(actionOpenMessage:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:@"Open Message"];
        [actionListMenu addItem:menuItem];

        actionListMenu_cached = actionListMenu;
    }

    return(actionListMenu_cached);
}

//setup display for displaying an alert
- (IBAction)actionDisplayAlert:(id)sender
{   	[self configureForTextDetails:@"Alert text:"];		}

    //setup display for speaking text
- (IBAction)actionSpeakText:(id)sender
{    [self configureForTextDetails:@"Text to speak:"];		}

    //setup display for playing a sound
- (IBAction)actionPlaySound:(id)sender
{    [self configureForMenuDetails:@"Sound to play:" menuToDisplay:[self soundListMenu]];	}

    //setup display for bouncing the dock
- (IBAction)actionBounceDock:(id)sender
{    [self configureForMenuDetails:@"Dock behavior:" menuToDisplay:[self behaviorListMenu]];	}

    //setup display for opening message window
- (IBAction)actionOpenMessage:(id)sender
{
    NSMutableDictionary * detailsDict;

    [selectedActionDict setObject:[NSNumber numberWithInt:1] forKey:KEY_EVENT_DETAILS_UNIQUE]; //will save at end of function

    detailsDict = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS_DICT];

    [popUp_actionDetails_open_message setMenu:[self accountForOpenMessageMenu]];
    if (!detailsDict) //new message
    {
        [button_anotherAccount_open_message setState:NSOnState]; //default: use another account if needed

        NSEnumerator * accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
        AIAccount * account;
        while( (account = [accountEnumerator nextObject]) && ([[account propertyForKey:@"Status"] intValue] == STATUS_OFFLINE) );
        if (account) //if we found an online account, set it as the default account choice
        {
            NSString * accountID = [account accountID];
            [popUp_actionDetails_open_message selectItemAtIndex: [popUp_actionDetails_open_message indexOfItemWithRepresentedObject:account]]; //set the menu view

            [selectedActionDict setObject:accountID forKey:KEY_EVENT_DETAILS]; //will save at end of function
        }
        [self saveOpenMessageDetails:nil];
    }
    else //restore the old settings
    {
        //Restore the account
        AIAccount * account = [[owner accountController] accountWithID:[[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS]];
        [popUp_actionDetails_open_message selectItemAtIndex:[popUp_actionDetails_open_message indexOfItemWithRepresentedObject:account]];
        [button_anotherAccount_open_message setState:[[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]];
    }

    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
    [self saveEventActionArray];

    [self configureWithSubview:view_details_open_message];
}

//setup display for sending a message
- (IBAction)actionSendMessage:(id)sender
{
    NSString *details = [[[NSString alloc] init]autorelease];
    NSMutableDictionary * detailsDict;

    details = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS];

    if ([[selectedActionDict objectForKey:KEY_EVENT_DETAILS_UNIQUE] intValue])
    {
        details = @"";
        [selectedActionDict setObject:@"" forKey:KEY_EVENT_DETAILS];
        [selectedActionDict setObject:[NSNumber numberWithInt:0] forKey:KEY_EVENT_DETAILS_UNIQUE];
        [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
        [self saveEventActionArray];
    }

    [textField_message_actionDetails setStringValue:(details ? details : @"")];
    [textField_message_actionDetails setDelegate:self];

    [popUp_message_actionDetails_one setMenu:[self accountMenu]];
    [popUp_message_actionDetails_two setMenu:[self sendToContactMenu]];

    detailsDict = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS_DICT];
    if (!detailsDict) //new message
    {
        [button_anotherAccount setState:NSOnState]; //default: use another account if needed
        [button_displayAlert setState:NSOffState]; //default: don't display an alert
        [popUp_message_actionDetails_two selectItemAtIndex:[popUp_message_actionDetails_two indexOfItemWithRepresentedObject:activeContactObject]]; //default: send to the current contact

        NSEnumerator * accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
        AIAccount * account;
        while( (account = [accountEnumerator nextObject]) && ([[account propertyForKey:@"Status"] intValue] == STATUS_OFFLINE) );
        if (account) //if we found an online account, set it as the default account choice
            [popUp_message_actionDetails_one selectItemAtIndex:[popUp_message_actionDetails_one indexOfItemWithRepresentedObject:account]];
        [self saveMessageDetails:nil];
    }
    else //restore the old settings
    {
        //Send from account:
        AIAccount * account = [[owner accountController] accountWithID:[detailsDict objectForKey:KEY_MESSAGE_SENDFROM]];
        [popUp_message_actionDetails_one selectItemAtIndex:[popUp_message_actionDetails_one indexOfItemWithRepresentedObject:account]];
        //Send message to:
        NSString * uid = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_UID];
        NSString * service = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_SERVICE];
        AIListContact * contact = [[owner contactController] contactInGroup:nil withService:service UID:uid];
        [popUp_message_actionDetails_two selectItemAtIndex:[popUp_message_actionDetails_two indexOfItemWithRepresentedObject:contact]];

        [button_anotherAccount setState:[[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]];
        [button_displayAlert setState:[[detailsDict objectForKey:KEY_MESSAGE_ERROR] intValue]];
    }

    [self configureWithSubview:view_details_message];
}

//Builds and returns an event menu
- (NSMenu *)eventMenu
{
    if (!eventMenu_cached)
    {
        NSMenu		*eventMenu = [[NSMenu alloc] init];

        //Add the static/display menu item
        [eventMenu addItemWithTitle:@"Add EventÉ" target:nil action:nil keyEquivalent:@""];

        //Add a menu item for each event
        [eventMenu addItem:[self eventMenuItem:@"Signed On" withDisplay:@"Signed On"]];
        [eventMenu addItem:[self eventMenuItem:@"Signed Off" withDisplay:@"Signed Off"]];
        [eventMenu addItem:[self eventMenuItem:@"Away" withDisplay:@"Went Away"]];
        [eventMenu addItem:[self eventMenuItem:@"!Away" withDisplay:@"Came Back From Away"]];
        [eventMenu addItem:[self eventMenuItem:@"Idle" withDisplay:@"Became Idle"]];
        [eventMenu addItem:[self eventMenuItem:@"!Idle" withDisplay:@"Became Unidle"]];
        [eventMenu addItem:[self eventMenuItem:@"Typing" withDisplay:@"Is Typing"]];
        [eventMenu addItem:[self eventMenuItem:@"UnviewedContent" withDisplay:@"Has Unviewed Content"]];
        [eventMenu addItem:[self eventMenuItem:@"Warning" withDisplay:@"Was Warned"]];
        eventMenu_cached = eventMenu;
    }
    return(eventMenu_cached);
}

-(IBAction)saveMessageDetails:(id)sender
{
    NSMutableDictionary *detailsDict = [[NSMutableDictionary alloc] init];

    AIAccount * account = [[popUp_message_actionDetails_one selectedItem] representedObject];
    [detailsDict setObject:[account accountID] forKey:KEY_MESSAGE_SENDFROM];
    AIListContact * contact = [[popUp_message_actionDetails_two selectedItem] representedObject];
    NSString * uid = [contact UID];
    NSString * service = [contact serviceID];
    [detailsDict setObject:uid forKey:KEY_MESSAGE_SENDTO_UID];
    [detailsDict setObject:service forKey:KEY_MESSAGE_SENDTO_SERVICE];

    [detailsDict setObject:[NSNumber numberWithInt:[button_anotherAccount state]] forKey:KEY_MESSAGE_OTHERACCOUNT];
    [detailsDict setObject:[NSNumber numberWithInt:[button_displayAlert state]] forKey:KEY_MESSAGE_ERROR];

    [selectedActionDict setObject:detailsDict forKey:KEY_EVENT_DETAILS_DICT];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    [self saveEventActionArray];
}

-(IBAction)saveOpenMessageDetails:(id)sender
{
    NSMutableDictionary *detailsDict = [[NSMutableDictionary alloc] init];
    [detailsDict setObject:[NSNumber numberWithInt:[button_anotherAccount_open_message state]] forKey:KEY_MESSAGE_OTHERACCOUNT];

    [selectedActionDict setObject:detailsDict forKey:KEY_EVENT_DETAILS_DICT];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    [self saveEventActionArray];
}

//Builds and returns a sound list menu - from AIEventSoundsPreferences.m
- (NSMenu *)soundListMenu
{
    if (!soundMenu_cached)
    {
        NSEnumerator	*enumerator;
        NSDictionary	*soundSetDict;
        NSMenu		*soundMenu = [[NSMenu alloc] init];

        enumerator = [[[owner soundController] soundSetArray] objectEnumerator];
        while((soundSetDict = [enumerator nextObject])){
            NSEnumerator	*soundEnumerator;
            NSString	*soundSetPath;
            NSString	*soundPath;
            NSMenuItem	*menuItem;

            //Add an item for the set
            if([soundMenu numberOfItems] != 0){
                [soundMenu addItem:[NSMenuItem separatorItem]]; //Divider
            }
            soundSetPath = [soundSetDict objectForKey:KEY_SOUND_SET];
            menuItem = [[[NSMenuItem alloc] initWithTitle:[soundSetPath lastPathComponent]
                                                   target:nil
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
            [menuItem setEnabled:NO];
            [soundMenu addItem:menuItem];

            //Add an item for each sound
            soundEnumerator = [[soundSetDict objectForKey:KEY_SOUND_SET_CONTENTS] objectEnumerator];
            while((soundPath = [soundEnumerator nextObject])){
                NSImage	*soundImage;
                NSString	*soundTitle;

                //Get the sound title and image
                soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
                soundImage = [[NSWorkspace sharedWorkspace] iconForFile:soundPath];
                [soundImage setSize:NSMakeSize(SOUND_MENU_ICON_SIZE,SOUND_MENU_ICON_SIZE)];

                //Build the menu item
                menuItem = [[[NSMenuItem alloc] initWithTitle:soundTitle
                                                       target:self
                                                       action:@selector(selectSound:)
                                                keyEquivalent:@""] autorelease];
                [menuItem setRepresentedObject:soundPath];
                [menuItem setImage:soundImage];

                [soundMenu addItem:menuItem];
            }
        }
        [soundMenu setAutoenablesItems:NO];
        soundMenu_cached = soundMenu;
    }
    return(soundMenu_cached);
}
//Select a sound from one of the sound popUp menus
- (IBAction)selectSound:(id)sender
{
    NSString	*soundPath = [sender representedObject];

    if(soundPath != nil && [soundPath length] != 0){
        [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
    }

    [selectedActionDict setObject:soundPath forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    //Save event sound preferences
    [self saveEventActionArray];
}

//Builds and returns a dock behavior list menu
- (NSMenu *)behaviorListMenu
{
    NSMenu		*behaviorMenu = [[NSMenu alloc] init];

    //Build the menu items
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_ONCE withName:@"Once"]];
    [behaviorMenu addItem:[NSMenuItem separatorItem]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_REPEAT withName:@"Repeatedly"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY5 withName:@"Every 5 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY10 withName:@"Every 10 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY15 withName:@"Every 15 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY30 withName:@"Every 30 Seconds"]];
    [behaviorMenu addItem:[self menuItemForBehavior:BOUNCE_DELAY60 withName:@"Every Minute"]];

    [behaviorMenu setAutoenablesItems:NO];

    return(behaviorMenu);
}

- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name
{
    NSMenuItem		*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:name
                                           target:self
                                           action:@selector(selectBehavior:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[[NSNumber numberWithInt:behavior] stringValue]];

    return(menuItem);
}

//The user selected a behavior
- (IBAction)selectBehavior:(id)sender
{
    NSString	*behavior = [sender representedObject];

    [selectedActionDict setObject:behavior forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    //Save event preferences
    [self saveEventActionArray];
}

- (IBAction)selectAccount:(id)sender
{
    AIAccount * account = [sender representedObject];
    NSString * accountID = [account accountID];

    [selectedActionDict setObject:accountID forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    //Save event preferences
    [self saveEventActionArray];
}

//builds an alphabetical menu of contacts for all online accounts; online contacts are sorted to the top and seperated
//from offline ones by a seperator reading "Offline"
//uses alphabeticalGroupOfflineSort and calls saveMessageDetails: when a selection is made
- (NSMenu *)sendToContactMenu
{
    NSMenu		*contactMenu = [[NSMenu alloc] init];
    //Build the menu items
    NSMutableArray		*contactArray =  [[owner contactController] allContactsInGroup:nil subgroups:YES];
    if ([contactArray count])
    {
        [contactArray sortUsingFunction:alphabeticalGroupOfflineSort context:nil]; //online buddies will end up at the top, alphabetically

        NSEnumerator 	*enumerator = 	[contactArray objectEnumerator];
        AIListObject	*contact;
        NSString 	*groupName = [[[NSString alloc] init] autorelease];
        BOOL		firstOfflineSearch = NO;

        while (contact = [enumerator nextObject])
        {
            NSMenuItem		*menuItem;
            NSString	 	*itemDisplay;
            NSString		*itemUID = [contact UID];
            itemDisplay = [contact displayName];
            if ( !([itemDisplay compare:itemUID] == 0) ) //display name and screen name aren't the same
                itemDisplay = [NSString stringWithFormat:@"%@ (%@)",itemDisplay,itemUID]; //show the UID along with the display name
            menuItem = [[[NSMenuItem alloc] initWithTitle:itemDisplay
                                                   target:self
                                                   action:@selector(saveMessageDetails:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:contact];

            if ([groupName compare:[[contact containingGroup] displayName]] != 0)
            {
                NSMenuItem	*groupItem;
                if ([contactMenu numberOfItems] > 0) [contactMenu addItem:[NSMenuItem separatorItem]];
                groupItem = [[[NSMenuItem alloc] initWithTitle:[[contact containingGroup] displayName]
                                                        target:nil
                                                        action:nil
                                                 keyEquivalent:@""] autorelease];
                //[groupItem setRepresentedObject:[contact containingGroup]];
                [groupItem setEnabled:NO];
                [contactMenu addItem:groupItem];
                firstOfflineSearch = YES; //start searching for an offline contact
            }

            if (firstOfflineSearch)
            {
                if ( !([[contact statusArrayForKey:@"Online"] greatestIntegerValue]) ) //look for the first offline contact
                {
                    NSMenuItem	*separatorItem;
                    separatorItem = [[[NSMenuItem alloc] initWithTitle:@"Offline"
                                                                target:nil
                                                                action:nil
                                                         keyEquivalent:@""] autorelease];
                    [separatorItem setEnabled:NO];
                    [contactMenu addItem:separatorItem];
                    firstOfflineSearch = NO;
                }
            }

            [contactMenu addItem:menuItem];

            groupName = [[contact containingGroup] displayName];
        }
        [contactMenu setAutoenablesItems:NO];
    }
    return contactMenu;
}



int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];


    NSString  	*groupNameA = [[objectA containingGroup] displayName];
    NSString  	*groupNameB = [[objectB containingGroup] displayName];
    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }
    else if ([groupNameA compare:groupNameB] == 0)
    {
        if(invisibleA && !invisibleB){
            return(NSOrderedDescending);
        }else if(!invisibleA && invisibleB){
            return(NSOrderedAscending);
        }else{
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
        }
    }
    else
        return([groupNameA caseInsensitiveCompare:groupNameB]);
}



- (NSMenu *)accountMenu
{
    NSEnumerator * accountEnumerator;
    AIAccount * account;
    NSMenu * accountMenu = [[NSMenu alloc] init];

    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while(account = [accountEnumerator nextObject]){
        NSMenuItem 	*menuItem;
        NSString	*accountDescription;
        accountDescription = [account accountDescription];
        menuItem = [[[NSMenuItem alloc] initWithTitle:accountDescription
                                               target:self
                                               action:@selector(saveMessageDetails:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [accountMenu addItem:menuItem];
    }

    return accountMenu;
}

- (NSMenu *)accountForOpenMessageMenu
{
    NSEnumerator * accountEnumerator;
    AIAccount * account;
    NSMenu * accountMenu = [[NSMenu alloc] init];

    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while(account = [accountEnumerator nextObject]){
        NSMenuItem 	*menuItem;
        NSString	*accountDescription;
        accountDescription = [account accountDescription];
        menuItem = [[[NSMenuItem alloc] initWithTitle:accountDescription
                                               target:self
                                               action:@selector(selectAccount:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [accountMenu addItem:menuItem];
    }

    return accountMenu;
}

//Save the event actions (contact context sensitive)
- (void)saveEventActionArray
{
    [[owner preferenceController] setPreference:eventActionArray forKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:activeContactObject];
}


//Called by the event popUp menu (Inserts a new event)
- (IBAction)newEvent:(id)sender
{
    NSMutableDictionary	*actionDict;
    NSString * event = [[sender representedObject] objectForKey:KEY_EVENT_NOTIFICATION];
    actionDict = [[NSMutableDictionary alloc] init];
    if ( [event hasPrefix:@"!"] ) //negative status
    {
        event = [event stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"!"]];
        [actionDict setObject:@"0" forKey:KEY_EVENT_STATUS];
    }
    else
        [actionDict setObject:@"1" forKey:KEY_EVENT_STATUS];

    //Add the new event
    [actionDict setObject:[[sender representedObject] objectForKey:KEY_EVENT_DISPLAYNAME] forKey:KEY_EVENT_DISPLAYNAME];
    [actionDict setObject:event forKey:KEY_EVENT_NOTIFICATION];
    [actionDict setObject:@"Sound" forKey:KEY_EVENT_ACTION]; //Sound is default action
    [actionDict setObject:[NSNumber numberWithInt:NSOffState] forKey:KEY_EVENT_DELETE]; //default to recurring events
    [actionDict setObject:[NSNumber numberWithInt:NSOffState] forKey:KEY_EVENT_ACTIVE]; //default to ignore active/inactive
    [eventActionArray addObject:actionDict];

    [self saveEventActionArray];

    [tableView_actions selectRow:([eventActionArray count]-1) byExtendingSelection:NO]; //select the new event

    if ([[tableView_actions dataSource] respondsToSelector:@selector(addedEvent:)])
        [[tableView_actions dataSource] performSelector:@selector(addedEvent:) withObject:self];

    //Update the outline view
    [tableView_actions reloadData];

}

- (void)configureForTextDetails:(NSString *)instructions
{
    NSString *details =  [[[NSString alloc] init] autorelease];

    details = [[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS];
    if ([[selectedActionDict objectForKey:KEY_EVENT_DETAILS_UNIQUE] intValue])
    {
        details = @"";
        [selectedActionDict setObject:@"" forKey:KEY_EVENT_DETAILS];
        [selectedActionDict setObject:[NSNumber numberWithInt:0] forKey:KEY_EVENT_DETAILS_UNIQUE];
        [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
        [self saveEventActionArray];
    }

    [textField_description_textField setStringValue:instructions];

    [textField_actionDetails setDelegate:self];
    [textField_actionDetails setStringValue:(details ? details : @"")];

    [self configureWithSubview:view_details_text];
}

- (void)configureForMenuDetails:(NSString *)instructions menuToDisplay:(NSMenu *)detailsMenu
{
    [selectedActionDict setObject:[NSNumber numberWithInt:1] forKey:KEY_EVENT_DETAILS_UNIQUE];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
    [self saveEventActionArray];

    [textField_description_popUp setStringValue:instructions];
    [popUp_actionDetails setMenu:detailsMenu];
    [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:[[eventActionArray objectAtIndex:row] objectForKey:KEY_EVENT_DETAILS]]];

    [self configureWithSubview:view_details_menu];
}

- (void)configureWithSubview:(NSView *)view_inView
{
    if (!view_inView) view_inView = view_blank; //pass nil to signify the blank subview

    int 	heightChange = [view_inView frame].size.height - [[[view_main subviews] objectAtIndex:0] frame].size.height;
    NSView * oldView = [[view_main subviews] objectAtIndex:0];
    [view_main replaceSubview:oldView with:view_blank];

    NSRect	containerFrame = [[view_main window] frame];

    NSSize	minimumSize = [[view_main window] minSize];
    containerFrame.size.height += heightChange;
    containerFrame.origin.y -= heightChange;
    minimumSize.height += heightChange;

    [[view_main window] setFrame:containerFrame display:YES animate:NO];
    [[view_main window] setMinSize:minimumSize];

    if (view_pref != nil)
    {
        containerFrame = [view_pref frame];
        containerFrame.size.height += heightChange;
        containerFrame.origin.y -= heightChange;
        [view_pref setFrame:containerFrame];

        containerFrame = [[[view_pref superview] superview] frame];
        containerFrame.size.height += heightChange;
        [[[view_pref superview] superview] setFrame:containerFrame];
        [view_pref setFrameOrigin:NSMakePoint(0,0)];
        [[[view_pref superview] superview] setNeedsDisplay:YES];

    }

    [view_main replaceSubview:view_blank with:view_inView];
    [view_main setFrameSize:[view_inView frame].size];
    [view_main setNeedsDisplay:YES];

}

- (void)removeAllSubviews:(NSView *)view
{
    NSArray 	* subviewsArray = [view subviews];
    NSEnumerator * enumerator = [subviewsArray objectEnumerator];
    NSView 	* theSubview;
    NSRect	containerFrame = [[view_main window] frame];
    NSSize	minimumSize = [[view_main window] minSize];
    int	 	heightChange;

    while (theSubview = [enumerator nextObject])
    {
        heightChange = -[theSubview frame].size.height;
        containerFrame.size.height += heightChange;
        containerFrame.origin.y -= heightChange;
        minimumSize.height += heightChange;
        [theSubview removeFromSuperviewWithoutNeedingDisplay];
    }
    [[view_main window] setFrame:containerFrame display:YES animate:YES];
    [[view_main window] setMinSize:minimumSize];
}



//used for each item of the eventMenu
-(NSMenuItem *)eventMenuItem:(NSString *)event withDisplay:(NSString *)displayName
{
    NSMenuItem *menuItem;
    NSMutableDictionary *menuDict;

    menuItem = [[[NSMenuItem alloc] initWithTitle:displayName
                                           target:self
                                           action:@selector(newEvent:)
                                    keyEquivalent:@""] autorelease];
    menuDict = [[[NSMutableDictionary alloc] init] retain];
    [menuDict setObject:displayName 	forKey:KEY_EVENT_DISPLAYNAME];
    [menuDict setObject:event 		forKey:KEY_EVENT_NOTIFICATION];
    [menuItem setRepresentedObject:menuDict];
    return menuItem;
}

//Delete the selected action
-(IBAction)deleteEventAction:(id)sender
{
    //Remove the event
    [eventActionArray removeObjectAtIndex:row];

    //Save event sound preferences
    [self saveEventActionArray];

    //Update the outline view
    [tableView_actions reloadData];
}

//editing is over - save in KEY_EVENT_DETAILS
//- (void)controlTextDidEndEditing:(NSNotification *)notification
- (void)controlTextDidChange:(NSNotification *)notification
{
    [selectedActionDict setObject:[[notification object] stringValue] forKey:KEY_EVENT_DETAILS];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];
    [self saveEventActionArray];
}

- (void)oneTimeEvent:(NSButton *)inButton
{
    [selectedActionDict setObject:[NSNumber numberWithInt:[inButton state]] forKey:KEY_EVENT_DELETE];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    [self saveEventActionArray];
}

- (void)onlyWhileActive:(NSButton *)inButton
{
    [selectedActionDict setObject:[NSNumber numberWithInt:[inButton state]] forKey:KEY_EVENT_ACTIVE];
    [eventActionArray replaceObjectAtIndex:row withObject:selectedActionDict];

    [self saveEventActionArray];
}

- (void)oneTimeEventFired:(NSNotification *)notification
{
    [self reload:[notification object] usingCache:NO];

    if ([[tableView_actions dataSource] respondsToSelector:@selector(anInstanceChanged:)])
        [[tableView_actions dataSource] performSelector:@selector(anInstanceChanged:) withObject:nil];
    [tableView_actions reloadData];
}

//determine if two instances of ESContactAlerts refer to the same contact
- (BOOL)isEqual:(id)inInstance
{
    BOOL contactTest = ( [[activeContactObject UIDAndServiceID] compare:[[inInstance activeObject] UIDAndServiceID]] == 0 );
    return contactTest;
}

//hash string is simply based on the UIDAndServiceID's NSString hash
- (unsigned) hash
{
    return ( [[activeContactObject UIDAndServiceID] hash] );
}
@end
