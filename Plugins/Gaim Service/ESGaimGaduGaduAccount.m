//
//  ESGaimGaduGaduAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.


#import "ESGaimGaduGaduAccountViewController.h"
#import "ESGaimGaduGaduAccount.h"

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
			return AILocalizedString(@"Reading data",nil);
			break;			
		case 3:
			return AILocalizedString(@"Balancer handshake",nil);
			break;
		case 4:
			return AILocalizedString(@"Reading server key",nil);
			break;
		case 5:
			return AILocalizedString(@"Exchanging key hash",nil);
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

	GaimConnection  *gc = [self gaimAccount]->gc;
	
	gg_userlist_request(((struct agg_data *)gc->proto_data)->sess, GG_USERLIST_GET, NULL);
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

@end