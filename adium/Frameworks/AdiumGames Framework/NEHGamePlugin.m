//
//  NEHGamePlugin.m
//  Adium XCode
//
//  Created by Nelson Elhage on Sun Jan 18 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NEHGamePlugin.h"
#import "NEHGameController.h"

#define MENU_INVITE		AILocalizedString(@"Invite to play %@","Contextual menu item to invite someone to a game.")
#define MENU_NEW		AILocalizedString(@"New %@ Game","File Menu Item.")

#define CONTACT_NOT_FOUND			AILocalizedString(@"Contact Not Found","")
#define CONTACT_NOT_FOUND_MESSAGE   AILocalizedString(@"Unable to find contact '%@'","")

@implementation NEHGamePlugin

static NSString * prefixString;

- (void)installPlugin
{
	prefixString = [[NSString stringWithFormat:@"[%@/",[self gameShortName]] retain];
	
	menuItem_invite = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:MENU_INVITE, [self gameLongName]]
							target:self action:@selector(newGame:) keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem_invite toLocation:Context_Contact_Manage];
	menuItem_newGame = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:MENU_NEW, [self gameLongName]] 
							target:self action:@selector(newGame:) keyEquivalent:@""] autorelease];
	[[adium menuController] addMenuItem:menuItem_newGame toLocation:LOC_File_New];
	
	[NSBundle loadNibNamed:[self nibName] owner:self];
	
	windowController = [[NSWindowController alloc] initWithWindow:window_newGame];
	[window_newGame setWindowController:windowController];
	
	gamesForAccounts = [[NSMutableDictionary alloc] init];
	[[adium contentController] registerIncomingContentFilter:self];
}

- (void)uninstallPlugin
{
	[prefixString release];
	[gamesForAccounts release];
	[windowController release];
	[[adium contentController] unregisterIncomingContentFilter:self];
}

- (void)endGameWith:(AIListContact*)contact fromAccount:(AIAccount*)account;
{
	[[gamesForAccounts objectForKey:[account UIDAndServiceID]]
			removeObjectForKey:[contact UIDAndServiceID]];
}

- (IBAction)newGame: (id)sender
{
	AIListObject   *selectedContact = [[adium contactController] selectedListObject];
	if(selectedContact)
		[textField_handle setStringValue:[selectedContact UID]];
	
	[windowController showWindow:nil];
	
	NSEnumerator		*enumerator;
    AIListContact		*contact;
    AIAccount			*account;
    
    //Configure the auto-complete view
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
    while((contact = [enumerator nextObject])){
        [textField_handle addCompletionString:[contact UID]];
    }

    //Configure the handle type menu
    [popUp_account removeAllItems];
    [[popUp_account menu] setAutoenablesItems:NO];

    //Insert a menu item for each available account
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        NSMenuItem	*menuItem;
        
        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:[account displayName] target:self action:@selector(selectAccount:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];

        //Disabled the menu item if the account is offline
        if(![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account]){
            [menuItem setEnabled:NO];
        }else{
            [menuItem setEnabled:YES];
        }

        //add the menu item
        [[popUp_account menu] addItem:menuItem];
    }

    //Select the last used account / Available online account
    [popUp_account selectItemAtIndex:[popUp_account indexOfItemWithRepresentedObject:[[adium accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil]]];
}

- (IBAction)selectAccount: (id)sender
{
}

