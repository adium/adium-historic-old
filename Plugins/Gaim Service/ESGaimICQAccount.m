//
//  ESGaimICQAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 8/29/04.
//

#import "ESGaimICQAccount.h"


@implementation ESGaimICQAccount

- (void)configureGaimAccount
{
	[super configureGaimAccount];

	NSString	*encoding;

	//Default encoding
	if ((encoding = [self preferenceForKey:KEY_ICQ_ENCODING group:GROUP_ACCOUNT_STATUS])){
		gaim_account_set_string(account, "encoding", [encoding UTF8String]);
	}
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	//As an ICQ account we should always send plain text, so no more complex checking is needed
	return ([inAttributedString string]);
}

//CBGaimOscarAccount does complex things here, but ICQ can just perform a normal encodedAttributedString:forListObject
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject contentMessage:(AIContentMessage *)contentMessage
{	
	return([self encodedAttributedString:inAttributedString forListObject:inListObject]);
}

//Setting aliases serverside would override the information Gaim is feeding us
- (BOOL)shouldSetAliasesServerside
{
	return(NO);
}

//ICQ doesn't support automatic typing notification clearing after a send, but AIM and .Mac do, so we return YES
//for smooth operation, particularly with iChat where this is very noticeable.
- (BOOL)suppressTypingNotificationChangesAfterSend
{
	return(YES);
}

@end
