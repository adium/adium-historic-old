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

- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;

	if (!supportedPropertyKeys){
		supportedPropertyKeys = [[super supportedPropertyKeys] mutableCopy];
		//ICQ doesn't support available messages
		[supportedPropertyKeys removeObject:@"AvailableMessage"];
	}
	
	return supportedPropertyKeys;
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

/*
 * @brief Return the gaim status type to be used for a status
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status equivalent
 * @param statusMessage A pointer to the statusMessage.  Set *statusMessage to nil if it should not be used directly for this status.
 *
 * @result The gaim status equivalent
 */
- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage
{
	NSString		*statusName = [statusState statusName];
	AIStatusType	statusType = [statusState statusType];
	char			*gaimStatusType = NULL;

	switch(statusType){
		case AIAvailableStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT])
				gaimStatusType = "Free For Chat";
			break;
		}

		case AIAwayStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_DND])
				gaimStatusType = "Do Not Disturb";
			else if ([statusName isEqualToString:STATUS_NAME_NOT_AVAILABLE])
				gaimStatusType = "Not Available";
			else if ([statusName isEqualToString:STATUS_NAME_OCCUPIED])
				gaimStatusType = "Occupied";
			
			break;
		}
	}

	//If we are setting one of our custom statuses, don't use a status message
	if(gaimStatusType != NULL) 	*statusMessage = nil;

	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

//ICQ doesn't support automatic typing notification clearing after a send, but AIM and .Mac do, so we return YES
//for smooth operation, particularly with iChat where this is very noticeable.
- (BOOL)suppressTypingNotificationChangesAfterSend
{
	return(YES);
}

@end
