//
//  RAFBlockEditorWindow.m
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "RAFBlockEditorWindowController.h"
#import "Adium/AIAccount.h"
#import "AIListContact.h"
#import "AIService.h"
#import "Adium/AIAccountController.h"
#import "AIContactController.h"
#import <AIUtilities/AICompletingTextField.h>

#define BLOCK_EDITOR_TITLE AILocalizedString(@"Block List","Block List Editor window title")
#define BLOCK_DONE	AILocalizedString(@"Done","Done button for block list editor")
#define BLOCK_BLOCK	AILocalizedString(@"Add","Add button for block list editor")
#define BLOCK_CANCEL	AILocalizedString(@"Cancel","Cancel button for block list editor")
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
	listContents = [[NSMutableArray alloc] init];
	NSMenu *tmpMenu = [[NSMenu alloc] init];
	AIAccount <AIAccount_Privacy> *account;
	NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];
	while((account = [enumerator nextObject])) {
		/* we can't do much with offline accounts and their block lists... */
		if([[account statusObjectForKey:@"Online"] boolValue] &&
		   [account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
#warning hardwired for a *block* list -RAF
			//all points where this will have to change are marked with XXX in a comment
			[listContents addObjectsFromArray:[account listObjectsOnPrivacyList:PRIVACY_DENY]];
			NSMenuItem *tmpItem = [[NSMenuItem alloc]
								initWithTitle:[account UID] action:NULL keyEquivalent:@""];
			[tmpItem setRepresentedObject:account];
			[tmpMenu addItem:[tmpItem autorelease]];
		}
	}
	/* We may want to switch to code like this:
	 *	[[AIAccountMenu accountMenuWithDelegate:self
	 *								submenuType:AIAccountNoSubmenu
	 *							 showTitleVerbs:NO] retain];
	 * for the accounts NSPopUpButton menu since now we may be
	 * duplicating some code. I'll look into this when I update this
	 * to support Allow lists and such. -RAF
	 */
	[self didChangeValueForKey:@"listContents"];
	
	[table registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs",nil]];
			
	[accounts setMenu:[tmpMenu autorelease]];
	
	[self configTextField:self];
	
	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender
{
	AIAccount <AIAccount_Privacy> *account;
	AIListContact *contact;
	NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];
	
	//remove unblocked people
	while((account = [enumerator nextObject])) {
		if([account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
//XXX-Block Specific
			NSEnumerator *tmp=[[account listObjectsOnPrivacyList:PRIVACY_DENY] objectEnumerator];
			while((contact = [tmp nextObject])) {
				if( ![listContents containsObject:contact] )
//XXX-Block Specific
				[account removeListObject:contact fromPrivacyList:PRIVACY_DENY];
			}
		}
	}
	
	//block blocked people who aren't already
	enumerator = [listContents objectEnumerator];
	while((contact = [enumerator nextObject])) {
		account = [contact account];
//XXX-Block Specific
		if( ![[account listObjectsOnPrivacyList:PRIVACY_DENY] containsObject:contact] &&
			[account conformsToProtocol:@protocol(AIAccount_Privacy)]) {
			[account addListObject:contact toPrivacyList:PRIVACY_DENY];
		}
	}
	sharedInstance = nil;
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
	contact = [self contactFromText:[field stringValue] onAccount:account];
	[listContents addObject:contact];
	[self didChangeValueForKey:@"listContents"];
}

- (AIListContact *)contactFromText:(NSString *)text onAccount:(AIAccount *)account
{
	AIListContact	*contact;
	NSString		*UID;
	
	//Get the service type and UID
	UID = [[account service] filterUID:text removeIgnoredCharacters:YES];
	
	//Find the contact
	contact = [[adium contactController] contactWithService:[account service]
													account:account 
														UID:UID];
	
	return contact;
}

@end
