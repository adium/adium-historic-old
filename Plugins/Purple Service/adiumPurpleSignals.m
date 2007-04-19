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

#import "adiumPurpleSignals.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIListContact.h>

static void buddy_status_changed_cb(PurpleBuddy *buddy, PurpleStatus *oldstatus, PurpleStatus *status, PurpleBuddyEvent event);
static void buddy_idle_changed_cb(PurpleBuddy *buddy, gboolean old_idle, gboolean idle, PurpleBuddyEvent event);

static void buddy_event_cb(PurpleBuddy *buddy, PurpleBuddyEvent event)
{
	if (buddy) {
		SEL				updateSelector = nil;
		id				data = nil;
		BOOL			letAccountHandleUpdate = YES;
		CBPurpleAccount	*account = accountLookup(buddy->account);
		AIListContact   *theContact = contactLookupFromBuddy(buddy);

		switch (event) {
			case PURPLE_BUDDY_SIGNON: {
				updateSelector = @selector(updateSignon:withData:);
				break;
			}
			case PURPLE_BUDDY_SIGNOFF: {
				updateSelector = @selector(updateSignoff:withData:);
				break;
			}
			case PURPLE_BUDDY_SIGNON_TIME: {
				PurplePresence	*presence = purple_buddy_get_presence(buddy);
				time_t			loginTime = purple_presence_get_login_time(presence);
				
				updateSelector = @selector(updateSignonTime:withData:);
				data = (loginTime ? [NSDate dateWithTimeIntervalSince1970:loginTime] : nil);

				break;
			}

			case PURPLE_BUDDY_EVIL: {
				updateSelector = @selector(updateEvil:withData:);
				//XXX EVIL?
				/*
				if (buddy->evil) {
					data = [NSNumber numberWithInt:buddy->evil];
				}
				 */
				break;
			}
			case PURPLE_BUDDY_ICON: {
				PurpleBuddyIcon *buddyIcon = purple_buddy_get_icon(buddy);
				updateSelector = @selector(updateIcon:withData:);
				AILog(@"Buddy icon update for %s",buddy->name);
				if (buddyIcon) {
					const guchar  *iconData;
					size_t		len;
					
					iconData = purple_buddy_icon_get_data(buddyIcon, &len);
					
					if (iconData && len) {
						data = [NSData dataWithBytes:iconData
											  length:len];
						AILog(@"[buddy icon: %s got data]",buddy->name);
					}
				}
				break;
			}
			case PURPLE_BUDDY_NAME: {
				updateSelector = @selector(renameContact:toUID:);

				data = [NSString stringWithUTF8String:buddy->name];
				AILog(@"Renaming %@ to %@",theContact,data);
				break;
			}
			default: {
				data = [NSNumber numberWithInt:event];
				break;
			}
		}
		
		if (letAccountHandleUpdate) {
			if (updateSelector) {
				[account performSelector:updateSelector
							  withObject:theContact
							  withObject:data];
			} else {
				[account updateContact:theContact
							  forEvent:data];
			}
		}
		
		/* If a status event didn't change from its previous value, we won't be notified of it.
		 * That's generally a good thing, but we clear some values when a contact signs off, including
		 * status, idle time, and signed-on time.  Manually update these as appropriate when we're informed of
		 * a signon.
		 */
		if ((event == PURPLE_BUDDY_SIGNON) || (event == PURPLE_BUDDY_SIGNOFF)) {
			PurplePresence	*presence = purple_buddy_get_presence(buddy);
			PurpleStatus		*status = purple_presence_get_active_status(presence);
			buddy_status_changed_cb(buddy, NULL, status, event);
			
			if (event == PURPLE_BUDDY_SIGNON) {
				buddy_idle_changed_cb(buddy, FALSE, purple_presence_is_idle(presence), event);
				buddy_event_cb(buddy, PURPLE_BUDDY_SIGNON_TIME);
			}
		}
	}
}