- (IBAction)sendInvite:(id)sender
{
	[windowController close]; 
	
    NSString		*UID;
    AIServiceType	*serviceType;
	AIAccount		*account;
	AIListContact   *contact;

    //Get the service type and UID
    account = [[popUp_account selectedItem] representedObject];
    serviceType = [[account service] handleServiceType];
    UID = [serviceType filterUID:[textField_handle stringValue]];
        
    //Find the contact
	contact = [[adium contactController] contactWithService:[serviceType identifier] UID:UID];
	NSMutableDictionary * contacts = [gamesForAccounts objectForKey:[account UIDAndServiceID]];
	if(contacts == nil)
	{
		contacts = [[[NSMutableDictionary alloc] init] autorelease];
		[gamesForAccounts setObject:contacts forKey:[account UIDAndServiceID]];
	}
	if(contact && [contacts objectForKey:[contact UIDAndServiceID]])
	{
		NSBeep();
		return;
		//TODO: Put an error message here, perhaps
	}
	
    if(contact){
		int play = [[radio_playAs selectedCell] tag];
		if(play == TAG_CHOOSE_PLAYER) play = rand()%2?TAG_PLAYER_1:TAG_PLAYER_2;
		int playAs = (play == TAG_PLAYER_1)?FIRST_PLAYER:SECOND_PLAYER;
		NEHGameController * control = [self newController];
		[self willSendInvitation:control];
		[control sendInvitation:playAs account:account contact:contact];
        [contacts setObject:control	forKey:[contact UIDAndServiceID]];
    }
	else
	{
		NSRunAlertPanel(CONTACT_NOT_FOUND,[NSString stringWithFormat:CONTACT_NOT_FOUND_MESSAGE,[textField_handle stringValue]],BUTTON_ERR,nil,nil);
	}
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inobj
{
	NSString * str = [inAttributedString string];
	NSRange start = [str rangeOfString:prefixString];
	NSRange end = [str rangeOfString:@"]:"];
	if(start.location != 0 || end.location == NSNotFound)
		return inAttributedString;
	NSRange r;
	r.location = start.length;
	r.length = end.location - r.location;
	NSString * type = [str substringWithRange:r];
	NSString * msg;
	if([str length] > end.location+end.length)
		msg = [str substringFromIndex:(end.location+end.length)];
	else
		msg = @"";
		
	[inobj setDisplayContent:NO];
	[inobj setTrackContent:NO];
	
	AIListContact   * contact = [inobj source];
	AIAccount		* account = [inobj destination];
	
	NSMutableDictionary * contacts = [gamesForAccounts objectForKey:[account UIDAndServiceID]];
	if(contacts == nil)
	{
		contacts = [[[NSMutableDictionary alloc] init] autorelease];
		[gamesForAccounts setObject:contacts forKey:[account UIDAndServiceID]];
	}
	NEHGameController * control = [contacts objectForKey:[contact UIDAndServiceID]];
		
	if([type isEqualToString:MSG_TYPE_INVITE])
	{
		if(control != nil)
		{
			//We just got an invitation from someone we think we have a game open with
			//This means, probably, one of two things.
			//1) We got unsynced with them, and we shouldn't actually have a game open
			//		and thus ought to start a new game, or
			//2) The other guy is running multiple instances of Adium, or knows our
			//		protocol and wants to mess with us :)
			//It might make sense to drop our game and start a new one here,
			//but for now we'll just ignore this
			return inAttributedString;
		}
		control = [self newController];
		[control handleInvitation:msg account:account contact:contact];
		[contacts setObject:control forKey:[contact UIDAndServiceID]];
	}
	else if(control != nil)		//We ignore non-invite messages from people with whom we don't have an open game
	{
		[control handleMessage:msg ofType:type];
	}
	return inAttributedString;	
}

- (IBAction)cancelInvite:(id)sender
{
	[windowController close];
}

#pragma mark Stubs for things subclasses implement


//First, things subclasses absolutely must implement for this contraption to work at all
- (NEHGameController*)newController
{
	return nil;
}

- (NSString*)nibName
{
	return @"";
}

- (NSString*)gameLongName
{
	return @"";
}


//Overriding anything below this point is optional for extra flexibility

- (NSString*)gameShortName
{
	return [self gameLongName];
}

- (void)willSendInvitation:(NEHGameController*)control
{
}

- (void)willRespondToInvitation:(NEHGameController*)control
{
}

@end
