//
//  DCGaimMeanwhileJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "DCGaimMeanwhileJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@interface DCGaimMeanwhileJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
- (void)_configureTextField;
@end

@implementation DCGaimMeanwhileJoinChatViewController

- (NSString *)nibName
{
	return @"DCGaimMeanwhileJoinChatView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{			
	account = inAccount;

	[textField_inviteUsers setMinStringLength:2];
	[textField_inviteUsers setCompletesOnlyAfterSeparator:YES];
	[self _configureTextField];
	
	[super configureForAccount:inAccount];

	[self validateEnteredText];
	[[view window] makeFirstResponder:textField_topic];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*topic;
	NSDictionary	*chatCreationInfo;
	
	//Obtain room and exchange from the view
	//room = [NSString stringWithFormat:@"Chat %@",[NSString randomStringOfLength:5]];
	topic = [textField_topic stringValue];
	
	if (topic && [topic length]){
		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSDictionary dictionaryWithObject:topic
													   forKey:@"chat_topic"];
		
		[self doJoinChatWithName:topic
					   onAccount:inAccount
				chatCreationInfo:chatCreationInfo
				invitingContacts:[self contactsFromNamesSeparatedByCommas:[textField_inviteUsers stringValue] onAccount:inAccount]
		   withInvitationMessage:nil];
	}else{
		NSLog(@"Error: No topic specified.");
	}
	
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if([notification object] == textField_topic){
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	NSString	*topic = [textField_topic stringValue];
	BOOL		enabled = (topic && [topic length]);
	
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
@end
