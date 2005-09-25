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
#import "CBGaimAccount.h"
#import "DCGaimJabberJoinChatViewController.h"
#import "DCJoinChatWindowController.h"
#import <AIUtilities/AICompletingTextField.h>
#import <Adium/AIListContact.h>

#define	KEY_DEFAULT_CONFERENCE_SERVER	@"DefaultConferenceServer"

@interface DCGaimJabberJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
- (void)_configureTextField;
@end

@implementation DCGaimJabberJoinChatViewController

- (id)init
{
	if ((self = [super init]))
	{
		[textField_inviteUsers setDragDelegate:self];
		[textField_inviteUsers registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs", nil]];
	}	
	
	return self;
}

/*
 * @brief Find the default conference server
 *
 * Assumption: The account ivar is non-nil
 *
 * @result The server specified by KEY_DEFAULT_CONFERENCE_SERVER, or conference.[account host].
 */
- (NSString *)defaultConferenceServer
{
	NSString *defaultConferenceServer;
	
	if (!(defaultConferenceServer = [account preferenceForKey:KEY_DEFAULT_CONFERENCE_SERVER group:GROUP_ACCOUNT_STATUS])) {
		defaultConferenceServer = [NSString stringWithFormat:@"conference.%@",[account host]];
	}
	
	return defaultConferenceServer;
}

/*
 * @brief Store a nwe default conference server
 */
- (void)setDefaultConferenceServer:(NSString *)inDefaultConferenceServer
{
	[account setPreference:inDefaultConferenceServer
					forKey:KEY_DEFAULT_CONFERENCE_SERVER
					 group:GROUP_ACCOUNT_STATUS];
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	NSString	*defaultConferenceServer;
	
	[super configureForAccount:inAccount];
	
	defaultConferenceServer = [self defaultConferenceServer];

	[delegate setJoinChatEnabled:NO];
	[[view window] makeFirstResponder:textField_roomName];

	if ([[textField_server cell] respondsToSelector:@selector(setPlaceholderString:)]) {
		[[textField_server cell] setPlaceholderString:[self defaultConferenceServer]];
	} else {
		[textField_server setStringValue:defaultConferenceServer];
	}
		
	[textField_inviteUsers setMinStringLength:2];
	[textField_inviteUsers setCompletesOnlyAfterSeparator:YES];
	[self _configureTextField];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room = [textField_roomName stringValue];
	NSString		*server = [textField_server stringValue];
	NSString		*handle = [textField_handle stringValue];
	NSString		*password = [textField_password stringValue];
	NSDictionary	*chatCreationInfo;
			
	if (!handle || ![handle length])
		handle = [inAccount UID];
	
#warning What is going on with the @"temp" password? It was committed in http://trac.adiumx.com/changeset/7131
	if (!password || ![password length])
		password = @"temp";
	
	if (!server || ![server length]) {
		//If no server is specified, use the default, which may be visible to the user as a placeholder string
		server = [self defaultConferenceServer];

	} else {
		//If the user specified a server, make it the new default if it isn't already the default
		if (![server isEqualToString:[self defaultConferenceServer]]) {
			[self setDefaultConferenceServer:server];
		}
	}
	
	chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",server,@"server",handle,@"handle",password,@"password",nil];

	[self doJoinChatWithName:[NSString stringWithFormat:@"%@@%@",room,server]
				   onAccount:inAccount
			chatCreationInfo:chatCreationInfo
			invitingContacts:nil
	   withInvitationMessage:nil];
}

- (NSString *)nibName
{
	return @"DCGaimJabberJoinChatView";
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	[self validateEnteredText];
}

- (void)validateEnteredText
{
	NSString *roomLen = [textField_roomName stringValue];
	//NSString *serverLen = [textField_server stringValue];
	//NSString *handleLen = [textField_handle stringValue];
	//NSString *passwordLen = [textField_password stringValue];
	BOOL enabled = NO;
	
	if ( roomLen && [roomLen length] 
		//&& serverLen && [serverLen length]
		//&& handleLen && [handleLen length]
		//&& passwordLen && [passwordLen length]
		) {
		enabled = YES;
	}
	
	if ( delegate )
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
