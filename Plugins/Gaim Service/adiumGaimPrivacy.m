/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "adiumGaimPrivacy.h"
#import <AIUtilities/CBObjectAdditions.h>

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
