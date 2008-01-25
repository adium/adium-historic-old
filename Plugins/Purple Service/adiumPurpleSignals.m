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
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>

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
	BOOL				isAvailable, isMobile;

	isAvailable = ((purple_status_type_get_primitive(purple_status_get_type(status)) == PURPLE_STATUS_AVAILABLE) ||
				   (purple_status_type_get_primitive(purple_status_get_type(status)) == PURPLE_STATUS_OFFLINE));
	isMobile = purple_presence_is_status_primitive_active(purple_buddy_get_presence(buddy), PURPLE_STATUS_MOBILE);
	statusTypeNumber = [NSNumber numberWithInt:(isAvailable ? 
												AIAvailableStatusType : 
												AIAwayStatusType)];

	statusName = [account statusNameForPurpleBuddy:buddy];
	statusMessage = [account statusMessageForPurpleBuddy:buddy];

	//XXX This is done so MSN can ignore it since it's currently buggy in libpurple
	[account updateMobileStatus:theContact
					   withData:isMobile];
	
	//Will also notify
	[account updateStatusForContact:theContact
					   toStatusType:statusTypeNumber
						 statusName:statusName
					  statusMessage:statusMessage];
}

static void buddy_idle_changed_cb(PurpleBuddy *buddy, gboolean old_idle, gboolean idle, PurpleBuddyEvent event)
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
				
	AILog(@"buddy_event_cb: %@ is %@ [old_idle %i, idle %i]",theContact,(idle ? @"idle" : @"not idle"),old_idle,idle);
}

static void typing_changed(PurpleAccount *acct, const char *name, AITypingState typingState)
{
	AIListContact *contact = contactLookupFromBuddy(purple_find_buddy(acct, name));
	[contact setStatusObject:[NSNumber numberWithInt:typingState] forKey:KEY_TYPING notify:NotifyNow];		
}

static void
buddy_typing_cb(PurpleAccount *acct, const char *name, void *data) {
	typing_changed(acct, name, AITyping);
}

static void
buddy_typed_cb(PurpleAccount *acct, const char *name, void *data) {
	typing_changed(acct, name, AIEnteredText);
}

static void
buddy_typing_stopped_cb(PurpleAccount *acct, const char *name, void *data) {
	typing_changed(acct, name, AINotTyping);
}

static void
file_recv_request_cb(PurpleXfer *xfer)
{
	ESFileTransfer  *fileTransfer;
	
	//Ask the account for an ESFileTransfer* object
	fileTransfer = [accountLookup(xfer->account) newFileTransferObjectWith:[NSString stringWithUTF8String:purple_xfer_get_remote_user(xfer)]
					size:purple_xfer_get_size(xfer)
					remoteFilename:[NSString stringWithUTF8String:purple_xfer_get_filename(xfer)]];
	
	//Configure the new object for the transfer
	[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
	
	xfer->ui_data = [fileTransfer retain];
	
	/* Set a fake local filename to convince libpurple that we are handling the request. We are, but
	 * the code expects a synchronous response, and we rock out asynchronously.
	 */
	purple_xfer_set_local_filename(xfer, "");
	
	//Tell the account that we are ready to request the reception
	[accountLookup(purple_xfer_get_account(xfer)) requestReceiveOfFileTransfer:fileTransfer];
}

void configureAdiumPurpleSignals(void)
{
	void *blist_handle = purple_blist_get_handle();
	void *handle       = adium_purple_get_handle();
	
	//Idle
	purple_signal_connect(blist_handle, "buddy-idle-changed",
						handle, PURPLE_CALLBACK(buddy_idle_changed_cb),
						GINT_TO_POINTER(0));
	
	//Status
	purple_signal_connect(blist_handle, "buddy-status-changed",
						handle, PURPLE_CALLBACK(buddy_status_changed_cb),
						GINT_TO_POINTER(0));

	//Icon
	purple_signal_connect(blist_handle, "buddy-icon-changed",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_ICON));

	//Signon / Signoff
	purple_signal_connect(blist_handle, "buddy-signed-on",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNON));
	purple_signal_connect(blist_handle, "buddy-signed-off",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNOFF));	
	purple_signal_connect(blist_handle, "buddy-got-login-time",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNON_TIME));	
	
	purple_signal_connect(purple_conversations_get_handle(), "buddy-typing",
						  handle, PURPLE_CALLBACK(buddy_typing_cb), NULL);
	
	purple_signal_connect(purple_conversations_get_handle(), "buddy-typed",
						  handle, PURPLE_CALLBACK(buddy_typed_cb), NULL);
	
	purple_signal_connect(purple_conversations_get_handle(), "buddy-typing-stopped",
						  handle, PURPLE_CALLBACK(buddy_typing_stopped_cb), NULL);

	purple_signal_connect(purple_xfers_get_handle(), "file-recv-request",
						  handle, PURPLE_CALLBACK(file_recv_request_cb), NULL);
}
