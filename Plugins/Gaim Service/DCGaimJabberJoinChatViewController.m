//
//  DCGaimJabberJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimJabberJoinChatViewController.h"
#import "DCJoinChatWindowController.h"
#import "CBGaimAccount.h"

#define DEFAULT_CONFERENCE_SERVER [NSString stringWithFormat:@"conference.%@",[(CBGaimAccount *)inAccount host]]

@interface DCGaimJabberJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
@end

@implementation DCGaimJabberJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[delegate setJoinChatEnabled:NO];
	[[view window] makeFirstResponder:textField_roomName];

	if([[textField_server cell] respondsToSelector:@selector(setPlaceholderString:)])
		[[textField_server cell] setPlaceholderString:DEFAULT_CONFERENCE_SERVER];
		
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

@end
