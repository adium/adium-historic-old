//
//  DCGaimOscarJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimOscarJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@interface DCGaimOscarJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
@end

@implementation DCGaimOscarJoinChatViewController

//#pragma mark Subclassed from DCJoinChatViewController

- (id)init
{
	[super init];

	return self;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	if( delegate ) {
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:([[textField_roomName stringValue] length] > 0)];
	}
	
	[[view window] makeFirstResponder:textField_roomName];

	[super configureForAccount:inAccount];
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
	//room = [NSString stringWithFormat:@"Chat %@",[NSString randomStringOfLength:5]];
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

- (NSString *)nibName
{
	return @"DCGaimOscarJoinChatView";
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
	NSString *roomName = [textField_roomName stringValue];
	BOOL enabled = NO;
	
	if( roomName && [roomName length] ) {
		enabled = YES;
	}
	
	if( delegate )
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:enabled];
}

//#pragma mark Table View of contacts
//
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
//{
//	NSString	*identifier = [tableColumn identifier];
//	
//	if([identifier isEqualToString:@"check"]){
//		return([NSNumber numberWithBool:YES]);
//	}else if([identifier isEqualToString:@"contacts"]){
//		return([[contacts objectAtIndex:row] displayName]);
//	}else{
//		return(@"");
//	}
//}
//
//- (int)numberOfRowsInTableView:(NSTableView *)tableView
//{
//	NSLog(@"#### numberOfRowsInTableView: %d",[contacts count]);
//	return([contacts count]);
//}
//
//- (void)updateContactsList
//{
//	contacts = [[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:account];
//}

@end
