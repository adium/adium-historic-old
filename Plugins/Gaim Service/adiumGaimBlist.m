//
//  adiumGaimBlist.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimBlist.h"

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
		
		AIListContact *theContact = contactLookupFromBuddy(buddy);
		
		//Group changes - gaim buddies start off in no group, so this is an important update for us
		//We also use this opportunity to check the contact's name against its formattedUID
		if(![theContact remoteGroupName]){
			GaimGroup	*g = gaim_find_buddys_group(buddy);
			NSString	*groupName;
			NSString	*contactName;
			
			groupName = ((g && g->name) ?
						 [NSString stringWithUTF8String:g->name] :
						 nil);
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
