//
//  DCJoinChatWindowController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCJoinChatViewController.h"

@implementation DCJoinChatViewController

//Create a new join chat view
+ (DCJoinChatViewController *)joinChatView
{
	return [[[self alloc] init] autorelease];
}

//Init
- (id)init
{
    [super init];
	
	chat = nil;
	
	NSString	*nibName = [self nibName];
	if (nibName){
		[NSBundle loadNibNamed:nibName owner:self];
	}else{
		NSLog(@"No nib available... we shouldn't ever get here.");
	}
	
    return(self);
}

- (NSView *)view
{
	return(view);
}

//Stubs for subclasses
- (NSString *)nibName { return(nil); };
- (void)configureForAccount:(AIAccount *)inAccount { };
- (void)joinChatWithAccount:(AIAccount *)inAccount { };

//General methods for joining chats and inviting users
- (void)doJoinChatWithName:(NSString *)inName
				 onAccount:(AIAccount *)inAccount
		  chatCreationInfo:(NSDictionary *)inInfo 
		  invitingContacts:(NSArray *)contactsToInvite
	 withInvitationMessage:(NSString *)invitationMessage
{
	chat = [[adium contentController] chatWithName:inName
										 onAccount:inAccount
								  chatCreationInfo:inInfo];
	
	if ([contactsToInvite count]){
		[chat setStatusObject:contactsToInvite forKey:@"ContactsToInvite" notify:NotifyNever];
		
		if ([invitationMessage length]){
			[chat setStatusObject:invitationMessage forKey:@"InitialInivitationMessage" notify:NotifyNever];
		}
		
		[[adium notificationCenter] addObserver:self selector:@selector(chatDidOpen:) name:Chat_DidOpen object:chat];
	}
}

//When the chat opens, we are ready to send out our invitations to join it
- (void)chatDidOpen:(NSNotification *)notification
{
	NSArray *contacts = [chat statusObjectForKey:@"ContactsToInvite"];
	
	if(contacts && [contacts count]) {
		NSMutableDictionary	*inviteUsersDict;
		NSString			*initialInvitationMessage = [chat statusObjectForKey:@"InitialInivitationMessage"];
		
		inviteUsersDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",contacts,@"ContactsToInvite",nil];
		if (initialInvitationMessage){
			[inviteUsersDict setObject:initialInvitationMessage
								forKey:@"InitialInivitationMessage"];
		}
		
		[NSTimer scheduledTimerWithTimeInterval:0.01
										 target:self
									   selector:@selector(inviteUsers:)
									   userInfo:inviteUsersDict
										repeats:YES];
	}
	
	//The dictionary will retain the ContactsToInvite and InitialInivitationMessage objects;
	//The timer will retain the dictionary until it is invalidated.
	[chat setStatusObject:nil forKey:@"ContactsToInvite" notify:NotifyNever];
	[chat setStatusObject:nil forKey:@"InitialInivitationMessage" notify:NotifyNever];
	
	//We are no longer concerned with the opening of this chat.
	[[adium notificationCenter] removeObserver:self name:Chat_DidOpen object:chat];
}

//Called repeatedly by the scheduled timer until all users have been invited to the chat (we do this incrementally
//instead of all at once to prevent beachballing if the process is slow and a large number of users are invited)
- (void)inviteUsers:(NSTimer *)inTimer
{
	NSMutableDictionary *userInfo = [inTimer userInfo];
	
	NSArray				*contactArray = [userInfo objectForKey:@"ContactsToInvite"];
	int					i = [(NSNumber *)[userInfo objectForKey:@"i"] intValue];
	int					count = [contactArray count];
	
	[chat inviteListContact:[contactArray objectAtIndex:i]
				withMessage:[userInfo objectForKey:@"InitialInivitationMessage"]];
	
	i++;
	[userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
	if(i >= count) {
		[inTimer invalidate];
	}
}

//Return an array of AIListContact objects given a string in the form @"Contact1,Another Contact,A Third Contact"
- (NSArray *)contactsFromNamesSeparatedByCommas:(NSString *)namesSeparatedByCommas onAccount:(AIAccount *)inAccount;
{
	NSMutableArray	*contactsArray = nil;
	NSArray			*contactNames;
	
	if ([namesSeparatedByCommas length]){
		//If the service is not case sensitive, compact the string before proceeding so our UIDs will be correct
		if (![[inAccount service] caseSensitive]){
			namesSeparatedByCommas = [namesSeparatedByCommas compactedString];
		}
		contactNames = [namesSeparatedByCommas componentsSeparatedByString:@","];
		
		if ([contactNames count]){
			NSEnumerator	*enumerator;
			NSString		*aContactName;
			AIListContact	*listContact;
			
			contactsArray = [NSMutableArray array];
			
			enumerator = [contactNames objectEnumerator];		
			while (aContactName = [enumerator nextObject]){
				listContact = [[adium contactController] contactWithService:[inAccount service] 
																	account:inAccount 
																		UID:aContactName];
				[contactsArray addObject:listContact];
			}
		}
	}
	
	return(contactsArray);
}


@end
