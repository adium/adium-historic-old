//
//  AIStatusSelectionView.m
//  Adium
//
//  Created by Adam Iser on Sat Jul 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIStatusSelectionView.h"

#define PREF_GROUP_AWAY_MESSAGES 	@"Away Messages"
#define KEY_SAVED_AWAYS			@"Saved Away Messages"

#define STATUS_SELECTION_NIB		@"StatusSelectionView"
#define MENU_AWAY_DISPLAY_LENGTH	30

#define STATUS_NAME_AVAILABLE		@"Available"
#define STATUS_NAME_OFFLINE		@"Offline"
#define STATUS_NAME_CONNECTING		@"ConnectingÉ"

@interface AIStatusSelectionView (PRIVATE)
- (void)configureView;
- (void)configureStatusMenu;
- (void)updateMenu;
- (void)_appendAwaysFromArray:(NSArray *)awayArray toMenu:(NSMenu *)awayMenu;
- (void)accountListChanged:(NSNotification *)notification;
- (void)accountPropertiesChanged:(NSNotification *)notification;
@end

@implementation AIStatusSelectionView

- (id)initWithFrame:(NSRect)frameRect owner:(id)inOwner
{
    [super initWithFrame:frameRect];

    //init
    owner = [inOwner retain];
    [self configureView];
    [self configureStatusMenu];

    //Observe account status changed notification
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountPropertiesChanged:) name:Account_PropertiesChanged object:nil];
    [self accountPropertiesChanged:nil];
    
    return(self);
}

- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self];
    [owner release];

    [super dealloc];
}

//Load and configure our contents
- (void)configureView
{
    NSEnumerator	*enumerator;
    NSView		*view;
    NSArray		*viewArray;

    //Load our contents
    [NSBundle loadNibNamed:STATUS_SELECTION_NIB owner:self];

    //Set our height correctly (width is flexible)
    [self setFrameSize:NSMakeSize([self frame].size.width, [view_contents frame].size.height)];

    //Transfer the contents to our view
    viewArray = [[[view_contents subviews] copy] autorelease];
    enumerator = [viewArray objectEnumerator];
    while((view = [enumerator nextObject])){
        [view retain];
        [view removeFromSuperview];
        [self addSubview:view];

        [view resizeWithOldSuperviewSize:[view_contents frame].size];
        [view release];
    }
    [view_contents release];

    //Correctly size our popup (IB won't let us make it this small normally)
    [popUp_status setFrameSize:NSMakeSize([popUp_status frame].size.width, 14)];

    //Observe preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    //
    [[popUp_status menu] setAutoenablesItems:NO];
}

//Update our menu if the away list changes
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_AWAY_MESSAGES] == 0 &&
       [(NSString *)[[notification userInfo] objectForKey:@"Key"] compare:KEY_SAVED_AWAYS] == 0){
        [self configureStatusMenu]; //Rebuild our status menu
    }
}

//Configures the status menu
- (void)configureStatusMenu
{
    NSMenu		*popUpMenu = [popUp_status menu];
    NSMenuItem		*menuItem;
    NSArray		*awayArray;

    //remove any existing menu items
    [popUpMenu removeAllItemsButFirst];

    //Available
    menuItem = [[NSMenuItem alloc] initWithTitle:STATUS_NAME_AVAILABLE target:self action:@selector(selectNewStatus:) keyEquivalent:@""];
    [popUpMenu addItem:menuItem];
    [popUpMenu addItem:[NSMenuItem separatorItem]];
    
    //Away messages
    //We read these on our own for now.  This status menu is so specialized and would be silly without away messages, so hard coding it to the away plugin's preferences shouldn't be an issue.
    awayArray = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    [self _appendAwaysFromArray:awayArray toMenu:popUpMenu];

    //Offline
    [popUpMenu addItem:[NSMenuItem separatorItem]];
    menuItem = [[NSMenuItem alloc] initWithTitle:STATUS_NAME_OFFLINE target:self action:@selector(selectNewStatus:) keyEquivalent:@""];
    [popUpMenu addItem:menuItem];

    //Update our menu's selection
    [self updateMenu];
}

//User selected a new status from the menu
- (IBAction)selectNewStatus:(id)sender
{
    NSDictionary	*representedObject = [sender representedObject];
    NSString		*title = [sender title];
    
    if(representedObject){ //Away
	NSAttributedString	*awayMessage = [representedObject objectForKey:@"Message"];
	NSAttributedString	*awayAutoResponse = [representedObject objectForKey:@"Autoresponse"];
	[[owner accountController] setProperty:awayMessage forKey:@"AwayMessage" account:nil];
        [[owner accountController] setProperty:awayAutoResponse forKey:@"Autoresponse" account:nil];

    }else if([title compare:STATUS_NAME_AVAILABLE] == 0){ //Available
        [[owner accountController] setProperty:nil forKey:@"AwayMessage" account:nil];
        NSLog(@"available");
        
    }else if([title compare:STATUS_NAME_OFFLINE] == 0){ //Offline
	[[owner accountController] disconnectAllAccounts];
	NSLog(@"offline");
    }
}

