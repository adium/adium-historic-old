//
//  DCGaimZephyrJoinChatViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 8/12/04.
//

#import "DCGaimZephyrJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@interface DCGaimZephyrJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
@end

@implementation DCGaimZephyrJoinChatViewController

- (NSString *)nibName
{
	return @"DCGaimZephyrJoinChatView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	if(delegate) {
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:([[textField_class stringValue] length] > 0)];
	}
	
	[[view window] makeFirstResponder:textField_class];
	
	[super configureForAccount:inAccount];
}

/*
 Zephyr uses "class" "instance" and "recipient".  Instance and Recipient are optional and will become "*" if
 they are not specified; we show this default value automatically for clarity.
 */

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString			*class;
	NSString			*instance;
	NSString			*recipient;
	NSDictionary		*chatCreationInfo;
	
	class = [textField_class stringValue];
	instance = [textField_instance stringValue];
	recipient = [textField_instance stringValue];
	
	if (!instance || ![instance length]) instance = @"*";
	if (!recipient || ![recipient length]) recipient = @"*";
	
	if (class && [class length]){
		NSString	*name;
		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSMutableDictionary dictionaryWithObject:class
															  forKey:@"class"];

		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:class,@"class",instance,@"instance",recipient,@"recipient"];
		
		name = [NSString stringWithFormat:@"%@,%@,%@",class,instance,recipient];
		
		[self doJoinChatWithName:name
					   onAccount:inAccount
				chatCreationInfo:chatCreationInfo
				invitingContacts:nil
		   withInvitationMessage:nil];
	}
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if([notification object] == textField_class){
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	NSString *class = [textField_class stringValue];
	BOOL enabled = NO;
	
	if(class && [class length]){
		enabled = YES;
	}
	
	if(delegate)
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:enabled];
}

@end
