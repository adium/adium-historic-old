//
//  ESGaimMeanwhileAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimMeanwhileAccount.h"

@interface ESGaimMeanwhileAccount (PRIVATE)
- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact;
@end

@implementation ESGaimMeanwhileAccount

#ifndef MEANWHILE_NOT_AVAILABLE

static BOOL didInitMeanwhile = NO;

- (const char*)protocolPlugin
{
	[super initSSL];
	if (!didInitMeanwhile) didInitMeanwhile = gaim_init_meanwhile_plugin(); 
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
	[super updateAwayReturn:theContact withData:data];
	
	[theContact setStatusObject:[self statusMessageForContact:theContact]
						 forKey:@"StatusMessage"
						 notify:YES];
}

#pragma mark Status Messages
- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	SEL updateSelector = nil;
	
	switch ([event intValue]){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
	}
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	NSAttributedString	*newStatusMessage = [self statusMessageForContact:theContact];
	NSAttributedString	*oldStatusMessage = [theContact statusObjectForKey:@"StatusMessage"];

	if(!oldStatusMessage || ![[newStatusMessage string] isEqualToString:[oldStatusMessage string]]){
		[theContact setStatusObject:newStatusMessage
							 forKey:@"StatusMessage"
							 notify:YES];
	}
}

- (NSAttributedString *)statusMessageForContact:(AIListContact *)theContact
{
	NSAttributedString		*statusMessage = nil;
	GaimConnection			*gc = [self gaimAccount]->gc;
		
	struct mw_plugin_data	*pd = ((struct mw_plugin_data *)(gc->proto_data));
	struct mwAwareIdBlock	t = { mwAware_USER, (char *)[[theContact UID] UTF8String], NULL };
	
	const char				*statusMessageText = (const char *)mwServiceAware_getText(pd->srvc_aware, &t);
	NSString				*statusMessageString = (statusMessageText ? [NSString stringWithUTF8String:statusMessageText] : nil);
	
	if (statusMessageString && [statusMessageString length]){
		statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
														 attributes:nil] autorelease];
	}
	
	return statusMessage;
}
#endif
@end
