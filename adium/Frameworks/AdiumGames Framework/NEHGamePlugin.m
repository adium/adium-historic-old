//
//  NEHGamePlugin.m
//  Adium
//
//  Created by Nelson Elhage on Sun Jan 18 2004.
//

#import "NEHGamePlugin.h"
#import "NEHGameController.h"

#define MENU_INVITE		AILocalizedString(@"Invite to play game","Contextual menu item to invite someone to a game.")
#define MENU_NEWGAME	AILocalizedString(@"New Game","File Menu Item.")

#define CONTACT_NOT_FOUND			AILocalizedString(@"Contact Not Found","")
#define CONTACT_NOT_FOUND_MESSAGE   AILocalizedString(@"Unable to find contact '%@'","")

@implementation NEHGamePlugin

static NSMenuItem		* menuItem_newGame;
static NSMenuItem		*menuItem_invite;
static NSMenu			*menu_Games;

- (void)installPlugin
{
	//Initialize the global menus
	if(menu_Games == nil) {
		menu_Games = [[[NSMenu alloc] initWithTitle:@""] autorelease];
		
		menuItem_newGame = [[[NSMenuItem alloc] initWithTitle:MENU_NEWGAME
													   action:NULL 
												keyEquivalent:@""] autorelease];
		menuItem_invite = [[[NSMenuItem alloc] initWithTitle:MENU_INVITE
													  action:NULL 
											   keyEquivalent:@""] autorelease];
		[menuItem_newGame setSubmenu:menu_Games];
		[menuItem_invite setSubmenu:menu_Games];
		
		[[adium menuController] addContextualMenuItem:menuItem_invite toLocation:Context_Contact_Manage];
		[[adium menuController] addMenuItem:menuItem_newGame toLocation:LOC_File_New];
	}
	
	prefixString = [[NSString stringWithFormat:@"[%@/",[self gameShortName]] retain];
	
	menuItem_game = [[[NSMenuItem alloc] initWithTitle:[self gameLongName]
							target:self action:@selector(newGame:) keyEquivalent:@""] autorelease];
	[menu_Games addItem:menuItem_game];					
	
	
	windowController = nil;
	
	gamesForAccounts = [[NSMutableDictionary alloc] init];
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterIncoming];
}

- (void)uninstallPlugin
{
	[prefixString release]; prefixString = nil;
	[gamesForAccounts release]; gamesForAccounts = nil;
	[windowController release]; windowController = nil;
//	[[adium contentController] unregisterIncomingContentFilter:self];
}

- (void)endGameWith:(AIListContact*)contact fromAccount:(AIAccount*)account;
{
	[[gamesForAccounts objectForKey:[account uniqueObjectID]]
			removeObjectForKey:[contact uniqueObjectID]];
}

