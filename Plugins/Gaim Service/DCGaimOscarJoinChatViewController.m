/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactController.h"
#import "DCGaimOscarJoinChatViewController.h"
#import "DCJoinChatWindowController.h"
#import <AIUtilities/AICompletingTextField.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>

@interface DCGaimOscarJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
- (void)_configureTextField;
@end

@implementation DCGaimOscarJoinChatViewController

//#pragma mark Subclassed from DCJoinChatViewController

- (NSString *)nibName
{
	return @"DCGaimOscarJoinChatView";
}

- (id)init
{
	[super init];

	[textField_inviteUsers setDragDelegate:self];
	[textField_inviteUsers registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs",nil]];

	return self;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	
	[textField_inviteUsers setMinStringLength:2];
	[textField_inviteUsers setCompletesOnlyAfterSeparator:YES];
	[self _configureTextField];

	[super configureForAccount:inAccount];
	
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

	if (room && [room length]){
		exchange = 4;
				
		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",[NSNumber numberWithInt:exchange],@"exchange",nil];
		
		[self doJoinChatWithName:room
					   onAccount:inAccount
				chatCreationInfo:chatCreationInfo
				invitingContacts:[self contactsFromNamesSeparatedByCommas:[textField_inviteUsers stringValue] onAccount:inAccount]
		  withInvitationMessage:[textField_inviteMessage stringValue]];
	}else{
		NSLog(@"Error: No room specified.");
	}

}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if([notification object] == textField_roomName){
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	NSString	*roomName = [textField_roomName stringValue];
	BOOL		enabled = (roomName && [roomName length]);

	if(delegate)
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
    while((contact = [enumerator nextObject])){
		if([contact service] == [account service]){
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
