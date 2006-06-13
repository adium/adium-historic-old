//
//  RAFBlockEditorWindow.m
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "RAFBlockEditorWindowController.h"
#import "Adium/AIAccount.h"
#import "AIListContact.h"
#import "AIService.h"
#import "Adium/AIAccountController.h"
#import "Adium/ESDebugAILog.h"
#import "AIContactController.h"
#import <AIUtilities/AICompletingTextField.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

#define BLOCK_EDITOR_TITLE AILocalizedString(@"Privacy Settings","Privacy Settings window title")
#define BLOCK_DONE	AILocalizedString(@"Done","Done button for Privacy Settings")
#define BLOCK_BLOCK	AILocalizedString(@"Add","Add button for Privacy Settings")
#define BLOCK_CANCEL	AILocalizedString(@"Cancel","Cancel button for Privacy Settings")
#define BLOCK_ACCOUNT AILocalizedString(@"Account:",nil)
#define BLOCK_BUDDY AILocalizedString(@"Buddy:",nil)
#define BLOCK_BUDDY_COL AILocalizedString(@"Contact","Title of column containing user IDs of blocked contacts")
#define BLOCK_ACCOUNT_COL AILocalizedString(@"Account","Title of column containing blocking accounts")

@implementation RAFBlockEditorWindowController

static RAFBlockEditorWindowController *sharedInstance = nil;

