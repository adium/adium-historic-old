//
//  DCGaimMeanwhileJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimMeanwhileJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@interface DCGaimMeanwhileJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
@end

@implementation DCGaimMeanwhileJoinChatViewController

- (NSString *)nibName
{
	return @"DCGaimMeanwhileJoinChatView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{		
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


@end
