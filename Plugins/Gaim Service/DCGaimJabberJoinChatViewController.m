//
//  DCGaimJabberJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "DCGaimJabberJoinChatViewController.h"
#import "DCJoinChatWindowController.h"
#import "CBGaimAccount.h"

#define DEFAULT_CONFERENCE_SERVER [NSString stringWithFormat:@"conference.%@",[(CBGaimAccount *)inAccount host]]

@interface DCGaimJabberJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
- (void)_configureTextField;
@end

@implementation DCGaimJabberJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	account = inAccount;

	[delegate setJoinChatEnabled:NO];
	[[view window] makeFirstResponder:textField_roomName];

	if([[textField_server cell] respondsToSelector:@selector(setPlaceholderString:)])
		[[textField_server cell] setPlaceholderString:DEFAULT_CONFERENCE_SERVER];
		
	[textField_inviteUsers setMinStringLength:2];
	[textField_inviteUsers setCompletesOnlyAfterSeparator:YES];
	[self _configureTextField];

	[super configureForAccount:inAccount];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room = [textField_roomName stringValue];
	NSString		*server = [textField_server stringValue];
	NSString		*handle = [textField_handle stringValue];
	NSString		*password = [textField_password stringValue];
	NSDictionary	*chatCreationInfo;
			
	if( !handle || ![handle length] )
		handle = [inAccount UID];
	
	if( !password || ![password length] )
		password = @"temp";
	
	if( !server || ![server length] )
		server = DEFAULT_CONFERENCE_SERVER;
			
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
	
	if( roomLen && [roomLen length] 
		//&& serverLen && [serverLen length]
		//&& handleLen && [handleLen length]
		//&& passwordLen && [passwordLen length]
		) {
		enabled = YES;
	}
	
	if( delegate )
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
@end