+ (void)showWindow
{	
	if (sharedInstance == nil)
		sharedInstance = [[self alloc] initWithWindowNibName:@"BlockEditorWindow"];
	[sharedInstance showWindow:nil];
	[[sharedInstance window] makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)windowDidLoad
{
	[[self window] setTitle:BLOCK_EDITOR_TITLE];
	[doneButton setTitle:BLOCK_DONE];
	[cancelButton setTitle:BLOCK_CANCEL];
	[blockButton setTitle:BLOCK_BLOCK];
	[accountText setStringValue:BLOCK_ACCOUNT];
	[buddyText setStringValue:BLOCK_BUDDY];
	[[buddyCol headerCell] setTitle:BLOCK_BUDDY_COL];
	[[accountCol headerCell] setTitle:BLOCK_ACCOUNT_COL];
	
	
	[self willChangeValueForKey:@"listContents"];
	accountStates = [[NSMutableDictionary alloc] init];
	listContents = [[NSMutableArray alloc] init];

	NSMenu *tmpMenu = [[NSMenu alloc] init];
	NSMenu *tmpMainAcctsMenu = [[NSMenu alloc] init];
	[tmpMainAcctsMenu addItem:[[[NSMenuItem alloc] initWithTitle:@"All" action:NULL keyEquivalent:@""] autorelease]];
	AIAccount <AIAccount_Privacy> *account;
	NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIPrivacyOption currentState = AIPrivacyOptionUnknown;
	while((account = [enumerator nextObject])) {
		/* we can't do much with offline accounts and their block lists... */
		if([[account statusObjectForKey:@"Online"] boolValue] &&
		   [account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
			AIPrivacyOption accountState = [account privacyOptions];
			[accountStates setObject:[NSNumber numberWithInt: (int)accountState] forKey:[account UID]];
			if (currentState == AIPrivacyOptionUnknown)
				currentState = accountState;
			else if (accountState != currentState)
				currentState = AIPrivacyOptionCustom;
			if (accountState == AIPrivacyOptionDenyUsers)
				[listContents addObjectsFromArray:[account listObjectsOnPrivacyList:AIPrivacyTypeDeny]];
			else if (accountState == AIPrivacyOptionAllowUsers) {
				// if it's an allow list, we have to "invert" it so that it looks right.
				NSArray *tmpArr = [account listObjectsOnPrivacyList:AIPrivacyTypePermit];
				NSMutableArray *allContacts = [[account contacts] mutableCopy];
				[allContacts removeObjectsInArray:tmpArr];
				[listContents addObjectsFromArray:allContacts];
			}
			NSMenuItem *tmpItem = [[NSMenuItem alloc]
								initWithTitle:[account UID] action:NULL keyEquivalent:@""];
			[tmpItem setRepresentedObject:account];
			[tmpMainAcctsMenu addItem:[[tmpItem copy] autorelease]];
			[tmpMenu addItem:[tmpItem autorelease]];
		}
	}
	
	//build the menu of states
	NSMenu *stateMenu = [[NSMenu alloc] init];
	NSMenuItem *tmpItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Allow anyone", nil) action:NULL keyEquivalent:@""];
	[tmpItem setRepresentedObject:[NSNumber numberWithInt:AIPrivacyOptionAllowAll]];
	[stateMenu addItem:[tmpItem autorelease]];
	
	tmpItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Allow anyone on my contact list", nil) action:NULL keyEquivalent:@""];
	[tmpItem setRepresentedObject:[NSNumber numberWithInt:AIPrivacyOptionAllowContactList]];
	[stateMenu addItem:[tmpItem autorelease]];
	
	tmpItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Allow people on my contact list except those below", nil) action:NULL keyEquivalent:@""];
	[tmpItem setRepresentedObject:[NSNumber numberWithInt:AIPrivacyOptionAllowUsers]];
	[stateMenu addItem:[tmpItem autorelease]];
	
	tmpItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Deny below contacts", nil) action:NULL keyEquivalent:@""];
	[tmpItem setRepresentedObject:[NSNumber numberWithInt:AIPrivacyOptionDenyUsers]];
	[stateMenu addItem:[tmpItem autorelease]];
	
	tmpItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Custom settings for each account", nil) action:NULL keyEquivalent:@""];
	[tmpItem setRepresentedObject:[NSNumber numberWithInt:AIPrivacyOptionCustom]];
	[stateMenu addItem:[tmpItem autorelease]];
	
	[stateChooser setMenu:[stateMenu autorelease]];

	[stateChooser selectItemWithRepresentedObject:[NSNumber numberWithInt:currentState]];
	
	[self didChangeValueForKey:@"listContents"];
	listContentsAllAccounts = [listContents mutableCopy];

	[table registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs",nil]];
	
	[mainAccounts setMenu:[tmpMainAcctsMenu autorelease]];
	[accounts setMenu:[tmpMenu autorelease]];
	
	[self configTextField:self];
	
	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender
{
	AIAccount <AIAccount_Privacy> *account;
	AIListContact *contact;
	NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];

	//remove "unblocked" people
	while ((account = [enumerator nextObject])) {
		if ([account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
			AIPrivacyOption accountState = [[accountStates objectForKey:[account UID]] intValue];
			[account setPrivacyOptions:accountState];
			AIPrivacyType privType = AIPrivacyTypeDeny;
			if (accountState == AIPrivacyOptionAllowUsers) {
				//convert to NSSets and use set voodoo to do our bidding
				NSMutableSet *allContacts = [NSMutableSet setWithArray:[account contacts]];
				NSMutableSet *disallowedContacts = [NSMutableSet setWithArray:listContents];
				[disallowedContacts intersectSet:allContacts];
				[allContacts minusSet:disallowedContacts];				
				[listContents removeObjectsInArray:[disallowedContacts allObjects]];
				[listContents addObjectsFromArray:[allContacts allObjects]];
				privType = AIPrivacyTypePermit;
			}
			NSEnumerator *tmp=[[account listObjectsOnPrivacyList:privType] objectEnumerator];
			while((contact = [tmp nextObject])) {
				if( ![listContents containsObject:contact]) {
					[account removeListObject:contact fromPrivacyList:privType];
					[contact setIsBlocked:(AIPrivacyTypePermit == privType) updateList:NO];
				}
			}
		}
	}
	
	//"block" blocked people who aren't already
	enumerator = [listContents objectEnumerator];
	while ((contact = [enumerator nextObject])) {
		account = [contact account];
		AIPrivacyOption accountState = [[accountStates objectForKey:[account UID]] intValue];
		AIPrivacyType privState = AIPrivacyTypeDeny;
		if (accountState == AIPrivacyOptionAllowUsers)
			privState = AIPrivacyTypePermit;
		if ([account conformsToProtocol:@protocol(AIAccount_Privacy)] &&
			![[account listObjectsOnPrivacyList:accountState] containsObject:contact]) {
			[account addListObject:contact toPrivacyList:privState];
			[contact setIsBlocked:(AIPrivacyTypeDeny == privState) updateList:NO];
		}
	}
	sharedInstance = nil;
	AILog(@"Comitted blocking changes for all accounts");
	[super windowWillClose:sender];
	[self release];
}

- (IBAction)configTextField:(id)sender
{
	AIAccount *account = [[accounts selectedItem] representedObject];
	NSEnumerator		*enumerator;
    AIListContact		*contact;
	
	//Clear the completing strings
	[field setCompletingStrings:nil];
	
	//Configure the auto-complete view to autocomplete for contacts matching the selected account's service
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while ((contact = [enumerator nextObject])) {
		if ([contact service] == [account service]) {
			NSString *UID = [contact UID];
			[field addCompletionString:[contact formattedUID] withImpliedCompletion:UID];
			[field addCompletionString:[contact displayName] withImpliedCompletion:UID];
			[field addCompletionString:UID];
		}
    }
	
}

- (void)dealloc
{
	[listContents release];
	[super dealloc];
}

- (NSMutableArray*)listContents
{
	return listContents;
}

- (void)setListContents:(NSArray*)newList
{
	[listContents release];
	listContents = [newList mutableCopy];
}

- (IBAction)runBlockSheet:(id)sender
{
	[NSApp beginSheet:sheet 
	   modalForWindow:[self window]
		modalDelegate:self 
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)cancelBlockSheet: (id)sender
{
	[field setStringValue:@""];
    [NSApp endSheet:sheet];
}

- (IBAction)didBlockSheet: (id)sender
{
	[self blockFieldUID:sender];
	[field setStringValue:@""];
    [NSApp endSheet:sheet];
}


- (void)didEndSheet:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [theSheet orderOut:self];
}

- (IBAction)blockFieldUID:(id)sender
{
	AIListContact	*contact;
	AIAccount		*account;
	[self willChangeValueForKey:@"listContents"];
	account = [[accounts selectedItem] representedObject];
	contact = [self contactFromTextField];
	[listContents addObject:contact];
	[self didChangeValueForKey:@"listContents"];
}

- (AIListContact *)contactFromTextField
{
	AIListContact	*contact = nil;
	NSString		*UID = nil;
	AIAccount		*account = [[accounts selectedItem] representedObject];;
	
	id impliedValue = [field impliedValue];
	if ([impliedValue isKindOfClass:[AIMetaContact class]]) {
		contact = impliedValue;
		
	} else if ([impliedValue isKindOfClass:[AIListContact class]]) {
		UID = [(AIListContact *)impliedValue UID];
		
	} else  if ([impliedValue isKindOfClass:[NSString class]]) {
		UID = [[account service] filterUID:impliedValue removeIgnoredCharacters:YES];
	}
	
	if (!contact && UID) {
		//Find the contact
		contact = [[adium contactController] contactWithService:[account service]
														account:account 
															UID:UID];		
	}
	
	return contact;
}

- (IBAction)setAccount:(id)sender
{
	AIAccount<AIAccount_Privacy> *repObj = [[mainAccounts selectedItem] representedObject];
	[self willChangeValueForKey:@"listContents"];
	[listContents release];
	listContents = [listContentsAllAccounts mutableCopy];
	AIPrivacyOption currentState = AIPrivacyOptionUnknown;
	if (repObj != nil) {
		//clean out the listObjs for other accounts
		AIListContact *listObj;
		NSMutableArray *objectsToRemove = [[NSMutableArray alloc] init];
		NSEnumerator *enumerator = [listContents objectEnumerator];
		while ((listObj = [enumerator nextObject]))
			if (![[listObj account] isEqual:repObj])
				[objectsToRemove addObject:listObj];
		[listContents removeObjectsInArray:objectsToRemove];
		[objectsToRemove release];
		currentState = [[accountStates objectForKey:[repObj UID]] intValue];
	} else {
		NSEnumerator *enumerator = [accountStates objectEnumerator];
		NSNumber *tmpNum;
		while((tmpNum = [enumerator nextObject])) {
			if (currentState == AIPrivacyOptionUnknown)
				currentState = [tmpNum intValue];
			else if ([tmpNum intValue] != currentState)
				currentState = AIPrivacyOptionCustom;
		}
	}
	[stateChooser selectItemWithRepresentedObject:[NSNumber numberWithInt:currentState]];
	[self didChangeValueForKey:@"listContents"];
}

- (IBAction)setState:(id)sender
{
	AIPrivacyOption newState = [[[stateChooser selectedItem] representedObject] intValue];
	if (newState == AIPrivacyOptionCustom) {
		newState = AIPrivacyOptionUnknown;
		NSEnumerator *enumerator = [accountStates objectEnumerator];
		NSNumber *tmpNum;
		while((tmpNum = [enumerator nextObject])) {
			if (newState == AIPrivacyOptionUnknown)
				newState = [tmpNum intValue];
			else if ([tmpNum intValue] != newState)
				newState = AIPrivacyOptionCustom;
		}
		if (newState != AIPrivacyOptionCustom)
			[stateChooser selectItemWithRepresentedObject:[NSNumber numberWithInt:newState]];
	} else {
		if ([[mainAccounts selectedItem] representedObject] == nil) {
			[self willChangeValueForKey:@"listContents"];
			NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];
			AIAccount<AIAccount_Privacy> *account;
			while((account = [enumerator nextObject])) {
				if([[account statusObjectForKey:@"Online"] boolValue] &&
				   [account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
				[accountStates setObject:[NSNumber numberWithInt: (int)newState] forKey:[account UID]];
			}
		}
	} else {
		AIAccount<AIAccount_Privacy> *account = [[mainAccounts selectedItem] representedObject];
		[accountStates setObject:[NSNumber numberWithInt: (int)newState] forKey:[account UID]];
		[listContents release];
	}
	}
	[self recomputeListContents];
}

- (void)recomputeListContents
{
	[self willChangeValueForKey:@"listContents"];
	listContents = [[NSMutableArray alloc] init];
	AIAccount <AIAccount_Privacy> *account;
	NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];
	while((account = [enumerator nextObject])) {
		/* we can't do much with offline accounts and their block lists... */
		if([[account statusObjectForKey:@"Online"] boolValue] &&
		   [account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
			AIPrivacyOption accountState = [[accountStates objectForKey:[account UID]] intValue];
			if (accountState == AIPrivacyOptionDenyUsers) {
				[listContents addObjectsFromArray:[account listObjectsOnPrivacyList:AIPrivacyTypeDeny]];
			}
			else if (accountState == AIPrivacyOptionAllowUsers) {
				// if it's an allow list, we have to "invert" it so that it looks right.
				NSArray *tmpArr = [account listObjectsOnPrivacyList:AIPrivacyTypePermit];
				NSMutableArray *allContacts = [[account contacts] mutableCopy];
				[allContacts removeObjectsInArray:tmpArr];
				[listContents addObjectsFromArray:allContacts];
			}
		}
	}
	
	listContentsAllAccounts = [listContents mutableCopy];
	account = [[mainAccounts selectedItem] representedObject];
	if (account != nil) {
		//clean out the listObjs for other accounts
		AIListContact *listObj;
		NSMutableArray *objectsToRemove = [[NSMutableArray alloc] init];
		NSEnumerator *enumerator = [listContents objectEnumerator];
		while ((listObj = [enumerator nextObject]))
			if (![[listObj account] isEqual:account])
				[objectsToRemove addObject:listObj];
		[listContents removeObjectsInArray:objectsToRemove];
		[objectsToRemove release];
	}
	[self didChangeValueForKey:@"listContents"];
}


@end
