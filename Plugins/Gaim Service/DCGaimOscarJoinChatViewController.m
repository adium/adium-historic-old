//
//  DCGaimOscarJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimOscarJoinChatViewController.h"

@implementation DCGaimOscarJoinChatViewController

//#pragma mark Subclassed from DCJoinChatViewController

- (id)init
{
	[super init];

	return self;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
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
		
		NSLog(@"#### OSCAR joinChatWithAccount: %@ joining %@ on exchange %i",inAccount,room,exchange);
		
		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		
		/*
		 Development notes:
		 
		 We could have a special key to allow custom handling such as will be needed for MSN,
		 and use the default hash-table built handling for prpls which properly implement the full Gaim
		 chat API, such as OSCAR.
		 
		 We don't read that proto_info here because it'd just obfuscate the code... we need to manually
		 hook up the nib and code for each option.  Error logging in SLGaimCocoaAdapter should quickly
		 indicate if any keys were missed in this method.
		 */
		
		chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",[NSNumber numberWithInt:exchange],@"exchange",nil];
		
		//Open a chat, using the room as the name, and passing the chatCreationInfo we just built
		//Note: Gaim expects that the name of the chat be the same as the first entry in the proto_info for that prpl
		//For OSCAR, that's the value identified by the identifier "room"; it's an equally intuitive choice for
		//other prpls.
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
