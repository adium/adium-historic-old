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
#import "AIChatController.h"
#import "AIService.h"
#import "AIListContact.h"
#import "AIMetaContact.h"
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
    if ((self = [super init]))
	{
		chat = nil;
		delegate = nil;
		
		NSString	*nibName = [self nibName];
		if (nibName)
		{
			[NSBundle loadNibNamed:nibName owner:self];
		}
	}
	
    return self;
}

- (void)dealloc
{
	[view release]; view = nil;
	[account release];

	[super dealloc];
}

- (NSView *)view
{
	return view;
}

//Stubs for subclasses
- (NSString *)nibName { return nil; };
- (void)joinChatWithAccount:(AIAccount *)inAccount { };

- (void)configureForAccount:(AIAccount *)inAccount
{ 
	if (inAccount != account) {
		[account release];
		account = [inAccount retain]; 
	}
}

- (NSString *)impliedCompletion:(NSString *)aString {return aString;}


//General methods for joining chats and inviting users
- (void)doJoinChatWithName:(NSString *)inName
				 onAccount:(AIAccount *)inAccount
		  chatCreationInfo:(NSDictionary *)inInfo 
		  invitingContacts:(NSArray *)contactsToInvite
	 withInvitationMessage:(NSString *)invitationMessage
{
	AILog(@"Creating chatWithName:%@ onAccount:%@ chatCreationInfo:%@",inName,inAccount,inInfo);
	chat = [[adium chatController] chatWithName:inName
									  onAccount:inAccount
							   chatCreationInfo:inInfo];
	
	if ([contactsToInvite count]) {
		[chat setStatusObject:contactsToInvite forKey:@"ContactsToInvite" notify:NotifyNever];
		
		if ([invitationMessage length]) {
			[chat setStatusObject:invitationMessage forKey:@"InitialInivitationMessage" notify:NotifyNever];
		}
		
		[[adium notificationCenter] addObserver:self selector:@selector(chatDidOpen:) name:Chat_DidOpen object:chat];
	}
}

//When the chat opens, we are ready to send out our invitations to join it
- (void)chatDidOpen:(NSNotification *)notification
{
	NSArray *contacts = [chat statusObjectForKey:@"ContactsToInvite"];
	
	if (contacts && [contacts count]) {
		NSMutableDictionary	*inviteUsersDict;
		NSString			*initialInvitationMessage = [chat statusObjectForKey:@"InitialInivitationMessage"];
		
		inviteUsersDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",contacts,@"ContactsToInvite",nil];
		if (initialInvitationMessage) {
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
	if (i >= count) {
		[inTimer invalidate];
	}
}

//Return an array of AIListContact objects given a string in the form @"Contact1,Another Contact,A Third Contact"
- (NSArray *)contactsFromNamesSeparatedByCommas:(NSString *)namesSeparatedByCommas onAccount:(AIAccount *)inAccount;
{
	NSMutableArray	*contactsArray = nil;
	NSArray			*contactNames;
	
	if ([namesSeparatedByCommas length]) {
		
		contactNames = [namesSeparatedByCommas componentsSeparatedByString:@","];
		
		if ([contactNames count]) {
			NSEnumerator	*enumerator;
			NSString		*aContactName, *UID;
			AIListContact	*listContact;
			
			contactsArray = [NSMutableArray array];
			
			enumerator = [contactNames objectEnumerator];		
			while ((aContactName = [enumerator nextObject])) {
								
				UID = [[inAccount service] filterUID:[self impliedCompletion:aContactName] removeIgnoredCharacters:YES];
				
				//If the service is not case sensitive, compact the string before proceeding so our UID will be correct
				if (![[inAccount service] caseSensitive]) {
					UID = [UID compactedString];
				}
				
				if ((listContact = [[adium contactController] contactWithService:[inAccount service] 
																	   account:inAccount 
																		   UID:UID])) {
					[contactsArray addObject:listContact];
				}
			}
		}
	}
	
	return contactsArray;
}

#pragma mark Drag delegate convenience

// Returns an online contact with the required service, from the unique ID. Returns nil if none.
- (AIListContact *)validContact:(NSString *)uniqueID withService:(AIService *)service
{
	AIListContact *listContact = nil;
	AIListObject *listObject = [[adium contactController] existingListObjectWithUniqueID:uniqueID];
	
	if ( listObject ) {
		if ( [listObject isKindOfClass:[AIMetaContact class]] ) {
			listContact = [(AIMetaContact *)listObject preferredContactWithService:service];
		} else if ( [listObject isKindOfClass:[AIListContact class]] ) {
			if ([[listObject service] isEqualTo:service]) {
				listContact = (AIListContact *)listObject;
			}
		}				
		
		if ( listContact && [listContact online] ) {
			return listContact;
		}
	}
	
	return nil;
}

// Tests if dragged objects are valid for this account
// Must be called by explicitly the subclass
- (NSDragOperation)doDraggingEntered:(id <NSDraggingInfo>)sender
{	
	// Test whether this drag item is acceptable
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	// Are there list objects being dragged?
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]]) {
		
		// If so, get the ID's
		if ([[pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]) {
			NSArray			*dragItemsUniqueIDs;
			NSString		*uniqueID;
			NSEnumerator	*enumerator;
			
			dragItemsUniqueIDs = [pboard propertyListForType:@"AIListObjectUniqueIDs"];
			
			enumerator = [dragItemsUniqueIDs objectEnumerator];
			while ((uniqueID = [enumerator nextObject])) {
				
				// Is there a contact with our service?
				if ( [self validContact:uniqueID withService:[account service]] ) {
					
					//if ([[view window] firstResponder] != textField_inviteUsers)
					//	[[view window] makeFirstResponder:textField_inviteUsers];
					return NSDragOperationGeneric;
				}
			}
		}
	}
	
	//if we reach this point, no valid contacts were dragged
	return NSDragOperationNone;
}

// Accepts list contacts being dragged over theField and adds their ID's to the field in a nice manner
// Note: subclasses must call this explicitly
- (BOOL)doPerformDragOperation:(id <NSDraggingInfo>)sender toField:(NSTextField *)theField
{	
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	// Were ListObjects dragged?
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]]) {
		
		// If so, get the unique ID's
		if ([[pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]) {
			NSArray			*dragItemsUniqueIDs;
			NSString		*uniqueID;
			AIListObject	*listObject;
			AIListContact	*listContact;
			NSEnumerator	*enumerator;
			
			dragItemsUniqueIDs = [pboard propertyListForType:@"AIListObjectUniqueIDs"];
			
			enumerator = [dragItemsUniqueIDs objectEnumerator];
			while ((uniqueID = [enumerator nextObject])) {
				NSString *oldValue = [theField stringValue];
				listObject = [[adium contactController] existingListObjectWithUniqueID:uniqueID];
				
				// Get contacts with our service
				// (May not be necessary, as we reject ungood contacts in the dragging entered phase)
				if ((listContact = [self validContact:uniqueID withService:[account service]])) {
					
					// Add a comma for prettiness if need be
					if ( [oldValue length] && ![[oldValue substringFromIndex:([oldValue length]-1)] isEqualToString:@","] ) {
						oldValue = [oldValue stringByAppendingString:@", "];
						[theField setStringValue:oldValue];
					}
					[theField setStringValue:[oldValue stringByAppendingString:[listContact displayName]]];
				}
			}
		}
	}
	return YES;
}

#pragma mark Delegate handling
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
}
- (id)delegate;
{
	return delegate;
}


@end
