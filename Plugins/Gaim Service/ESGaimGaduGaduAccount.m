//
//  ESGaimGaduGaduAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESGaimGaduGaduAccountViewController.h"
#import "ESGaimGaduGaduAccount.h"

#define AGG_STATUS_AVAIL              "Available"
#define AGG_STATUS_AVAIL_FRIENDS      "Available for friends only"
#define AGG_STATUS_BUSY               "Away"
#define AGG_STATUS_BUSY_FRIENDS       "Away for friends only"
#define AGG_STATUS_INVISIBLE          "Invisible"
#define AGG_STATUS_INVISIBLE_FRIENDS  "Invisible for friends only"
#define AGG_STATUS_NOT_AVAIL          "Unavailable"

@interface ESGaimGaduGaduAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimGaduGaduAccount


static BOOL didInitGG = NO;

- (const char*)protocolPlugin
{
	if (!didInitGG) didInitGG = gaim_init_gg_plugin();
    return "prpl-gg";
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Looking up server",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data","Connection step");
			break;			
		case 3:
			return AILocalizedString(@"Balancer handshake","Connection step");
			break;
		case 4:
			return AILocalizedString(@"Reading server key","Connection step");
			break;
		case 5:
			return AILocalizedString(@"Exchanging key hash","Connection step");
			break;
	}
	return nil;
}

- (NSString *)hostKey
{
	return KEY_GADU_GADU_HOST;
}

- (NSString *)portKey
{
	return KEY_GADU_GADU_PORT;
}

- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];	

	GaimAccount		*gaimAccount = [self gaimAccount];
	GaimConnection  *gc;
	
	if(gc = gaim_account_get_connection(gaimAccount)){
		gg_userlist_request(((struct agg_data *)gc->proto_data)->sess, GG_USERLIST_GET, NULL);
	}
}

//Away and away return
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data
{
	[super updateWentAway:theContact withData:data];
	[theContact setStatusObject:[self statusMessageForContact:theContact]
						 forKey:@"StatusMessage"
						 notify:YES];
}

- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data
{
	[super updateWentAway:theContact withData:data];
	
	[theContact setStatusObject:[self statusMessageForContact:theContact]
						 forKey:@"StatusMessage"
						 notify:YES];
}

- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact
{
	NSAttributedString  *statusMessage = nil;
	
	GaimBuddy *buddy = gaim_find_buddy([self gaimAccount],[[theContact UID] UTF8String]);
	if (buddy && buddy->proto_data){
		NSString	*statusMessageString = [NSString stringWithUTF8String:buddy->proto_data];
		if (statusMessageString && [statusMessageString length]){
			statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
															 attributes:nil] autorelease];
		}
	}   
	
	return statusMessage;
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
			if([statusName isEqualToString:STATUS_NAME_AVAILABLE])
				gaimStatusType = AGG_STATUS_AVAIL;
			else if([statusName isEqualToString:STATUS_NAME_AVAILABLE_FRIENDS_ONLY])
				gaimStatusType = AGG_STATUS_AVAIL_FRIENDS;
			break;
		}
			
		case AIAwayStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_AWAY])
				gaimStatusType = AGG_STATUS_BUSY;
			else if ([statusName isEqualToString:STATUS_NAME_AWAY_FRIENDS_ONLY])
				gaimStatusType = AGG_STATUS_BUSY_FRIENDS;
			else if ([statusName isEqualToString:STATUS_NAME_NOT_AVAILABLE])
				gaimStatusType = AGG_STATUS_NOT_AVAIL;
			
			break;
		}
	}

	/* Gadu-Gadu supports status messages along with the status types, so let our message stay */
	
	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

@end