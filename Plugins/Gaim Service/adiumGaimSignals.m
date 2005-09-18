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
				updateSelector = @selector(updateSignonTime:withData:);
				if (buddy->signon) {
					data = [NSDate dateWithTimeIntervalSince1970:buddy->signon];
				}
				break;
			}
			case GAIM_BUDDY_AWAY:
			case GAIM_BUDDY_AWAY_RETURN: 
			case GAIM_BUDDY_STATUS_MESSAGE: {
				NSNumber			*statusTypeNumber;
				NSString			*statusName;
				NSAttributedString	*statusMessage;

				statusTypeNumber = [NSNumber numberWithInt:((buddy->uc & UC_UNAVAILABLE) ? 
															AIAwayStatusType : 
															AIAvailableStatusType)];
				statusName = [account statusNameForGaimBuddy:buddy];
				statusMessage = [account statusMessageForGaimBuddy:buddy];

				[account mainPerformSelector:@selector(updateStatusForContact:toStatusType:statusName:statusMessage:)
								  withObject:theContact
								  withObject:statusTypeNumber
								  withObject:statusName
								  withObject:statusMessage];
				
				letAccountHandleUpdate = NO;
				break;
			}

			case GAIM_BUDDY_IDLE:
			case GAIM_BUDDY_IDLE_RETURN: {
				if (buddy->idle != 0) {
					updateSelector = @selector(updateWentIdle:withData:);
					
					if (buddy->idle != -1) {
						data = [NSDate dateWithTimeIntervalSince1970:buddy->idle];
					}
				} else {
					updateSelector = @selector(updateIdleReturn:withData:);	
				}
				break;
			}
			case GAIM_BUDDY_EVIL: {
				updateSelector = @selector(updateEvil:withData:);
				if (buddy->evil) {
					data = [NSNumber numberWithInt:buddy->evil];
				}
				break;
			}
			case GAIM_BUDDY_ICON: {
				GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
				updateSelector = @selector(updateIcon:withData:);
				
				if (buddyIcon) {
					const char  *iconData;
					size_t		len;
					
					iconData = gaim_buddy_icon_get_data(buddyIcon, &len);
					
					if (iconData && len) {
						data = [NSData dataWithBytes:iconData
											  length:len];
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
				[account mainPerformSelector:updateSelector
								  withObject:theContact
								  withObject:data];
			} else {
				[account mainPerformSelector:@selector(updateContact:forEvent:)
								  withObject:theContact
								  withObject:data];
			}
		}
	}
}

void configureAdiumGaimSignals(void)
{
	void *blist_handle = gaim_blist_get_handle();
	void *handle       = adium_gaim_get_handle();
	
	//Idle
	gaim_signal_connect(blist_handle, "buddy-idle",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_IDLE));
	gaim_signal_connect(blist_handle, "buddy-idle-updated",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_IDLE));
	gaim_signal_connect(blist_handle, "buddy-unidle",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_IDLE_RETURN));
	
	//Status
	gaim_signal_connect(blist_handle, "buddy-away",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_AWAY));
	gaim_signal_connect(blist_handle, "buddy-back",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_AWAY_RETURN));
	gaim_signal_connect(blist_handle, "buddy-status-message",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_STATUS_MESSAGE));
	
	//Info updated
	gaim_signal_connect(blist_handle, "buddy-info",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_INFO_UPDATED));
	
	//Icon
	gaim_signal_connect(blist_handle, "buddy-icon",
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
	gaim_signal_connect(blist_handle, "buddy-signon",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNON_TIME));
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