static void buddy_status_changed_cb(PurpleBuddy *buddy, PurpleStatus *oldstatus, PurpleStatus *status, PurpleBuddyEvent event)
{
	CBPurpleAccount		*account = accountLookup(buddy->account);
	AIListContact		*theContact = contactLookupFromBuddy(buddy);
	NSNumber			*statusTypeNumber;
	NSString			*statusName;
	NSAttributedString	*statusMessage;	
	BOOL				isAvailable;

	isAvailable = ((purple_status_type_get_primitive(purple_status_get_type(status)) == GAIM_STATUS_AVAILABLE) ||
				   (purple_status_type_get_primitive(purple_status_get_type(status)) == GAIM_STATUS_OFFLINE));

	statusTypeNumber = [NSNumber numberWithInt:(isAvailable ? 
												AIAvailableStatusType : 
												AIAwayStatusType)];

	statusName = [account statusNameForPurpleBuddy:buddy];
	statusMessage = [account statusMessageForPurpleBuddy:buddy];

	//XXX This is done so MSN can ignore it since it's currently buggy in libgaim
	[account updateMobileStatus:theContact
					   withData:(purple_presence_is_status_primitive_active(purple_buddy_get_presence(buddy), GAIM_STATUS_MOBILE))];

	//Will also notify
	[account updateStatusForContact:theContact
					   toStatusType:statusTypeNumber
						 statusName:statusName
					  statusMessage:statusMessage];
}

static void buddy_idle_changed_cb(PurpleBuddy *buddy, gboolean old_idle, gboolean idle, PurpleBuddyEvent	event)
{
	CBPurpleAccount	*account = accountLookup(buddy->account);
	AIListContact	*theContact = contactLookupFromBuddy(buddy);
	PurplePresence	*presence = purple_buddy_get_presence(buddy);
				
	if (idle) {
		time_t		idleTime = purple_presence_get_idle_time(presence);

		[account updateWentIdle:theContact
					   withData:(idleTime ?
									  [NSDate dateWithTimeIntervalSince1970:idleTime] :
									  nil)];
	} else {
		[account updateIdleReturn:theContact
						 withData:nil];
	}
}

static void buddy_added_cb(PurpleBuddy *buddy)
{
	PurpleGroup		*g = purple_buddy_get_group(buddy);

	/* We pass in buddy->name directly (without filtering or normalizing it) as it may indicate a 
	 * formatted version of the UID.  We have a signal for when a rename occurs, but passing here lets us get
	 * formatted names which are originally formatted in a way which differs from the results of normalization.
	 * For example, TekJew will normalize to tekjew in AIM; we want to use tekjew internally but display TekJew.
	 */	
	[accountLookup(buddy->account) updateContact:contactLookupFromBuddy(buddy)
									 toGroupName:((g && g->name) ? [NSString stringWithUTF8String:g->name] : nil)
									 contactName:(buddy->name ? [NSString stringWithUTF8String:buddy->name] : nil)];
}

void configureAdiumPurpleSignals(void)
{
	void *blist_handle = purple_blist_get_handle();
	void *handle       = adium_purple_get_handle();

	purple_signal_connect(blist_handle, "buddy-added",
						handle, GAIM_CALLBACK(buddy_added_cb),
						GINT_TO_POINTER(0));

	//Idle
	purple_signal_connect(blist_handle, "buddy-idle-changed",
						handle, GAIM_CALLBACK(buddy_idle_changed_cb),
						GINT_TO_POINTER(0));
	
	//Status
	purple_signal_connect(blist_handle, "buddy-status-changed",
						handle, GAIM_CALLBACK(buddy_status_changed_cb),
						GINT_TO_POINTER(0));

	//Icon
	purple_signal_connect(blist_handle, "buddy-icon-changed",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_ICON));

	//Signon / Signoff
	purple_signal_connect(blist_handle, "buddy-signed-on",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNON));
	purple_signal_connect(blist_handle, "buddy-signed-off",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNOFF));	
	purple_signal_connect(blist_handle, "buddy-got-login-time",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNON_TIME));	
}
