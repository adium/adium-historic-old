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

#import "AIAccount.h"
#import "AIChat.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIService.h"
#import "DCJoinChatViewController.h"
#import <AIUtilities/AIStringAdditions.h>

@interface DCJoinChatViewController (PRIVATE)
- (NSString *)impliedCompletion:(NSString *)aString;
@end

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
	delegate = nil;
	
	NSString	*nibName = [self nibName];
	if(nibName){
		[NSBundle loadNibNamed:nibName owner:self];
	}
	
    return(self);
}

- (void)dealloc
{
	[view release]; view = nil;
	
	[super dealloc];
}

- (NSView *)view
{
	return(view);
}

//Stubs for subclasses
- (NSString *)nibName { return(nil); };
- (void)configureForAccount:(AIAccount *)inAccount { };
- (void)joinChatWithAccount:(AIAccount *)inAccount { };
- (NSString *)impliedCompletion:(NSString *)aString {return aString;}

//General methods for joining chats and inviting users
- (void)doJoinChatWithName:(NSString *)inName
				 onAccount:(AIAccount *)inAccount
		  chatCreationInfo:(NSDictionary *)inInfo 
		  invitingContacts:(NSArray *)contactsToInvite
	 withInvitationMessage:(NSString *)invitationMessage
{
	AILog(@"Creating chatWithName:%@ onAccount:%@ chatCreationInfo:%@",inName,inAccount,inInfo);
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
		
		contactNames = [namesSeparatedByCommas componentsSeparatedByString:@","];
		
		if ([contactNames count]){
			NSEnumerator	*enumerator;
			NSString		*aContactName, *UID;
			AIListContact	*listContact;
			
			contactsArray = [NSMutableArray array];
			
			enumerator = [contactNames objectEnumerator];		
			while (aContactName = [enumerator nextObject]){
								
				UID = [[inAccount service] filterUID:[self impliedCompletion:aContactName] removeIgnoredCharacters:YES];
				
				//If the service is not case sensitive, compact the string before proceeding so our UID will be correct
				if (![[inAccount service] caseSensitive]){
					UID = [UID compactedString];
				}
				
				if(listContact = [[adium contactController] contactWithService:[inAccount service] 
																	   account:inAccount 
																		   UID:UID]){
					[contactsArray addObject:listContact];
				}
			}
		}
	}
	
	return(contactsArray);
}

- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
}
- (id)delegate;
{
	return delegate;
}


@end
