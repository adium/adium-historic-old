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

#import "adiumGaimBlist.h"
#import <AIUtilities/CBObjectAdditions.h>
#import <Adium/AIListContact.h>

static void adiumGaimBlistNewList(GaimBuddyList *list)
{
    //We're allowed to place whatever we want in blist's ui_data.    
}

static void adiumGaimBlistNewNode(GaimBlistNode *node)
{
	
}

static void adiumGaimBlistShow(GaimBuddyList *list)
{
	
}

static void adiumGaimBlistUpdate(GaimBuddyList *list, GaimBlistNode *node)
{
	if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
		GaimBuddy *buddy = (GaimBuddy*)node;
		
		AIListContact	*theContact = contactLookupFromBuddy(buddy);
		NSString		*remoteGroupName = [theContact remoteGroupName];
		GaimGroup		*g = gaim_find_buddys_group(buddy);
		NSString		*groupName = ((g && g->name) ? [NSString stringWithUTF8String:g->name] : nil);

		//Group changes, including the initial notification of the group
		//We also use this opportunity to check the contact's name against its formattedUID
		if(!remoteGroupName || ![remoteGroupName isEqualToString:groupName]){
			NSString	*contactName;

			contactName = [NSString stringWithUTF8String:buddy->name];
			
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toGroupName:contactName:)
													withObject:theContact
													withObject:groupName
													withObject:contactName];
		}
		
		const char	*alias = gaim_buddy_get_alias(buddy);
		if (alias){
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toAlias:)
													withObject:theContact
													withObject:[NSString stringWithUTF8String:alias]];
		}
	}
}

//A buddy was removed from the list
static void adiumGaimBlistRemove(GaimBuddyList *list, GaimBlistNode *node)
{
    NSCAssert(node != nil, @"BlistRemove on null node");
    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
		GaimBuddy *buddy = (GaimBuddy*) node;
		
		[accountLookup(buddy->account) mainPerformSelector:@selector(removeContact:)
												withObject:contactLookupFromBuddy(buddy)];
		
		//Clear the ui_data
		[(id)buddy->node.ui_data release]; buddy->node.ui_data = NULL;
    }
}

static void adiumGaimBlistDestroy(GaimBuddyList *list)
{
    //Here we're responsible for destroying what we placed in list's ui_data earlier
    GaimDebug (@"adiumGaimBlistDestroy");
}

static void adiumGaimBlistSetVisible(GaimBuddyList *list, gboolean show)
{
    GaimDebug (@"adiumGaimBlistSetVisible: %i",show);
}

static void adiumGaimBlistRequestAddBuddy(GaimAccount *account, const char *username, const char *group, const char *alias)
{
	[accountLookup(account) mainPerformSelector:@selector(requestAddContactWithUID:)
									 withObject:[NSString stringWithUTF8String:username]];
}

static void adiumGaimBlistRequestAddChat(GaimAccount *account, GaimGroup *group, const char *alias, const char *name)
{
    GaimDebug (@"adiumGaimBlistRequestAddChat");
}

static void adiumGaimBlistRequestAddGroup(void)
{
    GaimDebug (@"adiumGaimBlistRequestAddGroup");
}

static GaimBlistUiOps adiumGaimBlistOps = {
    adiumGaimBlistNewList,
    adiumGaimBlistNewNode,
    adiumGaimBlistShow,
    adiumGaimBlistUpdate,
    adiumGaimBlistRemove,
    adiumGaimBlistDestroy,
    adiumGaimBlistSetVisible,
    adiumGaimBlistRequestAddBuddy,
    adiumGaimBlistRequestAddChat,
    adiumGaimBlistRequestAddGroup
};

GaimBlistUiOps *adium_gaim_blist_get_ui_ops(void)
{
	return &adiumGaimBlistOps;
}