- (IBAction)newGame: (id)sender
{
	[self ensureGameNibIsLoaded];
	
	NSEnumerator		*enumerator;
    AIListContact		*contact;

	//Autofill the contact field is a contact is currently selected
	AIListObject   *selectedContact = [[adium contactController] selectedListObject];
	if(selectedContact && [selectedContact isKindOfClass:[AIListContact class]])
		[textField_handle setStringValue:[selectedContact UID]];
	
	[windowController showWindow:nil];
	    
    //Configure the auto-complete view
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while((contact = [enumerator nextObject])){
        [textField_handle addCompletionString:[contact UID]];
    }

    //Configure the handle type menu
    [popUp_account setMenu:[[adium accountController] menuOfAccountsWithTarget:self]];

    //Select the last used account / Available online account
	int index = [popUp_account indexOfItemWithRepresentedObject:[[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil]];
    if(index < [popUp_account numberOfItems] && index >= 0){
		[popUp_account selectItemAtIndex:index];
	}
}

- (void)ensureGameNibIsLoaded
{
	if (!window_newGame){
		[NSBundle loadNibNamed:[self nibName] owner:self];
		
		windowController = [[NSWindowController alloc] initWithWindow:window_newGame];
		[window_newGame setWindowController:windowController];
	}
}

- (IBAction)selectAccount:(id)sender
{
}

- (IBAction)sendInvite:(id)sender
{
	[self ensureGameNibIsLoaded];
	
	[windowController close]; 
	
    NSString		*UID;
    AIServiceType	*serviceType;
	AIAccount		*account;
	AIListContact   *contact;

    //Get the service type and UID
    account = [[popUp_account selectedItem] representedObject];
    serviceType = [[account service] handleServiceType];
    UID = [serviceType filterUID:[textField_handle stringValue] removeIgnoredCharacters:YES];
        
    //Find the contact
	contact = [[adium contactController] contactWithService:[serviceType identifier] accountID:[account uniqueObjectID] UID:UID];
	NSMutableDictionary *contacts = [gamesForAccounts objectForKey:[account uniqueObjectID]];
	if(contacts == nil) {
		contacts = [[[NSMutableDictionary alloc] init] autorelease];
		[gamesForAccounts setObject:contacts forKey:[account uniqueObjectID]];
	}
	
	if(contact && [contacts objectForKey:[contact uniqueObjectID]]) {
		NSBeep();
		return;
		//TODO: Put an error message here, perhaps
	}
	
    if(contact){
		NEHGameController   *control;
		int play, playAs;
		
		play = [[radio_playAs selectedCell] tag];
		if(play == TAG_CHOOSE_PLAYER){
			play = (rand()%2 ? TAG_PLAYER_1: TAG_PLAYER_2);
		}
		
		playAs = ((play == TAG_PLAYER_1) ? FIRST_PLAYER : SECOND_PLAYER);
		
		control = [self newController];
		[self willSendInvitation:control];
		[control sendInvitation:playAs account:account contact:contact];
        [contacts setObject:control	forKey:[contact uniqueObjectID]];
    } else {
		NSRunAlertPanel(CONTACT_NOT_FOUND,[NSString stringWithFormat:CONTACT_NOT_FOUND_MESSAGE,[textField_handle stringValue]],BUTTON_ERR,nil,nil);
	}
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if([context isKindOfClass:[AIContentObject class]]){
		NSString		*str = [inAttributedString string];
		NSRange			start, end;
		
		if((((start = [str rangeOfString:prefixString]).location) == 0) &&
		   (((end = [str rangeOfString:@"]:"]).location) != NSNotFound)){
			
			AIContentObject		*inObj = context;
			NSRange				r;
			NSString			*type, *msg;
			AIListContact		*contact;
			AIAccount			*account;
			NSMutableDictionary *contacts;
			NEHGameController   *control;
			
			r.location = start.length;
			r.length = end.location - r.location;
			
			type = [str substringWithRange:r];
			
			if([str length] > end.location+end.length)
				msg = [str substringFromIndex:(end.location+end.length)];
			else
				msg = @"";
			
			[inObj setDisplayContent:NO];
			[inObj setTrackContent:NO];
			
			contact = [inObj source];
			account = [inObj destination];
			
			contacts = [gamesForAccounts objectForKey:[account uniqueObjectID]];
			if(!contacts){
				contacts = [[[NSMutableDictionary alloc] init] autorelease];
				[gamesForAccounts setObject:contacts forKey:[account uniqueObjectID]];
			}
			
			control = [contacts objectForKey:[contact uniqueObjectID]];
			
			if([type isEqualToString:MSG_TYPE_INVITE]) {
				if(control != nil) {
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
				[contacts setObject:control forKey:[contact uniqueObjectID]];
				
			} else if(control != nil) { 
				//We ignore non-invite messages from people with whom we don't have an open game
				[control handleMessage:msg ofType:type];
			}
		}
	}	
	
	//We don't change the attributed string
	//though we may have set the content object not to display or track anymore
	return inAttributedString;	
}

- (IBAction)cancelInvite:(id)sender
{
	[windowController close];
}

/*- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListContact	*selectedContact = [[adium menuController] contactualMenuContact];

	BOOL valid = (selectedContact && [selectedContact isKindOfClass:[AIListContact class]]);

    return(valid);
}*/

#pragma mark Stubs for things subclasses implement


//First, things subclasses absolutely must implement for this contraption to work at all
- (NEHGameController*)newController
{
	[self ensureGameNibIsLoaded];
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
