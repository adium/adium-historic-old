//
//  ESGaimMeanwhileAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//

#import "ESGaimMeanwhileAccount.h"

//#define MEANWHILE_NOT_AVAILABLE

@interface ESGaimMeanwhileAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimMeanwhileAccount

static BOOL didInitMeanwhile = NO;

- (const char*)protocolPlugin
{
	[super initSSL];
#ifndef MEANWHILE_NOT_AVAILABLE
	if (!didInitMeanwhile) didInitMeanwhile = gaim_init_meanwhile_plugin(); 
#endif
    return "prpl-meanwhile";
}

- (NSString *)hostKey
{
	return KEY_MEANWHILE_HOST;
}

- (NSString *)portKey
{
	return KEY_MEANWHILE_PORT;
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	int contactListChoice = [[self preferenceForKey:KEY_MEANWHILE_CONTACTLIST group:GROUP_ACCOUNT_STATUS] intValue];

	gaim_prefs_set_int(MW_PRPL_OPT_BLIST_ACTION, contactListChoice);
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
#ifndef MEANWHILE_NOT_AVAILABLE
	NSAttributedString		*statusMessage = nil;
	GaimConnection			*gc = [self gaimAccount]->gc;
		
	struct mw_plugin_data	*pd = ((struct mw_plugin_data *)(gc->proto_data));
	struct mwAwareIdBlock	t = { mwAware_USER, (char *)[[theContact UID] UTF8String], NULL };
	
	const char				*statusMessageText = (const char *)mwServiceAware_getText(pd->srvc_aware, &t);
	NSString				*statusMessageString = [NSString stringWithUTF8String:statusMessageText];
	
	if (statusMessageString && [statusMessageString length]){
		statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
														 attributes:nil] autorelease];
	}
	
	return statusMessage;
#endif
}

@end
