//
//  DCGaimOscarJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimOscarJoinChatViewController.h"

@implementation DCGaimOscarJoinChatViewController

#pragma mark Subclassed from DCJoinChatViewController

- (id)init
{
	[super init];
	
	contacts = nil;
	account = nil;
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateContactsList)
									   name:Contact_ListChanged
									 object:nil];
	
	return self;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	account = inAccount;
	contacts = [[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:account];
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
	[[adium contentController] chatWithName:room
								  onAccount:inAccount
						   chatCreationInfo:chatCreationInfo];
	
	// Invite users to the chat
	NSArray *usersArray = [[textField_inviteUsers stringValue] componentsSeparatedByString:@","];
	
	NSLog(@"#### users to invite: %@",usersArray);
	
	[NSTimer scheduledTimerWithTimeInterval:0.01
									 target:self
								   selector:@selector(inviteUsers:)
								   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:usersArray,@"contacts",[NSNumber numberWithInt:0],@"i",nil]
									repeats:YES];
	 
}

- (NSString *)nibName
{
	return @"DCGaimOscarJoinChatView";
}

- (void)inviteUsers:(NSTimer *)inTimer
{
	NSMutableDictionary *userInfo = [inTimer userInfo];
	NSArray				*contactArray = [userInfo objectForKey:@"contacts"];
	int					i = [(NSNumber *)[userInfo objectForKey:@"i"] intValue];
	int					count = [contactArray count];
	
	AIListContact *newContact = [[adium contactController] contactWithService:[[account service] identifier] 
																	accountID:[account uniqueObjectID] 
																		  UID:[[contactArray objectAtIndex:i] compactedString]];
	NSLog(@"#### inviteUsers: (%d/%d) inviting %@",i,count,[contactArray objectAtIndex:i]);
	//[chat inviteListContact:newContact withMessage:[textField_inviteMessage stringValue]];
		
	i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if(i >= count) [inTimer invalidate];
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
