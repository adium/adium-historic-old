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

#import "adiumGaimSignals.h"
#import <AIUtilities/AIObjectAdditions.h>

static void buddy_status_changed_cb(GaimBuddy *buddy, GaimStatus *oldstatus, GaimStatus *status, GaimBuddyEvent event);

static void buddy_event_cb(GaimBuddy *buddy, GaimBuddyEvent event)
{
	if (buddy) {
		SEL				updateSelector = nil;
		id				data = nil;
		BOOL			letAccountHandleUpdate = YES;
		CBGaimAccount	*account = accountLookup(buddy->account);
		AIListContact   *theContact = contactLookupFromBuddy(buddy);

		switch (event) {
			case GAIM_BUDDY_SIGNON: {
				updateSelector = @selector(updateSignon:withData:);
				break;
			}
			case GAIM_BUDDY_SIGNOFF: {
				updateSelector = @selector(updateSignoff:withData:);
				break;
			}
			case GAIM_BUDDY_SIGNON_TIME: {
				GaimPresence	*presence = gaim_buddy_get_presence(buddy);
				time_t			loginTime = gaim_presence_get_login_time(presence);;
				
				updateSelector = @selector(updateSignonTime:withData:);
				data = (loginTime ? [NSDate dateWithTimeIntervalSince1970:loginTime] : nil);

				break;
			}

			case GAIM_BUDDY_EVIL: {
				updateSelector = @selector(updateEvil:withData:);
				//XXX EVIL?
				/*
				if (buddy->evil) {
					data = [NSNumber numberWithInt:buddy->evil];
				}
				 */
				break;
			}
			case GAIM_BUDDY_ICON: {
				GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
				updateSelector = @selector(updateIcon:withData:);
				AILog(@"Buddy icon update for %s",buddy->name);
				if (buddyIcon) {
					const guchar  *iconData;
					size_t		len;
					
					iconData = gaim_buddy_icon_get_data(buddyIcon, &len);
					
					if (iconData && len) {
						data = [NSData dataWithBytes:iconData
											  length:len];
						AILog(@"[buddy icon: %s got data]",buddy->name);
					}
				}
				break;
			}
			case GAIM_BUDDY_NAME: {
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
		
		//Update the contact's status if the event was a signon or signoff event, since the status changed event may not be sent.
		if (event == GAIM_BUDDY_SIGNON || event == GAIM_BUDDY_SIGNOFF) {
			GaimPresence	*presence = gaim_buddy_get_presence(buddy);
			GaimStatus		*status = gaim_presence_get_active_status(presence);
			buddy_status_changed_cb(buddy, NULL, status, event);
		}
	}
}

static void buddy_status_changed_cb(GaimBuddy *buddy, GaimStatus *oldstatus, GaimStatus *status, GaimBuddyEvent event)
{
	CBGaimAccount		*account = accountLookup(buddy->account);
	AIListContact		*theContact = contactLookupFromBuddy(buddy);
	NSNumber			*statusTypeNumber;
	NSString			*statusName;
	NSAttributedString	*statusMessage;	
	BOOL				isAvailable;

	GaimDebug(@"buddy_status_changed_cb: %@ (%i): name %s, message %s",
			  theContact,
			  gaim_status_type_get_primitive(gaim_status_get_type(status)),
			  gaim_status_get_name(status),
			  gaim_status_get_attr_string(status, "message"));

	isAvailable = ((gaim_status_type_get_primitive(gaim_status_get_type(status)) == GAIM_STATUS_AVAILABLE) ||
				   (gaim_status_type_get_primitive(gaim_status_get_type(status)) == GAIM_STATUS_OFFLINE));

	statusTypeNumber = [NSNumber numberWithInt:(isAvailable ? 
												AIAvailableStatusType : 
												AIAwayStatusType)];
	
	statusName = [account statusNameForGaimBuddy:buddy];
	statusMessage = [account statusMessageForGaimBuddy:buddy];

	[account updateStatusForContact:theContact
					   toStatusType:statusTypeNumber
						 statusName:statusName
					  statusMessage:statusMessage];
}

static void buddy_idle_changed_cb(GaimBuddy *buddy, gboolean old_idle, gboolean idle, GaimBuddyEvent event)
{
	CBGaimAccount	*account = accountLookup(buddy->account);
	AIListContact	*theContact = contactLookupFromBuddy(buddy);
	GaimPresence	*presence = gaim_buddy_get_presence(buddy);
				
	if (idle) {
		time_t		idleTime = gaim_presence_get_idle_time(presence);

		[account updateWentIdle:theContact
					   withData:(idleTime ?
									  [NSDate dateWithTimeIntervalSince1970:idleTime] :
									  nil)];
	} else {
		[account updateIdleReturn:theContact
						 withData:nil];
	}
				
	AILog(@"buddy_event_cb: %@ is %@ [old_idle %i, idle %i]",theContact,(idle ? @"idle" : @"not idle"),old_idle,idle);
}

void configureAdiumGaimSignals(void)
{
	void *blist_handle = gaim_blist_get_handle();
	void *handle       = adium_gaim_get_handle();
	
	//Idle
	gaim_signal_connect(blist_handle, "buddy-idle-changed",
						handle, GAIM_CALLBACK(buddy_idle_changed_cb),
						GINT_TO_POINTER(0));
	
	//Status
	gaim_signal_connect(blist_handle, "buddy-status-changed",
						handle, GAIM_CALLBACK(buddy_status_changed_cb),
						GINT_TO_POINTER(0));
	
	//Info updated
	gaim_signal_connect(blist_handle, "buddy-info",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_INFO_UPDATED));
	
	//Icon
	gaim_signal_connect(blist_handle, "buddy-icon-changed",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_ICON));
	
	//Evil
	gaim_signal_connect(blist_handle, "buddy-evil",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_EVIL));
	
	
	//Miscellaneous
	gaim_signal_connect(blist_handle, "buddy-miscellaneous",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_MISCELLANEOUS));
	
	//Signon / Signoff
	gaim_signal_connect(blist_handle, "buddy-signed-on",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNON));
	gaim_signal_connect(blist_handle, "buddy-signed-off",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNOFF));
	
	//DirectIM
	gaim_signal_connect(blist_handle, "buddy-direct-im-connected",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_DIRECTIM_CONNECTED));
	//DirectIM
	gaim_signal_connect(blist_handle, "buddy-direct-im-disconnected",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_DIRECTIM_DISCONNECTED));

	gaim_signal_connect(blist_handle, "buddy-renamed",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_NAME));
}
