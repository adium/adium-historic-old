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
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIListContact.h>

static NSMutableDictionary	*groupDict = nil;
static NSMutableDictionary	*aliasDict = nil;

static void adiumGaimBlistNewList(GaimBuddyList *list)
{

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

		//Take no action if the relevant account isn't online.
		if (!buddy->account || !gaim_account_is_connected(buddy->account))
			return;
		   
		AIListContact	*theContact = contactLookupFromBuddy(buddy);

		GaimGroup		*g = gaim_buddy_get_group(buddy);
		NSString		*groupName = ((g && g->name) ? [NSString stringWithUTF8String:g->name] : nil);
		NSString		*oldGroupName;
		NSValue			*buddyValue = [NSValue valueWithPointer:buddy];

		//Group changes, including the initial notification of the group
		//We also use this opportunity to check the contact's name against its formattedUID
		if (!groupDict) groupDict = [[NSMutableDictionary alloc] init];

		/* If there is no old group name, or there is and there is no current group name, or the two don't match,
		 * update our group information. */
		if (!(oldGroupName = [groupDict objectForKey:buddyValue]) ||
		   !(groupName) ||
		   !([oldGroupName isEqualToString:groupName])) {

			/* We pass in buddy->name directly (without filtering or normalizing it) as it may indicate a 
			 * formatted version of the UID.  We have a signal for when a rename occurs, but passing here lets us get
			 * formatted names which are originally formatted in a way which differs from the results of normalization.
			 * For example, TekJew will normalize to tekjew in AIM; we want to use tekjew internally but display TekJew.
			 */
			NSString	*contactName;
			contactName = [NSString stringWithUTF8String:buddy->name];

			//Store the new string in our aliasDict
			if (groupName) {
				[groupDict setObject:groupName forKey:buddyValue];
			} else {
				[groupDict removeObjectForKey:buddyValue];
			}

			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toGroupName:contactName:)
													withObject:theContact
													withObject:groupName
													withObject:contactName];
		}
		
		/* We have no way of differentiating when the buddy's alias changes versus when we get an update
		 * for a different status event.  We don't want to send to the main thread a used alias every time
		 * we get any update, but we do want to pass on a changed alias.  We therefore use the static
		 * aliasDict NSMutableDictionary to track what alias was last used for each buddy.  The first invocation,
		 * and subsequent invocations for the same alias, are passed back to the main thread for processing. */
		const char	*alias = gaim_buddy_get_alias_only(buddy);
		if (alias) {
			NSString	*aliasString = [NSString stringWithUTF8String:alias];
			NSString	*oldAliasString;
			
			if (!aliasDict) aliasDict = [[NSMutableDictionary alloc] init];

			if (![aliasString isEqualToString:[theContact UID]] &&
			   (!(oldAliasString = [aliasDict objectForKey:buddyValue]) ||
			   (![oldAliasString isEqualToString:aliasString]))) {

				//Store the new string in our aliasDict
				if (aliasString) {
					[aliasDict setObject:aliasString forKey:buddyValue];
				} else {
					[aliasDict removeObjectForKey:buddyValue];
				}
				
				//Send it to the main thread
				[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toAlias:)
														withObject:theContact
														withObject:aliasString];
			}
		}
	}
}

//A buddy was removed from the list
static void adiumGaimBlistRemove(GaimBuddyList *list, GaimBlistNode *node)
{
    NSCAssert(node != nil, @"BlistRemove on null node");
    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
		GaimBuddy	*buddy = (GaimBuddy*) node;
		NSValue		*buddyValue = [NSValue valueWithPointer:buddy];

//		GaimDebug (@"adiumGaimBlistRemove %s",buddy->name);
		[accountLookup(buddy->account) mainPerformSelector:@selector(removeContact:)
												withObject:contactLookupFromBuddy(buddy)];

		//Clear our dictionaries
		[groupDict removeObjectForKey:buddyValue];
		[aliasDict removeObjectForKey:buddyValue];

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
