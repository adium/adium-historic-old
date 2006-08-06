//
//  ESjoscarJoinChatViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 2/7/06.
//

#import "ESjoscarJoinChatViewController.h"
#import <Adium/DCJoinChatWindowController.h>
#import <AIUtilities/AICompletingTextField.h>
#import "AIAdium.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import "RAFjoscarAccount.h"

@interface ESjoscarJoinChatViewController (PRIVATE)
- (void)_configureTextField;
@end

@implementation ESjoscarJoinChatViewController


//#pragma mark Subclassed from DCJoinChatViewController

- (NSString *)nibName
{
	return @"joscarJoinChatView";
}

- (id)init
{
	if ((self = [super init]))
	{
		[textField_inviteUsers setDragDelegate:self];
		[textField_inviteUsers registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs", nil]];
	}	
	
	return self;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	[textField_inviteUsers setMinStringLength:2];
	[textField_inviteUsers setCompletesOnlyAfterSeparator:YES];
	[self _configureTextField];
	
	[[view window] makeFirstResponder:textField_roomName];
	[self validateEnteredText];
}

/*
 OSCAR uses: 
	oscar_join_chat, with a GHashTable *data which needs to contain values to fulfill the keys:
 "room"
 "exchange"
 ("exchange" contains an integer, minimum of 4, maximum of 20, turned into a string by g_stdup_printf.
  What could this integer mean?)
 Dave: this integer refers to a group of chat rooms, all with similar properties. It should always be 4.
 I found dat on teh INTERNET!
 */


- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room;
	int				exchange;
	NSDictionary	*chatCreationInfo;

	//Obtain room and exchange from the view
	room = [textField_roomName stringValue];

	if (room && [room length]) {
		//XXX we should probaly let the user pick the exchange
		exchange = 4;

		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",[NSNumber numberWithInt:exchange],@"exchange",nil];

		NSString *invitationMessage = [textField_inviteMessage stringValue];

		if (!invitationMessage || ![invitationMessage length]) {
			invitationMessage = [[adium chatController] defaultInvitationMessageForRoom:room account:inAccount];
		}

		[self doJoinChatWithName:room
					   onAccount:inAccount
				chatCreationInfo:chatCreationInfo
				invitingContacts:[self contactsFromNamesSeparatedByCommas:[textField_inviteUsers stringValue] onAccount:inAccount]
		   withInvitationMessage:invitationMessage];
		AIChat *tmpChat = [[adium chatController] existingChatWithName:room onAccount:account];
		[(RAFjoscarAccount *)account addChat:tmpChat];

	} else {
		NSLog(@"Error: No room specified.");
	}
	
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if ([notification object] == textField_roomName) {
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	NSString	*roomName = [textField_roomName stringValue];
	BOOL		enabled = (roomName && [roomName length]);
	
	if (delegate)
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:enabled];
}

- (NSString *)impliedCompletion:(NSString *)aString
{
	return [textField_inviteUsers impliedStringValueForString:aString];
}

- (void)_configureTextField
{
	NSEnumerator		*enumerator;
    AIListContact		*contact;
	
	//Clear the completing strings
	[textField_inviteUsers setCompletingStrings:nil];
	
	//Configure the auto-complete view to autocomplete for contacts matching the selected account's service
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while ((contact = [enumerator nextObject])) {
		if ([contact service] == [account service]) {
			NSString *UID = [contact UID];
			[textField_inviteUsers addCompletionString:[contact formattedUID] withImpliedCompletion:UID];
			[textField_inviteUsers addCompletionString:[contact displayName] withImpliedCompletion:UID];
			[textField_inviteUsers addCompletionString:UID];
		}
    }
	
}

#pragma mark Dragging Delegate


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [super doPerformDragOperation:sender toField:textField_inviteUsers];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [super doDraggingEntered:sender];
}

@end
