//
//  adiumGaimPrivacy.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimPrivacy.h"


static void adiumGaimPermitAdded(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyPermitListAdded:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}
static void adiumGaimPermitRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyPermitListRemoved:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}
static void adiumGaimDenyAdded(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyDenyListAdded:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}
static void adiumGaimDenyRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyDenyListRemoved:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}

static GaimPrivacyUiOps adiumGaimPrivacyOps = {
    adiumGaimPermitAdded,
    adiumGaimPermitRemoved,
    adiumGaimDenyAdded,
    adiumGaimDenyRemoved
};

GaimPrivacyUiOps *adium_gaim_privacy_get_ui_ops()
{
	return &adiumGaimPrivacyOps;
}
