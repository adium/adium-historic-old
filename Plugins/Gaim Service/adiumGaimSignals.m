//
//  adiumGaimSignals.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimSignals.h"

static void buddy_event_cb(GaimBuddy *buddy, GaimBuddyEvent event)
{
	if (buddy){
		SEL updateSelector = nil;
		id data = nil;
		
		AIListContact   *theContact = contactLookupFromBuddy(buddy);
		
		switch(event){
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
				if (buddy->signon){
					data = [NSDate dateWithTimeIntervalSince1970:buddy->signon];
				}
				break;
			}
			case GAIM_BUDDY_AWAY:{
				updateSelector = @selector(updateWentAway:withData:);
				break;
			}
			case GAIM_BUDDY_AWAY_RETURN: {
				updateSelector = @selector(updateAwayReturn:withData:);
				break;
			}
			case GAIM_BUDDY_IDLE:
			case GAIM_BUDDY_IDLE_RETURN: {
				if (buddy->idle != 0){
					updateSelector = @selector(updateWentIdle:withData:);
					
					if (buddy->idle != -1){
						data = [NSDate dateWithTimeIntervalSince1970:buddy->idle];
					}
				}else{
					updateSelector = @selector(updateIdleReturn:withData:);	
				}
				break;
			}
			case GAIM_BUDDY_EVIL: {
				updateSelector = @selector(updateEvil:withData:);
				if (buddy->evil){
					data = [NSNumber numberWithInt:buddy->evil];
				}
				break;
			}
			case GAIM_BUDDY_ICON: {
				GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
				updateSelector = @selector(updateIcon:withData:);
				
				if (buddyIcon){
					const char  *iconData;
					size_t		len;
					
					iconData = gaim_buddy_icon_get_data(buddyIcon, &len);
					
					if (iconData && len){
						data = [NSData dataWithBytes:iconData
											  length:len];
					}
				}
				break;
			}
			default: {
				data = [NSNumber numberWithInt:event];
			}
		}
		
		if (updateSelector){
			[accountLookup(buddy->account) mainPerformSelector:updateSelector
													withObject:theContact
													withObject:data];
		}else{
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:forEvent:)
													withObject:theContact
													withObject:data];
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
}