- (void)_appendAwaysFromArray:(NSArray *)awayArray toMenu:(NSMenu *)awayMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*awayDict;

    //Add a menu item for each away message
    enumerator = [awayArray objectEnumerator];
    while((awayDict = [enumerator nextObject])){
        if([(NSString *)[awayDict objectForKey:@"Type"] compare:@"Away"] == 0){
            NSMenuItem		*menuItem;
	    
            NSString *away = [awayDict objectForKey:@"Title"]; 
	    if (!away) //no title found, then use the message
		away = [[NSAttributedString stringWithData:[awayDict objectForKey:@"Message"]] string];

            //Cap the away menu title (so they're not incredibly long)
            if([away length] > MENU_AWAY_DISPLAY_LENGTH){
                away = [[away substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:@"É"];
            }

            menuItem = [[NSMenuItem alloc] initWithTitle:away target:self action:@selector(selectNewStatus:) keyEquivalent:@""];
            [menuItem setRepresentedObject:awayDict];
            [awayMenu addItem:menuItem];
        }
    }
}

//
- (void)updateMenu
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    int			onlineAccounts = 0;
    int			connectingAccounts = 0;
    int			awayMessageIndex = 0;
    NSData		*awayMessageData;
    NSMenuItem		*menuItem;
    NSMenuItem		*selectedMenuItem = nil;

    //Get the number of accounts that are online, or connecting
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        int status = [[account propertyForKey:@"Status"] intValue];

        if(status == STATUS_ONLINE){
            onlineAccounts++;
        }else if(status == STATUS_CONNECTING){
            connectingAccounts++;
        }
    }

    //Get the current away message
    awayMessageData = [[owner accountController] propertyForKey:@"AwayMessage" account:nil];
    if(awayMessageData){
        //Determine the selected away message's menu item index
        enumerator = [[[popUp_status menu] itemArray] objectEnumerator];
        while(menuItem = [enumerator nextObject]){
            NSDictionary	*awayDict = [menuItem representedObject];

            if(awayDict && [awayMessageData isEqualToData:[awayDict objectForKey:@"Message"]]) break;
            awayMessageIndex++;
        }        
    }
    
    //Get and select the active menu item
    if(connectingAccounts){ //Connecting
        [popUp_status selectItem:nil];
        [popUp_status setTitle:STATUS_NAME_CONNECTING];
        selectedMenuItem = nil;

    }else if(onlineAccounts && awayMessageData){ //Away
        if(awayMessageIndex > 0 && awayMessageIndex < [[popUp_status menu] numberOfItems]){
            selectedMenuItem = (NSMenuItem *)[[popUp_status menu] itemAtIndex:awayMessageIndex];
        } else { //not a saved away message but away nonetheless
	    NSString * away = [[NSAttributedString stringWithData:awayMessageData] string];

            //Cap the away menu title (so they're not incredibly long)
            if([away length] > MENU_AWAY_DISPLAY_LENGTH){
                away = [[away substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:@"É"];
            }

	    //we're neither offline nor available, but selectItem:nil doesn't seem to uncheck things
	    [[[popUp_status menu] itemWithTitle:STATUS_NAME_OFFLINE] setState:NSOffState];
	    [[[popUp_status menu] itemWithTitle:STATUS_NAME_AVAILABLE] setState:NSOffState];
	    [popUp_status selectItem:nil];
	    [popUp_status setTitle:away];
	    selectedMenuItem = nil;
	}
	
        
    }else if(onlineAccounts){ //Online
        selectedMenuItem = (NSMenuItem *)[[popUp_status menu] itemWithTitle:STATUS_NAME_AVAILABLE];
        
    }else{ //Offline
        selectedMenuItem = (NSMenuItem *)[[popUp_status menu] itemWithTitle:STATUS_NAME_OFFLINE];
        
    }
    
    if(selectedMenuItem) { [popUp_status selectItem:selectedMenuItem];

    //Update the 'Checked' menu item
    enumerator = [[[popUp_status menu] itemArray] objectEnumerator];
    while(menuItem = [enumerator nextObject]){
        if([menuItem representedObject] == selectedMenuItem){
            [menuItem setState:NSOnState];
        }else{
            [menuItem setState:NSOffState];
        }
    }
    }
    
    //Both available and offline have no represented object, but one should be checked and the other off if one is selected.
    if ( selectedMenuItem == [[popUp_status menu] itemWithTitle:STATUS_NAME_AVAILABLE])
    {
	[[[popUp_status menu] itemWithTitle:STATUS_NAME_AVAILABLE] setState:NSOnState];
	[[[popUp_status menu] itemWithTitle:STATUS_NAME_OFFLINE] setState:NSOffState];
    } else if ( selectedMenuItem == [[popUp_status menu] itemWithTitle:STATUS_NAME_OFFLINE])
    {
	[[[popUp_status menu] itemWithTitle:STATUS_NAME_OFFLINE] setState:NSOnState];
	[[[popUp_status menu] itemWithTitle:STATUS_NAME_AVAILABLE] setState:NSOffState];
    }
    
    //Size the menu to fit
    [popUp_status sizeToFit];
}

- (void)accountListChanged:(NSNotification *)notification
{
    [self updateMenu];
}

- (void)accountPropertiesChanged:(NSNotification *)notification
{
    [self updateMenu];
}

@end




