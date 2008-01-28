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

#import "adiumPurpleBlist.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIListContact.h>

static NSMutableDictionary	*groupDict = nil;
static NSMutableDictionary	*aliasDict = nil;

static void adiumPurpleBlistNewList(PurpleBuddyList *list)
{

}

static void adiumPurpleBlistNewNode(PurpleBlistNode *node)
{
	
}

static void adiumPurpleBlistShow(PurpleBuddyList *list)
{
	
}

static void adiumPurpleBlistUpdate(PurpleBuddyList *list, PurpleBlistNode *node)
{
	if (PURPLE_BLIST_NODE_IS_BUDDY(node)) {
		PurpleBuddy *buddy = (PurpleBuddy*)node;

		//Take no action if the relevant account isn't online.
		if (!purple_buddy_get_account(buddy) || !purple_account_is_connected(purple_buddy_get_account(buddy)))
			return;
		   
		AIListContact	*theContact = contactLookupFromBuddy(buddy);

		PurpleGroup		*g = purple_buddy_get_group(buddy);
		NSString		*groupName = ((g && purple_group_get_name(g)) ? [NSString stringWithUTF8String:purple_group_get_name(g)] : nil);
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

			/* We pass in purple_buddy_get_name(buddy) directly (without filtering or normalizing it) as it may indicate a 
			 * formatted version of the UID.  We have a signal for when a rename occurs, but passing here lets us get
			 * formatted names which are originally formatted in a way which differs from the results of normalization.
			 * For example, TekJew will normalize to tekjew in AIM; we want to use tekjew internally but display TekJew.
			 */
			NSString	*contactName;
			contactName = [NSString stringWithUTF8String:purple_buddy_get_name(buddy)];

			//Store the new string in our aliasDict
			if (groupName) {
				[groupDict setObject:groupName forKey:buddyValue];
			} else {
				[groupDict removeObjectForKey:buddyValue];
			}

			[accountLookup(purple_buddy_get_account(buddy)) updateContact:theContact
											 toGroupName:groupName
											 contactName:contactName];
		}
		
		/* We have no way of differentiating when the buddy's alias changes versus when we get an update
		 * for a different status event.  We don't want to send to the main thread a used alias every time
		 * we get any update, but we do want to pass on a changed alias.  We therefore use the static
		 * aliasDict NSMutableDictionary to track what alias was last used for each buddy.  The first invocation,
		 * and subsequent invocations for the same alias, are passed back to the main thread for processing. */
		const char	*alias = purple_buddy_get_alias_only(buddy);
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
				[accountLookup(purple_buddy_get_account(buddy)) updateContact:theContact
													 toAlias:aliasString];
			}
		}
	}
}

//A buddy was removed from the list
static void adiumPurpleBlistRemove(PurpleBuddyList *list, PurpleBlistNode *node)
{
    NSCAssert(node != nil, @"BlistRemove on null node");
    if (PURPLE_BLIST_NODE_IS_BUDDY(node)) {
		PurpleBuddy	*buddy = (PurpleBuddy*) node;
		NSValue		*buddyValue = [NSValue valueWithPointer:buddy];

//		AILog(@"adiumPurpleBlistRemove %s",purple_buddy_get_name(buddy));
		[accountLookup(purple_buddy_get_account(buddy)) removeContact:contactLookupFromBuddy(buddy)];

		//Clear our dictionaries
		[groupDict removeObjectForKey:buddyValue];
		[aliasDict removeObjectForKey:buddyValue];

		//Clear the ui_data
		[(id)buddy->node.ui_data release]; buddy->node.ui_data = NULL;
    }
}

static void adiumPurpleBlistDestroy(PurpleBuddyList *list)
{
    //Here we're responsible for destroying what we placed in list's ui_data earlier
    AILog(@"adiumPurpleBlistDestroy");
}

static void adiumPurpleBlistSetVisible(PurpleBuddyList *list, gboolean show)
{
    AILog(@"adiumPurpleBlistSetVisible: %i",show);
}

static void adiumPurpleBlistRequestAddBuddy(PurpleAccount *account, const char *username, const char *group, const char *alias)
{
	[accountLookup(account) requestAddContactWithUID:[NSString stringWithUTF8String:username]];
}

static void adiumPurpleBlistRequestAddChat(PurpleAccount *account, PurpleGroup *group, const char *alias, const char *name)
{
    AILog(@"adiumPurpleBlistRequestAddChat");
}

static void adiumPurpleBlistRequestAddGroup(void)
{
    AILog(@"adiumPurpleBlistRequestAddGroup");
}

static PurpleBlistUiOps adiumPurpleBlistOps = {
    adiumPurpleBlistNewList,
    adiumPurpleBlistNewNode,
    adiumPurpleBlistShow,
    adiumPurpleBlistUpdate,
    adiumPurpleBlistRemove,
    adiumPurpleBlistDestroy,
    adiumPurpleBlistSetVisible,
    adiumPurpleBlistRequestAddBuddy,
    adiumPurpleBlistRequestAddChat,
    adiumPurpleBlistRequestAddGroup
};

PurpleBlistUiOps *adium_purple_blist_get_ui_ops(void)
{
	return &adiumPurpleBlistOps;
}
