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

#import "CBPurpleAccount.h"

#import <libpurple/notify.h>
#import <libpurple/cmds.h>
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentNotification.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIWindowController.h>
#import <Adium/AIEmoticon.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIContentStatus.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AISystemNetworkDefaults.h>
#import "ESiTunesPlugin.h"
#import "AMPurpleTuneTooltip.h"
#import "adiumPurpleRequest.h"
#import "AIDualWindowInterfacePlugin.h"

#import "ESMSNService.h" //why oh why must the superclass know about MSN specific things!?

#define NO_GROUP						@"__NoGroup__"

#define	PREF_GROUP_ALIASES			@"Aliases"		//Preference group to store aliases in
#define NEW_ACCOUNT_DISPLAY_TEXT		AILocalizedString(@"<New Account>", "Placeholder displayed as the name of a new account")

#define	KEY_PRIVACY_OPTION	@"Privacy Option"

@interface CBPurpleAccount (PRIVATE)
- (NSString *)_mapIncomingGroupName:(NSString *)name;
- (NSString *)_mapOutgoingGroupName:(NSString *)name;

- (void)setTypingFlagOfChat:(AIChat *)inChat to:(NSNumber *)typingState;

- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(PurpleMessageFlags)flags date:(NSDate *)date;
- (void)_sentMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat toDestinationListContact:(AIListContact *)destinationContact flags:(PurpleMessageFlags)flags date:(NSDate *)date;
- (NSString *)_messageImageCachePathForID:(int)imageID;

- (ESFileTransfer *)createFileTransferObjectForXfer:(PurpleXfer *)xfer;

- (NSNumber *)shouldCheckMail;

- (void)configurePurpleAccountNotifyingTarget:(id)target selector:(SEL)selector;
- (void)continueConnectWithConfiguredPurpleAccount;
- (void)continueConnectWithConfiguredProxy;
- (void)continueRegisterWithConfiguredPurpleAccount;
- (void)promptForHostBeforeConnecting;

- (void)setAccountProfileTo:(NSAttributedString *)profile configurePurpleAccountContext:(NSInvocation *)inInvocation;

- (void)performAccountMenuAction:(NSMenuItem *)sender;
@end

@implementation CBPurpleAccount

static SLPurpleCocoaAdapter *purpleAdapter = nil;

// The PurpleAccount currently associated with this Adium account
- (PurpleAccount*)purpleAccount
{
	//Create a purple account if one does not already exist
	if (!account) {
		[self createNewPurpleAccount];
		AILog(@"Created PurpleAccount 0x%x with UID %@, protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	}
	
    return account;
}

- (SLPurpleCocoaAdapter *)purpleAdapter
{
	if (!purpleAdapter) {
		purpleAdapter = [[SLPurpleCocoaAdapter sharedInstance] retain];	
	}	
	return purpleAdapter;
}

// Subclasses must override this
- (const char*)protocolPlugin { return NULL; }

// Contacts ------------------------------------------------------------------------------------------------
#pragma mark Contacts
- (void)newContact:(AIListContact *)theContact withName:(NSString *)inName
{

}

- (void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName contactName:(NSString *)contactName
{
	//When a new contact is created, if we aren't already silent and delayed, set it  a second to cover our initial
	//status updates
	if (!silentAndDelayed) {
		[self silenceAllContactUpdatesForInterval:2.0];
		[[adium contactController] delayListObjectNotificationsUntilInactivity];		
	}
	
	//If the name we were passed differs from the current formatted UID of the contact, it's itself a formatted UID
	//This is important since we may get an alias ("Evan Schoenberg") from the server but also want the formatted name
	if (![contactName isEqualToString:[theContact formattedUID]] && ![contactName isEqualToString:[theContact UID]]) {
		[theContact setValue:contactName
							 forProperty:@"FormattedUID"
							 notify:NotifyLater];
	}
	
	if (groupName && [groupName isEqualToString:@PURPLE_ORPHANS_GROUP_NAME]) {
		[theContact setRemoteGroupName:AILocalizedString(@"Orphans","Name for the orphans group")];
	} else if (groupName && [groupName length] != 0) {
		[theContact setRemoteGroupName:[self _mapIncomingGroupName:groupName]];
	} else {
		AILog(@"Got a nil group for %@",theContact);
	}
	
	[self gotGroupForContact:theContact];
}

/*!
 * @brief Change the UID of a contact
 *
 * If we're just passed a formatted version of the current UID, don't change the UID but instead use the information
 * as the FormattedUID.  For example, we get sent this when an AIM contact's name formatting changes; we always want
 * to use a lowercase and space-free version for the UID, however.
 */
- (void)renameContact:(AIListContact *)theContact toUID:(NSString *)newUID
{
	//If the name we were passed differs from the current formatted UID of the contact, it's itself a formatted UID
	//This is important since we may get an alias ("Evan Schoenberg") from the server but also want the formatted name
	NSString	*normalizedUID = [[self service] normalizeUID:newUID removeIgnoredCharacters:YES];
	
	if ([normalizedUID isEqualToString:[theContact UID]]) {
		[theContact setValue:newUID
							 forProperty:@"FormattedUID"
							 notify:NotifyLater];		
	} else {
		[theContact setUID:newUID];		
	}
}

- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)purpleAlias
{
	if (![[purpleAlias compactedString] isEqualToString:[[theContact UID] compactedString]]) {
		//Store this alias as the serverside display name so long as it isn't identical when unformatted to the UID
		[theContact setServersideAlias:purpleAlias
					   asStatusMessage:[self useDisplayNameAsStatusMessage]
							  silently:silentAndDelayed];

	} else {
		//If it's the same characters as the UID, apply it as a formatted UID
		if (![purpleAlias isEqualToString:[theContact formattedUID]] && 
			![purpleAlias isEqualToString:[theContact UID]]) {
			[theContact setFormattedUID:purpleAlias
								 notify:NotifyLater];

			//Apply any changes
			[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
		}
	}
}

- (BOOL)useDisplayNameAsStatusMessage
{
	return NO;
}

- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
}		


//Signed online
- (void)updateSignon:(AIListContact *)theContact withData:(void *)data
{
	[theContact setOnline:YES
				   notify:NotifyLater
				 silently:silentAndDelayed];

	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}

//Signed offline
- (void)updateSignoff:(AIListContact *)theContact withData:(void *)data
{
	[theContact setOnline:NO
				   notify:NotifyLater
				 silently:silentAndDelayed];
	
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}

//Signon Time
- (void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate
{	
	[theContact setSignonDate:signonDate
					   notify:NotifyLater];
	
	//Apply any changes
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}

/*!
 * @brief Status name to use for a Purple buddy
 */
- (NSString *)statusNameForPurpleBuddy:(PurpleBuddy *)buddy
{
	return nil;
}

/*!
 * @brief Status message for a contact
 */
- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)buddy
{
	PurplePresence		*presence = purple_buddy_get_presence(buddy);
	PurpleStatus		*status = (presence ? purple_presence_get_active_status(presence) : NULL);
	const char			*message = (status ? purple_status_get_attr_string(status, "message") : NULL);
	
	return (message ? [AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String:message]] : nil);
}

/*!
 * @brief Update the status message and away state of the contact
 */
- (void)updateStatusForContact:(AIListContact *)theContact toStatusType:(NSNumber *)statusTypeNumber statusName:(NSString *)statusName statusMessage:(NSAttributedString *)statusMessage
{
	[theContact setStatusWithName:statusName
					   statusType:[statusTypeNumber intValue]
						   notify:NotifyLater];
	[theContact setStatusMessage:statusMessage
						  notify:NotifyLater];
	
	//Apply the change
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}

//Idle time
- (void)updateWentIdle:(AIListContact *)theContact withData:(NSDate *)idleSinceDate
{
	[theContact setIdle:YES sinceDate:idleSinceDate notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}
- (void)updateIdleReturn:(AIListContact *)theContact withData:(void *)data
{
	[theContact setIdle:NO
			  sinceDate:nil
				 notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}
	
//Evil level (warning level)
- (void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber
{
	[theContact setWarningLevel:[evilNumber intValue]
						 notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}


- (void)clearIconForContact:(AIListContact *)theContact
{
	[theContact setServersideIconData:nil
							   notify:NotifyLater];
	
	//Apply any changes
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];	
}

//Buddy Icon
- (void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(clearIconForContact:)
											   object:theContact];
	if (userIconData) {
		[theContact setServersideIconData:userIconData
								   notify:NotifyLater];
		
		//Apply any changes
		[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];

	} else {
		/* We may receive an empty icon update just before an actual change. We don't want to flicker through no-icon.
		 * We therefore cancel empty icon updates when we receive a new icon, and we do the actual clearing on a delay in case
		 * this is what is about to happen.
		 */
		[self performSelector:@selector(clearIconForContact:)
				   withObject:theContact
				   afterDelay:10.0];
	}
}

- (void)updateMobileStatus:(AIListContact *)theContact withData:(BOOL)isMobile
{
	[theContact setIsMobile:isMobile notify:NotifyLater];

	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}

- (NSString *)processedIncomingUserInfo:(NSString *)inString
{
	NSMutableString *returnString = nil;
	if ([inString rangeOfString:@"Purple could not find any information in the user's profile. The user most likely does not exist."].location != NSNotFound) {
		returnString = [[inString mutableCopy] autorelease];
		[returnString replaceOccurrencesOfString:@"Purple could not find any information in the user's profile. The user most likely does not exist."
									  withString:AILocalizedString(@"Adium could not find any information in the user's profile. This may not be a registered name.", "Message shown when a contact's profile can't be found")
										 options:NSLiteralSearch
										   range:NSMakeRange(0, [returnString length])];
	}
	
	return (returnString ? returnString : inString);
}

- (NSMutableArray *)arrayOfDictionariesFromPurpleNotifyUserInfo:(PurpleNotifyUserInfo *)user_info
{
	GList *l;
	NSMutableArray *array = [NSMutableArray array];
	
	for (l = purple_notify_user_info_get_entries(user_info); l != NULL; l = l->next) {
		PurpleNotifyUserInfoEntry *user_info_entry = l->data;
		
		switch (purple_notify_user_info_entry_get_type(user_info_entry)) {
			case PURPLE_NOTIFY_USER_INFO_ENTRY_SECTION_HEADER:
				[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								  [NSString stringWithUTF8String:purple_notify_user_info_entry_get_label(user_info_entry)], KEY_KEY,
								  [NSNumber numberWithInt:AIUserInfoSectionHeader], KEY_TYPE,
								  nil]];
				
				break;
			case PURPLE_NOTIFY_USER_INFO_ENTRY_SECTION_BREAK:
				[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:AIUserInfoSectionBreak], KEY_TYPE,
								  nil]];
				break;
				
			case PURPLE_NOTIFY_USER_INFO_ENTRY_PAIR:
			{
				if (purple_notify_user_info_entry_get_label(user_info_entry) && purple_notify_user_info_entry_get_value(user_info_entry)) {
					[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithUTF8String:purple_notify_user_info_entry_get_label(user_info_entry)], KEY_KEY,
									  processPurpleImages([NSString stringWithUTF8String:purple_notify_user_info_entry_get_value(user_info_entry)], self), KEY_VALUE,
									  nil]];
					
				} else if (purple_notify_user_info_entry_get_label(user_info_entry)) {
					[array addObject:[NSDictionary dictionaryWithObject:
									  [NSString stringWithUTF8String:purple_notify_user_info_entry_get_label(user_info_entry)]
																 forKey:KEY_KEY]];
				} else if (purple_notify_user_info_entry_get_value(user_info_entry)) {
					NSMutableString	*value = [processPurpleImages([NSString stringWithUTF8String:purple_notify_user_info_entry_get_value(user_info_entry)],
																  self) mutableCopy];
					NSEnumerator	*enumerator;
					NSString		*valuePair;
					[value replaceOccurrencesOfString:@"<br>" withString:@"<br/>" options:(NSCaseInsensitiveSearch | NSLiteralSearch)];
					[value replaceOccurrencesOfString:@"<br />" withString:@"<br/>" options:(NSCaseInsensitiveSearch | NSLiteralSearch)];
					[value replaceOccurrencesOfString:@"<B>" withString:@"<b>" options:NSLiteralSearch];

					enumerator = [[value componentsSeparatedByString:@"<br/><b>"] objectEnumerator];
					while ((valuePair = [enumerator nextObject])) {
						NSRange	firstStartBold = [valuePair rangeOfString:@"<b>"];
						NSRange	firstEndBold = [valuePair rangeOfString:@"</b>"];
						
						if (firstEndBold.length > 0) {
							// Chop off <b> from the beginning and :</b> from the end. The extra -1 is for the colon.
							[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											  [valuePair substringWithRange:NSMakeRange(firstStartBold.length, firstEndBold.location-firstStartBold.length-1)], KEY_KEY,
											  [valuePair substringFromIndex:NSMaxRange(firstEndBold)], KEY_VALUE,
											  nil]];
						} else {
							[array addObject:[NSDictionary dictionaryWithObject:valuePair
																		forKey:KEY_VALUE]];
						}
					}
					[value release];
				}	
				break;
			}
		}
	}

	return array;
}

- (void)updateUserInfo:(AIListContact *)theContact withData:(PurpleNotifyUserInfo *)user_info
{
	NSArray		*profileContents = [self arrayOfDictionariesFromPurpleNotifyUserInfo:user_info];
	[theContact setProfileArray:profileContents
					notify:NotifyLater];

	//Apply any changes
	[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
}

/*!
 * @brief Purple removed a contact from the local blist
 *
 * This can happen in many situations:
 *	- For every contact on an account when the account signs off
 *	- For a contact as it is deleted by the user
 *	- For a contact as it is deleted by Purple (e.g. when Sametime refuses an addition because it is known to be invalid)
 *	- In the middle of the move process as a contact moves from one group to another
 *
 * We need not take any action; we'll be notified of changes by Purple as necessary.
 */
- (void)removeContact:(AIListContact *)theContact
{

}

//To allow root level buddies on protocols which don't support them, we map any buddies in a group
//named after this account's UID to the root group.  These functions handle the mapping.  Group names should
//be filtered through incoming before being sent to Adium - and group names from Adium should be filtered through
//outgoing before being used.
- (NSString *)_mapIncomingGroupName:(NSString *)name
{
	if (!name || ([[name compactedString] caseInsensitiveCompare:[self UID]] == NSOrderedSame)) {
		return ADIUM_ROOT_GROUP_NAME;
	} else {
		return name;
	}
}
- (NSString *)_mapOutgoingGroupName:(NSString *)name
{
	if ([[name compactedString] caseInsensitiveCompare:ADIUM_ROOT_GROUP_NAME] == NSOrderedSame) {
		return [self UID];
	} else {
		return name;
	}
}

//Update the status of a contact (Request their profile)
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
    //Request profile
	AILogWithSignature(@"");
	[purpleAdapter getInfoFor:[inContact UID] onAccount:self];
}

- (void)requestAddContactWithUID:(NSString *)contactUID
{
	[[adium contactController] requestAddContactWithUID:contactUID
												service:[self _serviceForUID:contactUID]
												account:self];
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	return [self service];
}

- (void)gotGroupForContact:(AIListContact *)listContact {};

/*!
 * @brief Return the serverside icon for a contact
 */
- (NSData *)serversideIconDataForContact:(AIListContact *)contact
{
	PurpleBuddy		*buddy;
	NSData			*data = nil;

	if (account &&
		(buddy = purple_find_buddy(account, [[contact UID] UTF8String]))) {
		PurpleBuddyIcon *buddyIcon;
		BOOL			shouldUnref = NO;
		
		/* First, try to get a current buddy icon from the PurpleBuddy */
		buddyIcon = purple_buddy_get_icon(buddy);
		if (!buddyIcon) {
			/* Failing that, load one from the cache. We'll need to unreference the returned PurpleBuddyIcon
			 * when we're done.
			 */
			buddyIcon = purple_buddy_icons_find(account, [[contact UID] UTF8String]);
			shouldUnref = YES;
		}
		
		if (buddyIcon) {
			const guchar	*iconData;
			size_t			len;
			
			iconData = purple_buddy_icon_get_data(buddyIcon, &len);
			
			if (iconData && len) {
				data = [NSData dataWithBytes:iconData length:len];
			}
			
			if (shouldUnref)
				purple_buddy_icon_unref(buddyIcon);
		}

	} else {
		AILogWithSignature(@"Could not get serverside icon data for %@. account is %p", contact, account);
	}
	
	return data;
}

/*!
 * @brief Libpurple manages a contact icon cache; we don't need to duplicate it.
 */
- (BOOL)managesOwnContactIconCache
{
	return YES;
}

/*********************/
/* AIAccount_Handles */
/*********************/
#pragma mark Contact List Editing

- (void)removeContacts:(NSArray *)objects
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	
	while ((object = [enumerator nextObject])) {
		NSString	*groupName = [self _mapOutgoingGroupName:[object remoteGroupName]];

		//Have the purple thread perform the serverside actions
		[purpleAdapter removeUID:[object UID] onAccount:self fromGroup:groupName];
		
		//Remove it from Adium's list
		[object setRemoteGroupName:nil];
	}
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group
{
	NSEnumerator	*enumerator = [objects objectEnumerator];
	AIListContact	*object;
	NSString		*groupName = [self _mapOutgoingGroupName:[group UID]];
	
	while ((object = [enumerator nextObject])) {
		AILogWithSignature(@"%@ adding %@ to %@", self, [self _UIDForAddingObject:object], groupName);

		[purpleAdapter addUID:[self _UIDForAddingObject:object] onAccount:self toGroup:groupName];
		
		//Add it to Adium's list
		[object setRemoteGroupName:[group UID]]; //Use the non-mapped group name locally
	}
}

- (NSString *)_UIDForAddingObject:(AIListContact *)object
{
	return [object UID];
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	NSString		*groupName = [self _mapOutgoingGroupName:[group UID]];
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	//Move the objects to it
	enumerator = [objects objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([listObject isKindOfClass:[AIListGroup class]]) {
			//Since no protocol here supports nesting, a group move is really a re-name
			
		} else {
			//			NSString	*oldGroupName = [self _mapOutgoingGroupName:[listObject remoteGroupName]];
			
			//Tell the purple thread to perform the serverside operation
			[purpleAdapter moveUID:[listObject UID] onAccount:self toGroup:groupName];

			//Use the non-mapped group name locally
			[listObject setRemoteGroupName:[group UID]];
		}
	}		
}

- (void)renameGroup:(AIListGroup *)inGroup to:(NSString *)newName
{
	NSString		*groupName = [self _mapOutgoingGroupName:[inGroup UID]];

	//Tell the purple thread to perform the serverside operation	
	[purpleAdapter renameGroup:groupName onAccount:self to:newName];

	//We must also update the remote grouping of all our contacts in that group
	NSEnumerator	*enumerator = [[[adium contactController] allContactsInObject:inGroup recurse:YES onAccount:self] objectEnumerator];
	AIListContact	*contact;
	
	while ((contact = [enumerator nextObject])) {
		//Evan: should we use groupName or newName here?
		[contact setRemoteGroupName:newName];
	}
}

- (void)deleteGroup:(AIListGroup *)inGroup
{
	NSString		*groupName = [self _mapOutgoingGroupName:[inGroup UID]];

	[purpleAdapter deleteGroup:groupName onAccount:self];
}

// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    return [self online];
}

- (NSWindowController *)authorizationRequestWithDict:(NSDictionary*)dict {
	//We will release the returned window controller in -[self authorizationWindowController:authorizationWithDict:didAuthorize:]
	return [[[[AIObject sharedAdiumInstance] contactController] showAuthorizationRequestWithDict:dict
																					  forAccount:self] retain];
}

- (void)authorizationWindowController:(NSWindowController *)inWindowController authorizationWithDict:(NSDictionary *)infoDict response:(AIAuthorizationResponse)authorizationResponse
{
	if (account) {
		NSValue	*callback = nil;

		switch (authorizationResponse) {
			case AIAuthorizationAllowed:
				callback = [[[infoDict objectForKey:@"authorizeCB"] retain] autorelease];
				break;
			case AIAuthorizationDenied:
				callback = [[[infoDict objectForKey:@"denyCB"] retain] autorelease];
				break;
			case AIAuthorizationNoResponse:
				callback = nil;
				break;
		}
		
		//libpurple will remove its reference to the handle for this request, which is inWindowController, in response to this callback invocation
		if (callback) {
			[purpleAdapter doAuthRequestCbValue:callback withUserDataValue:[[[infoDict objectForKey:@"userData"] retain] autorelease]];

			/* Retained in -[self authorizationRequestWithDict:].  We kept it around before now in case libpurle wanted us to close it early, such as because the
			 * account disconnected.
			 */
			[inWindowController autorelease];
		} else {
			[purpleAdapter closeAuthRequestWithHandle:inWindowController];
			
		}
	}
}

//Chats ------------------------------------------------------------
#pragma mark Chats

- (void)updateUserListForChat:(AIChat *)chat
{
	PurpleConversation *conv = [[chat identifier] pointerValue];
	if (conv) {
		GList *l;
		GList *users = purple_conv_chat_get_users(purple_conversation_get_chat_data(conv));
		NSMutableArray *usersArray = [NSMutableArray array];
		NSMutableArray *flagsArray = [NSMutableArray array];
		NSMutableArray *aliasesArray = [NSMutableArray array];
		
		for (l = users; l; l = l->next) {
			PurpleConvChatBuddy *cb = (PurpleConvChatBuddy *)l->data;
			const char *name = purple_conv_chat_cb_get_name(cb);
			const char *alias = cb->alias;
			PurpleConvChatBuddyFlags flags = cb->flags;
			
			[usersArray addObject:[NSString stringWithUTF8String:name]];
			[flagsArray addObject:[NSNumber numberWithInt:flags]];
			[aliasesArray addObject:(alias ? [NSString stringWithUTF8String:alias] : @"")];
		}
		AILogWithSignature(@"Adding %@ back to chat", usersArray);
		[self addUsersArray:usersArray
				  withFlags:flagsArray
				 andAliases:aliasesArray
				newArrivals:[NSNumber numberWithBool:NO]
					 toChat:chat];
	}	
}

/*!
 * @brief Called by Purple code when a chat should be opened by the interface
 *
 * If the user sent an initial message, this will be triggered and have no effect.
 *
 * If a remote user sent an initial message, however, a chat will be created without being opened.  This call is our
 * cue to actually open chat.
 *
 * Another situation in which this is relevant is when we request joining a group chat; the chat should only be actually
 * opened once the server notifies us that we are in the room.
 *
 * This will ultimately call -[CBPurpleAccount openChat:] below if the chat was not previously open.
 */
- (void)addChat:(AIChat *)chat
{
	AILogWithSignature(@"");

	//Open the chat
	if ([chat isOpen]) {
		[self displayYouHaveConnectedInChat:chat];
		
		if ([chat isGroupChat]) {
			[self performSelector:@selector(updateUserListForChat:)
					   withObject:chat
					   afterDelay:0];
		}
	}

	[[adium interfaceController] openChat:chat];
	
	[chat accountDidJoinChat];
}

//Open a chat for Adium
- (BOOL)openChat:(AIChat *)chat
{
	/* The #if 0'd block below causes crashes in msn_tooltip_text() on MSN */
#if 0
	AIListContact	*listContact;
	
	//Obtain the contact's information if it's a stranger
	if ((listContact = [chat listObject]) && ([listContact isStranger])) {
		[self delayedUpdateContactStatus:listContact];
	}
#endif
	
	AILog(@"purple openChat:%@ for %@",chat,[chat uniqueChatID]);

	//Inform purple that we have opened this chat
	[purpleAdapter openChat:chat onAccount:self];
	
	//Created the chat successfully
	return YES;
}

- (BOOL)closeChat:(AIChat*)chat
{
	[purpleAdapter closeChat:chat];
	
	//Be sure any remaining typing flag is cleared as the chat closes
	[self setTypingFlagOfChat:chat to:nil];
	AILog(@"purple closeChat:%@",[chat uniqueChatID]);
	
    return YES;
}

- (void)chatWasDestroyed:(AIChat *)chat
{
	[[adium chatController] accountDidCloseChat:chat];
}

- (void)chatJoinDidFail:(AIChat *)chat
{
	[[adium chatController] accountDidCloseChat:chat];
}

/* 
 * @brief Rejoin a chat
 */
- (BOOL)rejoinChat:(AIChat *)chat
{
	[chat retain];

	PurpleConversation *conv = [[chat identifier] pointerValue];
	if (conv && conv->ui_data) {
		[(AIChat *)(conv->ui_data) release];
		conv->ui_data = NULL;
	}

	/* The identifier is how we associate a PurpleConversation with an AIChat.
	 * Clear the identifier so a new PurpleConversation will be made. The ChatCreationInfo for the chat is still around, so it can join.
	 */
	[chat setIdentifier:nil];
	[purpleAdapter openChat:chat onAccount:self];

	[chat autorelease];

	//We don't get any immediate feedback as to our success; just return YES.
	return YES;
}

/*!
 * @brief A chat will be joined
 *
 * This gives the account a chance to update any information in the chat's creation dictionary if desired.
 *
 * @result The final chat creation dictionary to use.
 */
- (NSDictionary *)willJoinChatUsingDictionary:(NSDictionary *)chatCreationDictionary
{
	return chatCreationDictionary;
}

- (BOOL)chatCreationDictionary:(NSDictionary *)chatCreationDict isEqualToDictionary:(NSDictionary *)baseDict
{
	return [chatCreationDict isEqualToDictionary:baseDict];
}

- (AIChat *)chatWithContact:(AIListContact *)contact identifier:(id)identifier
{
	AIChat *chat = [[adium chatController] chatWithContact:contact];
	[chat setIdentifier:identifier];

	return chat;
}


- (AIChat *)chatWithName:(NSString *)name identifier:(id)identifier
{
	return [[adium chatController] chatWithName:name identifier:identifier onAccount:self chatCreationInfo:nil];
}

//Typing update in an IM
- (void)typingUpdateForIMChat:(AIChat *)chat typing:(NSNumber *)typingState
{
	[self setTypingFlagOfChat:chat
						   to:typingState];
}

//Multiuser chat update
- (void)convUpdateForChat:(AIChat *)chat type:(NSNumber *)type
{

}

/*!
 * @brief Called when we are informed that we left a multiuser chat
 */
- (void)leftChat:(AIChat *)chat
{
	AILogWithSignature(@"Chat left - something should happen here!");
}

- (void)updateTopic:(NSString *)inTopic forChat:(AIChat *)chat
{
	
}
- (void)updateTitle:(NSString *)inTitle forChat:(AIChat *)chat
{
	[[chat displayArrayForKey:@"Display Name"] setObject:inTitle
											   withOwner:self];
}

- (void)updateForChat:(AIChat *)chat type:(NSNumber *)type
{
	AIChatUpdateType	updateType = [type intValue];
	NSString			*key = nil;
	switch (updateType) {
		case AIChatTimedOut:
		case AIChatClosedWindow:
			break;
	}
	
	if (key) {
		[chat setValue:[NSNumber numberWithBool:YES] forProperty:key notify:NotifyNow];
		[chat setValue:nil forProperty:key notify:NotifyNever];
		
	}
}

- (void)errorForChat:(AIChat *)chat type:(NSNumber *)type
{
	[chat receivedError:type];
}

- (void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{
	PurpleMessageFlags		flags = [[messageDict objectForKey:@"PurpleMessageFlags"] intValue];
	
	if ((flags & PURPLE_MESSAGE_SEND) != 0) {
        //Purple is telling us that our message was sent successfully.

		//We would tell the other side that we're done typing, except that if we do this now, the typing notification icon in some clients (e.g., iChat) disappears before the message actually arrives.
		//[purpleAdapter sendTyping:AINotTyping inChat:chat];
    } else {
		NSAttributedString		*attributedMessage;
		AIListContact			*listContact;
		
		listContact = [chat listObject];

		attributedMessage = [[adium contentController] decodedIncomingMessage:[messageDict objectForKey:@"Message"]
																  fromContact:listContact
																	onAccount:self];
		
		//Clear the typing flag of the chat since a message was just received
		[self setTypingFlagOfChat:chat to:nil];
		
		[self _receivedMessage:attributedMessage
						inChat:chat 
			   fromListContact:listContact
						 flags:flags
						  date:[messageDict objectForKey:@"Date"]];
	}
}

- (void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat
{	
	PurpleMessageFlags	flags = [[messageDict objectForKey:@"PurpleMessageFlags"] intValue];
	NSAttributedString	*attributedMessage = [messageDict objectForKey:@"AttributedMessage"];;
	NSString			*source = [messageDict objectForKey:@"Source"];

	if (source) {
		[self _receivedMessage:attributedMessage
						inChat:chat 
			   fromListContact:[self contactWithUID:source]
						 flags:flags
						  date:[messageDict objectForKey:@"Date"]];
	} else {
		//If we didn't get a listContact, this is a purple status message... display it as such.
		[[adium contentController] displayEvent:[attributedMessage string]
										 ofType:@"purple"
										 inChat:chat];
		
	}
}

- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(PurpleMessageFlags)flags date:(NSDate *)date
{
	AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
														   withSource:sourceContact
														  destination:self
																 date:date
															  message:attributedMessage
															autoreply:(flags & PURPLE_MESSAGE_AUTO_RESP) != 0];
	
	[[adium contentController] receiveContentObject:messageObject];
}

/*********************/
/* AIAccount_Content */
/*********************/
#pragma mark Content
- (void)sendTypingObject:(AIContentTyping *)inContentTyping
{
	AIChat *chat = [inContentTyping chat];

	if (![chat isGroupChat]) {
		[purpleAdapter sendTyping:[inContentTyping typingState] inChat:chat];
	}
}

- (BOOL)supportsSendingNotifications
{
	return (account ? ((PURPLE_PLUGIN_PROTOCOL_INFO(purple_find_prpl(purple_account_get_protocol_id(account)))->send_attention) != NULL) : NO);
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	PurpleMessageFlags		flags = PURPLE_MESSAGE_RAW;
	
	if ([inContentMessage isKindOfClass:[AIContentNotification class]] &&
		[self supportsSendingNotifications]) {
		//Send a notification directly if possible
		[purpleAdapter sendNotificationOfType:[(AIContentNotification *)inContentMessage notificationType]
								 fromAccount:self
									  inChat:[inContentMessage chat]];

	} else {
		if ([inContentMessage isAutoreply]) {
			flags |= PURPLE_MESSAGE_AUTO_RESP;
		}

		[purpleAdapter sendEncodedMessage:[inContentMessage encodedMessage]
							 fromAccount:self
								  inChat:[inContentMessage chat]
							   withFlags:flags];
	}
	
	return YES;
}

/*!
 * @brief Return the string encoded for sending to a remote contact
 *
 * We return nil if the string turns out to have been a / command.
 */
- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	BOOL		didCommand = [purpleAdapter attemptPurpleCommandOnMessage:[[inContentMessage message] string]
														 fromAccount:(AIAccount *)[inContentMessage source]
															  inChat:[inContentMessage chat]];	
	
	return (didCommand ? nil : [super encodedAttributedStringForSendingContentMessage:inContentMessage]);
}

/*!
 * @brief Libpurple prints file transfer messages to the chat window. The Adium core therefore shouldn't.
 */
- (BOOL)accountDisplaysFileTransferMessages
{
	return YES;
}

/*!
 * @brief Available for sending content
 *
 * Returns YES if the contact is available for receiving content of the specified type.  If contact is nil, instead
 * check for the availiability to send any content of the given type.
 *
 * We override the default implementation to check -[self allowFileTransferWithListObject:] for file transfers
 *
 * @param inType A string content type
 * @param inContact The destination contact, or nil to check global availability
 */
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
    if ([self online] && [inType isEqualToString:CONTENT_FILE_TRANSFER_TYPE]) {
		if (inContact) {
			return ([self conformsToProtocol:@protocol(AIAccount_Files)] &&
					(([inContact online] || [inContact isStranger]) && [self allowFileTransferWithListObject:inContact]));
		} else {
			return [self conformsToProtocol:@protocol(AIAccount_Files)];
		}
	}

    return [super availableForSendingContentType:inType toContact:inContact];
}

- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	PurplePluginProtocolInfo *prpl_info = NULL;

	if (account && purple_account_get_connection(account) && purple_account_get_connection(account)->prpl)
		prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(purple_account_get_connection(account)->prpl);
	
	if (prpl_info && prpl_info->send_file)
		return (!prpl_info->can_receive_file || prpl_info->can_receive_file(purple_account_get_connection(account), [[inListObject UID] UTF8String]));
	else
		return NO;
}

- (BOOL)supportsAutoReplies
{
	if (account && purple_account_get_connection(account)) {
		return ((purple_account_get_connection(account)->flags & PURPLE_CONNECTION_AUTO_RESP) != 0);
	}
	
	return NO;
}

- (BOOL)canSendOfflineMessageToContact:(AIListContact *)inContact
{
	PurplePluginProtocolInfo *prpl_info = NULL;

	if (account && purple_account_get_connection(account) && purple_account_get_connection(account)->prpl)
		prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(purple_account_get_connection(account)->prpl);
	
	if (prpl_info && prpl_info->offline_message) {
		
		return (prpl_info->offline_message(purple_find_buddy(account, [[inContact UID] UTF8String])));

	} else
		return NO;
	
}

#pragma mark Custom emoticons
- (void)chat:(AIChat *)inChat isWaitingOnCustomEmoticon:(NSString *)emoticonEquivalent
{
	if(![[[adium preferenceController] preferenceForKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
												  group:PREF_GROUP_MSN_SERVICE] boolValue])
		return;
	AIEmoticon *emoticon;

	//Look for an existing emoticon with this equivalent
	NSEnumerator *enumerator = [[inChat customEmoticons] objectEnumerator];
	while ((emoticon = [enumerator nextObject])) {
		if ([[emoticon textEquivalents] containsObject:emoticonEquivalent]) break;
	}
	
	if (!emoticon) {
		emoticon = [AIEmoticon emoticonWithIconPath:nil
										equivalents:[NSArray arrayWithObject:emoticonEquivalent]
											   name:emoticonEquivalent
											   pack:nil];
		[inChat addCustomEmoticon:emoticon];			
	}
	
	if (![emoticon path]) {
		[emoticon setPath:[[NSBundle bundleForClass:[CBPurpleAccount class]] pathForResource:@"missing_image"
																					ofType:@"png"]];
	}
}

/*!
 * @brief Return the path at which to save an emoticon
 */
- (NSString *)_emoticonCachePathForEmoticon:(NSString *)emoticonEquivalent type:(AIBitmapImageFileType)fileType inChat:(AIChat *)inChat
{
	static unsigned long long emoticonID = 0;
    NSString    *filename = [NSString stringWithFormat:@"TEMP-CustomEmoticon_%@_%@_%qu.%@",
		[inChat uniqueChatID], emoticonEquivalent, emoticonID++, [NSImage extensionForBitmapImageFileType:fileType]];
    return [[adium cachesPath] stringByAppendingPathComponent:[filename safeFilenameString]];	
}


- (void)chat:(AIChat *)inChat setCustomEmoticon:(NSString *)emoticonEquivalent withImageData:(NSData *)inImageData
{
	if(![[[adium preferenceController] preferenceForKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
												  group:PREF_GROUP_MSN_SERVICE] boolValue])
		return;
	/* XXX Note: If we can set outgoing emoticons, this method needs to be updated to mark emoticons as incoming
	 * and AIEmoticonController needs to be able to handle that.
	 */
	AIEmoticon	*emoticon;

	//Look for an existing emoticon with this equivalent
	NSEnumerator *enumerator = [[inChat customEmoticons] objectEnumerator];
	while ((emoticon = [enumerator nextObject])) {
		if ([[emoticon textEquivalents] containsObject:emoticonEquivalent]) break;
	}
	
	//Write out our image
	NSString	*path = [self _emoticonCachePathForEmoticon:emoticonEquivalent
													   type:[NSImage fileTypeOfData:inImageData]
													 inChat:inChat];
	[inImageData writeToFile:path
				  atomically:NO];

	if (emoticon) {
		//If we already have an emoticon, just update its path
		[emoticon setPath:path];

	} else {
		emoticon = [AIEmoticon emoticonWithIconPath:path
										equivalents:[NSArray arrayWithObject:emoticonEquivalent]
											   name:emoticonEquivalent
											   pack:nil];
		[inChat addCustomEmoticon:emoticon];
	}
}

- (void)chat:(AIChat *)inChat closedCustomEmoticon:(NSString *)emoticonEquivalent
{
	if(![[[adium preferenceController] preferenceForKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
												  group:PREF_GROUP_MSN_SERVICE] boolValue])
		return;
	AIEmoticon	*emoticon;

	//Look for an existing emoticon with this equivalent
	NSEnumerator *enumerator = [[inChat customEmoticons] objectEnumerator];
	while ((emoticon = [enumerator nextObject])) {
		if ([[emoticon textEquivalents] containsObject:emoticonEquivalent]) break;
	}
	
	if (emoticon) {
		[[adium notificationCenter] postNotificationName:@"AICustomEmoticonUpdated"
												  object:inChat
												userInfo:[NSDictionary dictionaryWithObject:emoticon
																					 forKey:@"AIEmoticon"]];
	} else {
		//This shouldn't happen; chat:setCustomEmoticon:withImageData: should have already been called.
		emoticon = [AIEmoticon emoticonWithIconPath:nil
										equivalents:[NSArray arrayWithObject:emoticonEquivalent]
											   name:emoticonEquivalent
											   pack:nil];
		NSLog(@"Warning: closed custom emoticon %@ without adding it to the chat", emoticon);
		AILog(@"Warning: closed custom emoticon %@ without adding it to the chat", emoticon);
	}
}

#pragma mark PurpleConversation User Lists
- (NSString *)uidForContactWithUID:(NSString *)inUID inChat:(AIChat *)chat
{
	//No change for the superclass; subclasses may wish to modify it
	return inUID;
}
- (void)addUsersArray:(NSArray *)usersArray
			withFlags:(NSArray *)flagsArray
		   andAliases:(NSArray *)aliasesArray 
		  newArrivals:(NSNumber *)newArrivals
			   toChat:(AIChat *)chat
{
	int			i, count;
	BOOL		isNewArrival = (newArrivals && [newArrivals boolValue]);

	AILog(@"*** %@: addUsersArray:%@ toChat:%@",self,usersArray,chat);

	count = [usersArray count];
	for (i = 0; i < count; i++) {
		NSString				*contactName;
		NSString				*alias;
		AIListContact			*listContact;
		PurpleConvChatBuddyFlags	flags;

		contactName = [usersArray objectAtIndex:i];
		flags = [[flagsArray objectAtIndex:i] intValue];
		alias = [aliasesArray objectAtIndex:i];

		listContact = [self contactWithUID:[self uidForContactWithUID:contactName inChat:chat]];
		[listContact setFormattedUID:contactName notify:NotifyNow];

		if (alias && [alias length] && ![alias isEqualToString:contactName]) {
			[listContact setServersideAlias:alias asStatusMessage:NO silently:YES];
		}

		[chat addParticipatingListObject:listContact notify:isNewArrival];
	}
}

- (void)renameRoomOccupant:(NSString *)contactName to:(NSString *)newName inChat:(AIChat *)chat
{
	AIListContact	*occupant = (AIListContact *)[chat objectWithService:[[chat account] service]
																	 UID:contactName];

	[occupant setFormattedUID:newName notify:NotifyLater];
}

- (void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat
{
	AIListContact	*contact;

	if ((chat) && 
		(contact = [self contactWithUID:[self uidForContactWithUID:contactName inChat:chat]])) {
		
		[chat removeObject:contact];
		
		AILog(@"%@ removeUser:%@ fromChat:%@",self,contact,chat);
	} else {
		AILog(@"Could not remove %@ from %@ (contactWithUID: %@)",
			  contactName,chat,[self contactWithUID:[self uidForContactWithUID:contactName inChat:chat]]);
	}
}

- (void)removeUsersArray:(NSArray *)usersArray fromChat:(AIChat *)chat
{
	NSEnumerator	*enumerator = [usersArray objectEnumerator];
	NSString		*contactName;
	while ((contactName = [enumerator nextObject])) {
		[self removeUser:contactName fromChat:chat];
	}
}

/*********************/
/* AIAccount_Privacy */
/*********************/
#pragma mark Privacy
- (BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(AIPrivacyType)type
{
    if (type == AIPrivacyTypePermit)
        return (purple_privacy_permit_add(account,[[inObject UID] UTF8String],FALSE));
    else
        return (purple_privacy_deny_add(account,[[inObject UID] UTF8String],FALSE));
}

- (BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(AIPrivacyType)type
{
    if (type == AIPrivacyTypePermit)
        return (purple_privacy_permit_remove(account,[[inObject UID] UTF8String],FALSE));
    else
        return (purple_privacy_deny_remove(account,[[inObject UID] UTF8String],FALSE));
}

- (NSArray *)listObjectsOnPrivacyList:(AIPrivacyType)type
{
	NSMutableArray	*array = [NSMutableArray array];
	if (account) {
		GSList			*list;
		GSList			*sourceList = ((type == AIPrivacyTypePermit) ? account->permit : account->deny);
		
		for (list = sourceList; (list != NULL); list=list->next) {
			[array addObject:[self contactWithUID:[NSString stringWithUTF8String:(char *)list->data]]];
		}
	}

	return array;
}

- (void)accountPrivacyList:(AIPrivacyType)type added:(NSString *)sourceUID
{
	//Can't really trust sourceUID to not be @"" or something silly like that
	if ([sourceUID length]) {
		//Get our contact
		AIListContact   *contact = [self contactWithUID:sourceUID];

		//Update Adium's knowledge of it
		[contact setIsBlocked:((type == AIPrivacyTypeDeny) ? YES : NO) updateList:NO];
	}
}

- (void)privacyPermitListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypePermit added:sourceUID];
}

- (void)privacyDenyListAdded:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypeDeny added:sourceUID];
}

- (void)accountPrivacyList:(AIPrivacyType)type removed:(NSString *)sourceUID
{
	//Can't really trust sourceUID to not be @"" or something silly like that
	if ([sourceUID length]) {
		if (!namesAreCaseSensitive) {
			sourceUID = [sourceUID compactedString];
		}

		//Get our contact, which must already exist for us to care about its removal
		AIListContact   *contact = [[adium contactController] existingContactWithService:service
																				 account:self
																					 UID:sourceUID];
		
		if (contact) {			
			//Update Adium's knowledge of it
			[contact setIsBlocked:((type == AIPrivacyTypeDeny) ? NO : YES) updateList:NO];
		}
	}
}

- (void)privacyPermitListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypePermit removed:sourceUID];
}

- (void)privacyDenyListRemoved:(NSString *)sourceUID
{
	[self accountPrivacyList:AIPrivacyTypeDeny removed:sourceUID];
}

- (void)setPrivacyOptions:(AIPrivacyOption)option
{
	if (account && purple_account_get_connection(account)) {
		PurplePrivacyType privacyType;

		switch (option) {
			case AIPrivacyOptionAllowAll:
			default:
				privacyType = PURPLE_PRIVACY_ALLOW_ALL;
				break;
			case AIPrivacyOptionDenyAll:
				privacyType = PURPLE_PRIVACY_DENY_ALL;
				break;
			case AIPrivacyOptionAllowUsers:
				privacyType = PURPLE_PRIVACY_ALLOW_USERS;
				break;
			case AIPrivacyOptionDenyUsers:
				privacyType = PURPLE_PRIVACY_DENY_USERS;
				break;
			case AIPrivacyOptionAllowContactList:
				privacyType = PURPLE_PRIVACY_ALLOW_BUDDYLIST;
				break;
			
		}
		
		if (account->perm_deny != privacyType) {
			account->perm_deny = privacyType;
			serv_set_permit_deny(purple_account_get_connection(account));
			AILog(@"Set privacy options for %@ (%x %x) to %i",
				  self,account,purple_account_get_connection(account),account->perm_deny);

			[self setPreference:[NSNumber numberWithInt:option]
						 forKey:KEY_PRIVACY_OPTION
						  group:GROUP_ACCOUNT_STATUS];			
		}
	} else {
		AILog(@"Couldn't set privacy options for %@ (%x %x)",self,account,purple_account_get_connection(account));
	}
}

- (AIPrivacyOption)privacyOptions
{
	AIPrivacyOption privacyOption = -1;
	
	if (account) {
		PurplePrivacyType privacyType = account->perm_deny;
		
		switch (privacyType) {
			case PURPLE_PRIVACY_ALLOW_ALL:
			default:
				privacyOption = AIPrivacyOptionAllowAll;
				break;
			case PURPLE_PRIVACY_DENY_ALL:
				privacyOption = AIPrivacyOptionDenyAll;
				break;
			case PURPLE_PRIVACY_ALLOW_USERS:
				privacyOption = AIPrivacyOptionAllowUsers;
				break;
			case PURPLE_PRIVACY_DENY_USERS:
				privacyOption = AIPrivacyOptionDenyUsers;
				break;
			case PURPLE_PRIVACY_ALLOW_BUDDYLIST:
				privacyOption = AIPrivacyOptionAllowContactList;
				break;
		}
	}
	AILog(@"%@: privacyOptions are %i",self,privacyOption);
	return privacyOption;
}

/*****************************************************/
/* File transfer / AIAccount_Files inherited methods */
/*****************************************************/
#pragma mark File Transfer
- (BOOL)canSendFolders
{
	return NO;
}

//Create a protocol-specific xfer object, set it up as requested, and begin sending
- (void)_beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	PurpleXfer *xfer = [self newOutgoingXferForFileTransfer:fileTransfer];
	
	if (xfer) {
		//Associate the fileTransfer and the xfer with each other
		[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
		xfer->ui_data = [fileTransfer retain];
		
		//Set the filename
		purple_xfer_set_local_filename(xfer, [[fileTransfer localFilename] UTF8String]);
		purple_xfer_set_filename(xfer, [[[fileTransfer localFilename] lastPathComponent] UTF8String]);
		
		/*
		 Request that the transfer begins.
		 We will be asked to accept it via:
			- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
		 below.
		 */
		[purpleAdapter xferRequest:xfer];
		[fileTransfer setStatus: Waiting_on_Remote_User_FileTransfer];
	}
}
//By default, protocols can not create PurpleXfer objects
- (PurpleXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	PurpleXfer				*newPurpleXfer = NULL;

	if (account && purple_account_get_connection(account)) {
		PurplePlugin				*prpl;
		PurplePluginProtocolInfo  *prpl_info = ((prpl = purple_find_prpl(purple_account_get_protocol_id(account))) ?
												PURPLE_PLUGIN_PROTOCOL_INFO(prpl) :
												NULL);

		if (prpl_info && prpl_info->new_xfer) {
			char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
			newPurpleXfer = (prpl_info->new_xfer)(purple_account_get_connection(account), destsn);
		}
	}

	return newPurpleXfer;
}

/* 
 * @brief The account requested that we received a file.
 *
 * Set up the ESFileTransfer and query the fileTransferController for a save location.
 * 
 */
- (void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	AILog(@"File transfer request received: %@",fileTransfer);
	[[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

//Create an ESFileTransfer object from an xfer
- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID
										 size:(unsigned long long)inSize
							   remoteFilename:(NSString *)remoteFilename
{
	AIListContact   *contact = [self contactWithUID:destinationUID];
    ESFileTransfer	*fileTransfer;
	
	fileTransfer = [[adium fileTransferController] newFileTransferWithContact:contact
																   forAccount:self
																		 type:Unknown_FileTransfer]; 
	[fileTransfer setSize:inSize];
	[fileTransfer setRemoteFilename:remoteFilename];
	
    return fileTransfer;
}

//Update an ESFileTransfer object progress
- (void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	float percentDone = [percent floatValue];
    [fileTransfer setPercentDone:percentDone bytesSent:[bytesSent unsignedLongValue]];
}

//The local side cancelled the transfer.  We probably already have this status set, but set it just in case.
- (void)fileTransferCancelledLocally:(ESFileTransfer *)fileTransfer
{
	if (![fileTransfer isStopped]) {
		[fileTransfer setStatus:Cancelled_Local_FileTransfer];
	}
}

//The remote side cancelled the transfer, the fool. Update our status.
- (void)fileTransferCancelledRemotely:(ESFileTransfer *)fileTransfer
{
	if (![fileTransfer isStopped]) {
		[fileTransfer setStatus:Cancelled_Remote_FileTransfer];
	}
}

- (void)destroyFileTransfer:(ESFileTransfer *)fileTransfer
{
	AILog(@"Destroy file transfer %@",fileTransfer);
	[fileTransfer release];
}

//Accept a send or receive ESFileTransfer object, beginning the transfer.
//Subsequently inform the fileTransferController that the fun has begun.
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    AILog(@"Accepted file transfer %@",fileTransfer);
	
	PurpleXfer		*xfer;
	PurpleXferType	xferType;
	
	xfer = [[fileTransfer accountData] pointerValue];

    xferType = purple_xfer_get_type(xfer);
    if (xferType == PURPLE_XFER_SEND) {
        [fileTransfer setFileTransferType:Outgoing_FileTransfer];

    } else if (xferType == PURPLE_XFER_RECEIVE) {
        [fileTransfer setFileTransferType:Incoming_FileTransfer];
		[fileTransfer setSize:purple_xfer_get_size(xfer)];
    }
    
    //accept the request
	[purpleAdapter xferRequestAccepted:xfer withFileName:[fileTransfer localFilename]];
	
	[fileTransfer setStatus:Accepted_FileTransfer];
}

//User refused a receive request.  Tell purple; we don't release the ESFileTransfer object
//since that will happen when the xfer is destroyed.  This will end up calling back on
//- (void)fileTransfercancelledLocally:(ESFileTransfer *)fileTransfer
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
	PurpleXfer	*xfer = [[fileTransfer accountData] pointerValue];
	if (xfer) {
		[purpleAdapter xferRequestRejected:xfer];
	}
}

//Cancel a file transfer in progress.  Tell purple; we don't release the ESFileTransfer object
//since that will happen when the xfer is destroyed.  This will end up calling back on
//- (void)fileTransfercancelledLocally:(ESFileTransfer *)fileTransfer
- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	PurpleXfer	*xfer = [[fileTransfer accountData] pointerValue];
	if (xfer) {
		[purpleAdapter xferCancel:xfer];
	}	
}

//Account Connectivity -------------------------------------------------------------------------------------------------
#pragma mark Connect
//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
	finishedConnectProcess = NO;

	[super connect];

	//Ensure we have a purple account if one does not already exist
	[self purpleAccount];
	
	//Make sure our settings are correct
	if ([self connectivityBasedOnNetworkReachability] &&
		![[self host] length]) {
		//If we use the network for connectivity, and we don't have a host, we need to get ourselves one. Prompt for it!
		[self promptForHostBeforeConnecting];
	} else {
		[self configurePurpleAccountNotifyingTarget:self selector:@selector(continueConnectWithConfiguredPurpleAccount)];
	}
}

- (void)unregister
{
	finishedConnectProcess = NO;

	[purpleAdapter unregisterAccount:self];
}

static void prompt_host_cancel_cb(CBPurpleAccount *self) {
	[self disconnect];
}


static void prompt_host_ok_cb(CBPurpleAccount *self, const char *host) {
	if(host && *host) {
		[self setPreference:[NSString stringWithUTF8String:host]
					 forKey:KEY_CONNECT_HOST
					  group:GROUP_ACCOUNT_STATUS];	

		[self configurePurpleAccountNotifyingTarget:self selector:@selector(continueConnectWithConfiguredPurpleAccount)];
	} else {
		prompt_host_cancel_cb(self);
	}
}

- (void)promptForHostBeforeConnecting
{
	purple_request_input(NULL, [[NSString stringWithFormat:AILocalizedString(@"%@ (%@) Setup", "first %@ is an account name; second is a service. This is a title for a window"),
								[self formattedUID], [[self service] shortDescription]] UTF8String],
						 [AILocalizedString(@"No Server Specified", nil) UTF8String],
						 [[NSString stringWithFormat:AILocalizedString(@"No server has been configured for the %@ account %@. Please enter one below to connect", nil),
						   [[self service] longDescription], [self formattedUID]] UTF8String],
						 /* default value */ "", /* multiline */ FALSE, /* masked */ FALSE, /* hint */ NULL,
						 [AILocalizedString(@"Connect", "Button title to connect; this is a verb") UTF8String], G_CALLBACK(prompt_host_ok_cb),
						 [AILocalizedString(@"Cancel", nil) UTF8String], G_CALLBACK(prompt_host_cancel_cb),
						 /* account */ NULL, /* who */ NULL, /* conv */ NULL,
						 self);
						 
}


- (void)continueConnectWithConfiguredPurpleAccount
{
	//Configure libpurple's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxyNotifyingTarget:self selector:@selector(continueConnectWithConfiguredProxy)];
}

- (void)continueConnectWithConfiguredProxy
{
	//Set password and connect
	purple_account_set_password(account, [password UTF8String]);

	//Set our current status state after filtering its statusMessage as appropriate. This will take us online in the process.
	AIStatus	*statusState = [self valueForProperty:@"StatusState"];
	if (!statusState || ([statusState statusType] == AIOfflineStatusType)) {
		statusState = [[adium statusController] defaultInitialStatusState];
	}

	AILog(@"Adium: Connect: %@ initiating connection using status state %@ (%@).",[self UID],statusState,
			  [statusState statusMessageString]);

	[self autoRefreshingOutgoingContentForStatusKey:@"StatusState"
										   selector:@selector(gotFilteredStatusMessage:forStatusState:)
											context:statusState];
}

//Make sure our settings are correct; notify target/selector when we're finished
- (void)configurePurpleAccountNotifyingTarget:(id)target selector:(SEL)selector
{
	NSInvocation	*contextInvocation;
	
	//Perform the synchronous configuration activities (subclasses may want to take action in this function)
	[self configurePurpleAccount];
	
	contextInvocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	
	[contextInvocation setTarget:target];
	[contextInvocation setSelector:selector];
	[contextInvocation retainArguments];

	//Set the text profile BEFORE beginning the connect process, to avoid problems with setting it while the
	//connect occurs. Once that's done, contextInvocation will be invoked, continuing the configurePurpleAccount process.
	[self autoRefreshingOutgoingContentForStatusKey:@"TextProfile" 
										   selector:@selector(setAccountProfileTo:configurePurpleAccountContext:)
											context:contextInvocation];
}

/*!
 * @brief The server name to be passed to libpurple
 * By default, this is the host as seen by the rest of Adium.  Subclasses may choose to override this if
 * some trickery is desired between what is told to libpurple and what the rest of Adium sees.
 */
- (NSString *)hostForPurple
{
	return [self host];
}

//Synchronous purple account configuration activites, always performed after an account is created.
//This is a definite subclassing point so prpls can apply their own account settings.
- (void)configurePurpleAccount
{
	NSString	*hostName;
	int			portNumber;

	//Host (server)
	hostName = [self hostForPurple];
	if (hostName && [hostName length]) {
		purple_account_set_string(account, "server", [hostName UTF8String]);
	}
	
	//Port
	portNumber = [self port];
	if (portNumber) {
		purple_account_set_int(account, "port", portNumber);
	}
	
	//E-mail checking
	purple_account_set_check_mail(account, [[self shouldCheckMail] boolValue]);
	
	//Update a few properties before we begin connecting.  Libpurple will send these automatically
    [self updateStatusForKey:KEY_USER_ICON];
}

/*!
 * @brief Configure libpurple's proxy settings using the current system values
 *
 * target/selector are used rather than a hardcoded callback (or getProxyConfigurationNotifyingTarget: directly) because this allows code reuse
 * between the connect and register processes, which are similar in their need for proxy configuration
 */
- (void)configureAccountProxyNotifyingTarget:(id)target selector:(SEL)selector
{
	NSInvocation		*invocation; 

	//Configure the invocation we will use when we are done configuring
	invocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[invocation setSelector:selector];
	[invocation setTarget:target];
	
	[self getProxyConfigurationNotifyingTarget:self
									  selector:@selector(retrievedProxyConfiguration:context:)
									   context:invocation];
}

/*!
 * @brief Callback for -[self getProxyConfigurationNotifyingTarget:selector:context:]
 */
- (void)retrievedProxyConfiguration:(NSDictionary *)proxyConfig context:(NSInvocation *)invocation
{
	PurpleProxyInfo		*proxy_info;
	
	AdiumProxyType  	proxyType = [[proxyConfig objectForKey:@"AdiumProxyType"] intValue];
	
	proxy_info = purple_proxy_info_new();
	purple_account_set_proxy_info(account, proxy_info);

	PurpleProxyType		purpleAccountProxyType;
	
	switch (proxyType) {
		case Adium_Proxy_HTTP:
		case Adium_Proxy_Default_HTTP:
			purpleAccountProxyType = PURPLE_PROXY_HTTP;
			break;
		case Adium_Proxy_SOCKS4:
		case Adium_Proxy_Default_SOCKS4:
			purpleAccountProxyType = PURPLE_PROXY_SOCKS4;
			break;
		case Adium_Proxy_SOCKS5:
		case Adium_Proxy_Default_SOCKS5:
			purpleAccountProxyType = PURPLE_PROXY_SOCKS5;
			break;
		case Adium_Proxy_None:
		default:
			purpleAccountProxyType = PURPLE_PROXY_NONE;
			break;
	}
	
	purple_proxy_info_set_type(proxy_info, purpleAccountProxyType);

	if (proxyType != Adium_Proxy_None) {
		purple_proxy_info_set_host(proxy_info, (char *)[[proxyConfig objectForKey:@"Host"] UTF8String]);
		purple_proxy_info_set_port(proxy_info, [[proxyConfig objectForKey:@"Port"] intValue]);

		purple_proxy_info_set_username(proxy_info, (char *)[[proxyConfig objectForKey:@"Username"] UTF8String]);
		purple_proxy_info_set_password(proxy_info, (char *)[[proxyConfig objectForKey:@"Password"] UTF8String]);
		
		AILog(@"Connecting with proxy type %i and proxy host %@",proxyType, [proxyConfig objectForKey:@"Host"]);
	}

	[invocation invoke];
}

//Sublcasses should override to provide a string for each progress step
- (NSString *)connectionStringForStep:(int)step { return nil; };

/*!
 * @brief Should the account's status be updated as soon as it is connected?
 *
 * If YES, the StatusState and IdleSince properties will be told to update as soon as the account connects.
 * This will allow the account to send its status information to the server upon connecting.
 *
 * If this information is already known by the account at the time it connects and further prompting to send it is
 * not desired, return NO.
 *
 * libpurple should already have been told of our status before connecting began.
 */
- (BOOL)updateStatusImmediatelyAfterConnecting
{
	return NO;
}

- (void)didConnect
{
	finishedConnectProcess = YES;

	[super didConnect];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(iTunesDidUpdate:)
									   name:Adium_iTunesTrackChangedNotification
									 object:nil];
	
	//Silence updates
	[self silenceAllContactUpdatesForInterval:18.0];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];
	
	//Clear any previous disconnection error
	[self setLastDisconnectionError:nil];

	if (unregisterAfterConnecting)
		[self unregister];
}

//Our account has connected
- (void)accountConnectionConnected
{
	AILog(@"************ %@ CONNECTED ***********",[self UID]);
	[self didConnect];
}

- (void)accountConnectionProgressStep:(NSNumber *)step percentDone:(NSNumber *)connectionProgressPrecent
{
	NSString	*connectionProgressString = [self connectionStringForStep:[step intValue]];

	[self setValue:connectionProgressString forProperty:@"ConnectionProgressString" notify:NO];
	[self setValue:connectionProgressPrecent forProperty:@"ConnectionProgressPercent" notify:NO];	

	//Apply any changes
	[self notifyOfChangedPropertiesSilently:NO];
	
	AILog(@"************ %@ --step-- %i",[self UID],[step intValue]);
}

/*!
 * @brief Name to use when creating a PurpleAccount for this CBPurpleAccount
 *
 * By default, we just use the formattedUID.  Subclasses can override this to provide other handling,
 * such as appending @mac.com if necessary for dotMac accounts.
 */
- (const char *)purpleAccountName
{
	return [[self formattedUID] UTF8String];
}

- (void)setPurpleAccount:(PurpleAccount *)inAccount
{
	account = inAccount;
}

- (void)createNewPurpleAccount
{
	//Ensure libpurple is loaded and initialized
	[self purpleAdapter];
	
	//If loading libpurple didn't set an account for us, tell it to create one
	if (!account)
		[[self purpleAdapter] addAdiumAccount:self];

	//-[SLPurpleCocoaAdapter addAdiumAccount:] should have immediately called back on setPurpleAccount. It's bad if it didn't.
	if (account) {
		AILog(@"Created PurpleAccount 0x%x with UID %@ and protocolPlugin %s", account, [self UID], [self protocolPlugin]);
	} else {
		AILog(@"Unable to create Libpurple account with name %s and protocol plugin %s",
			  [self purpleAccountName], [self protocolPlugin]);
		NSLog(@"Unable to create Libpurple account with name %s and protocol plugin %s",
			  [self purpleAccountName], [self protocolPlugin]);
	}
}

#pragma mark Disconnect

/*!
 * @brief Disconnect this account
 */
- (void)disconnect
{
	if ([self online] || [self integerValueForProperty:@"Connecting"]) {
		//As per AIAccount's documentation, call super's implementation
		[super disconnect];

		[[adium contactController] delayListObjectNotificationsUntilInactivity];

		//Tell libpurple to disconnect
		[purpleAdapter disconnectAccount:self];
	}
}

- (void)setLastDisconnectionReason:(PurpleConnectionError)reason
{
	lastDisconnectionReason = reason;
}

- (PurpleConnectionError)lastDisconnectionReason
{
	return lastDisconnectionReason;
}

/*!
 * @brief Our account was unexpectedly disconnected with an error message
 */
- (void)accountConnectionReportDisconnect:(NSString *)text withReason:(PurpleConnectionError)reason
{
	[self setLastDisconnectionError:text];
	[self setLastDisconnectionReason:reason];

	if (reason == PURPLE_CONNECTION_ERROR_AUTHENTICATION_FAILED)
		[self serverReportedInvalidPassword];

	//We are disconnecting
    [self setValue:[NSNumber numberWithBool:YES] forProperty:@"Disconnecting" notify:NotifyNow];
	
	AILog(@"%@ accountConnectionReportDisconnect: %@",self,lastDisconnectionError);
}

- (void)accountConnectionNotice:(NSString *)connectionNotice
{
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"%@ (%@) : Connection Notice",nil),[self formattedUID],[service description]]
                                    withDescription:connectionNotice];
}

- (void)didDisconnect
{
	//Clear properties which don't make sense for a disconnected account
	[self setValue:nil forProperty:@"TextProfile" notify:NO];
	
	//Apply any changes
	[self notifyOfChangedPropertiesSilently:NO];
	
	[[adium notificationCenter] removeObserver:self
										  name:Adium_iTunesTrackChangedNotification
										object:nil];
	[tuneinfo release];
	tuneinfo = nil;
	
	if (deletePurpleAccountAfterDisconnecting) {
		deletePurpleAccountAfterDisconnecting = FALSE;

		[[self purpleAdapter] removeAdiumAccount:self];
	}

	[super didDisconnect];
}
/*!
 * @brief Our account has disconnected
 *
 * This is called after the account disconnects for any reason
 */
- (void)accountConnectionDisconnected
{
	//Report that we disconnected
	AILog(@"%@: Telling the core we disconnected", self);
	[self didDisconnect];
}

- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	AIReconnectDelayType reconnectDelayType;

	if ([self lastDisconnectionReason] == PURPLE_CONNECTION_ERROR_AUTHENTICATION_FAILED) {
		[self setLastDisconnectionError:AILocalizedString(@"Incorrect username or password","Error message displayed when the server reports username or password as being incorrect.")];
		reconnectDelayType = AIReconnectImmediately;

	} else if ([self lastDisconnectionReason] == PURPLE_CONNECTION_ERROR_INVALID_USERNAME) {
		[self setLastDisconnectionError:AILocalizedString(@"The name you entered is not registered. Check to ensure you typed it correctly.", nil)];
		reconnectDelayType = AIReconnectNever;

	} else if (disconnectionError && ([*disconnectionError isEqualToString:[NSString stringWithUTF8String:_("SSL Handshake Failed")]] ||
									  [*disconnectionError isEqualToString:[NSString stringWithUTF8String:_("SSL Connection Failed")]])) {
		/* This particular message comes with PURPLE_CONNECTION_ERROR_ENCRYPTION_ERROR, which is a 'fatal' error according to libpurple. Other problems
		 * with that message may be fatal, but this one isn't.
		 */
		reconnectDelayType = AIReconnectNormally;

	} else if (purple_connection_error_is_fatal([self lastDisconnectionReason])) {
		reconnectDelayType = AIReconnectNever;

	} else {
		reconnectDelayType = AIReconnectNormally;
	}

	return reconnectDelayType;
}

#pragma mark Registering
- (void)performRegisterWithPassword:(NSString *)inPassword
{
	//Save the new password
	if (password != inPassword) {
		[password release]; password = [inPassword retain];
	}

	//Ensure we have a purple account if one does not already exist
	[self purpleAccount];
	
	//We are connecting
	[self setValue:[NSNumber numberWithBool:YES] forProperty:@"Connecting" notify:NotifyNow];
	
	//Make sure our settings are correct
	[self configurePurpleAccountNotifyingTarget:self selector:@selector(continueRegisterWithConfiguredPurpleAccount)];
}

- (void)continueRegisterWithConfiguredProxy
{
	//Set password and connect
	purple_account_set_password(account, [password UTF8String]);
	
	AILog(@"Adium: Register: %@ initiating connection.",[self UID]);
	
	[purpleAdapter registerAccount:self];
}

- (void)continueRegisterWithConfiguredPurpleAccount
{
	//Configure libpurple's proxy settings; continueConnectWithConfiguredProxy will be called once we are ready
	[self configureAccountProxyNotifyingTarget:self selector:@selector(continueRegisterWithConfiguredProxy)];
}

- (void)purpleAccountRegistered:(BOOL)success
{
	if (success && [[self service] accountViewController]) {
		NSString *username = (purple_account_get_username(account) ? [NSString stringWithUTF8String:purple_account_get_username(account)] : [NSNull null]);
		NSString *pw = (purple_account_get_password(account) ? [NSString stringWithUTF8String:purple_account_get_password(account)] : [NSNull null]);

		[[adium notificationCenter] postNotificationName:AIAccountUsernameAndPasswordRegisteredNotification
												  object:self
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													username, @"username",
													pw, @"password",
													nil]];
	}
}

//Account Status ------------------------------------------------------------------------------------------------------
#pragma mark Account Status
//Properties this account supports
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"IdleSince",
			@"IdleManuallySet",
			@"TextProfile",
			@"DefaultUserIconFilename",
			KEY_ACCOUNT_CHECK_MAIL,
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
		
	}

	return supportedPropertyKeys;
}

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	[super updateStatusForKey:key];
	
    //Now look at keys which only make sense if we have an account
	if (account) {
		AILog(@"%@: Updating status for key: %@",self, key);

		if ([key isEqualToString:@"IdleSince"]) {
			NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			[self setAccountIdleSinceTo:idleSince];
							
		} else if ([key isEqualToString:@"TextProfile"]) {
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(setAccountProfileTo:)];
			
		} else if ([key isEqualToString:KEY_USER_ICON]) {
			NSData  *data = [self userIconData];

			[self setAccountUserImageData:data];

		} else if ([key isEqualToString:KEY_ACCOUNT_CHECK_MAIL]) {
			//Update the mail checking setting if the account is already made (if it isn't, we'll set it when it is made)
			if (account) {
				[purpleAdapter setCheckMail:[self shouldCheckMail]
							  forAccount:self];
			}
		}
	}
}

/*!
 * @brief Return the purple status type to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the purple status ID
 * @param arguments Prpl-specific arguments which will be passed with the state. Message is handled automatically.
 *
 * @result The purple status ID
 */
- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	char	*statusID = NULL;
	
	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			statusID = "available";
			break;
		case AIAwayStatusType:
			statusID = "away";
			break;
			
		case AIInvisibleStatusType:
			statusID = "invisible";
			break;
			
		case AIOfflineStatusType:
			statusID = "offline";
			break;
	}
	
	return statusID;
}

- (BOOL)shouldAddMusicalNoteToNowPlayingStatus
{
	return YES;
}

- (BOOL)shouldSetITMSLinkForNowPlayingStatus
{
	return NO;
}

- (BOOL)shouldIncludeNowPlayingInformationInAllStatuses
{
	return NO;
}

- (NSDictionary *)purpleSongInfoDictionary
{
	NSMutableDictionary *arguments = [NSMutableDictionary dictionary];

	if ([self shouldIncludeNowPlayingInformationInAllStatuses]) {
		if (tuneinfo && [[tuneinfo objectForKey:ITUNES_PLAYER_STATE] isEqualToString:@"Playing"]) {
			NSString *artist = [tuneinfo objectForKey:ITUNES_ARTIST];
			NSString *name = [tuneinfo objectForKey:ITUNES_NAME];
			
			[arguments setObject:(artist ? artist : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ARTIST]];
			[arguments setObject:(name ? name : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TITLE]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_ALBUM] ? [tuneinfo objectForKey:ITUNES_ALBUM] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ALBUM]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_GENRE] ? [tuneinfo objectForKey:ITUNES_GENRE] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_GENRE]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_TOTAL_TIME] ? [tuneinfo objectForKey:ITUNES_TOTAL_TIME]:[NSNumber numberWithInt:-1]) forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TIME]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_YEAR] ? [tuneinfo objectForKey:ITUNES_YEAR]:[NSNumber numberWithInt:-1]) forKey:[NSString stringWithUTF8String:PURPLE_TUNE_YEAR]];
			[arguments setObject:([tuneinfo objectForKey:ITUNES_STORE_URL] ? [tuneinfo objectForKey:ITUNES_STORE_URL] : @"") forKey:[NSString stringWithUTF8String:PURPLE_TUNE_URL]];
			
			[arguments setObject:[NSString stringWithFormat:@"%@%@%@", (name ? name : @""), (name && artist ? @" - " : @""), (artist ? artist : @"")]
						  forKey:[NSString stringWithUTF8String:PURPLE_TUNE_FULL]];
			
		} else {
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ARTIST]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TITLE]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_ALBUM]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_GENRE]];
			[arguments setObject:[NSNumber numberWithInt:-1] forKey:[NSString stringWithUTF8String:PURPLE_TUNE_TIME]];
			[arguments setObject:[NSNumber numberWithInt:-1] forKey:[NSString stringWithUTF8String:PURPLE_TUNE_YEAR]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_URL]];
			[arguments setObject:@"" forKey:[NSString stringWithUTF8String:PURPLE_TUNE_FULL]];
		}
	}

	return arguments;
}

- (void)iTunesDidUpdate:(NSNotification*)notification {
	if ([self shouldIncludeNowPlayingInformationInAllStatuses]) {
		[tuneinfo release];
		tuneinfo = [[notification object] retain];

		[purpleAdapter setSongInformation:[self purpleSongInfoDictionary] onAccount:self];
	}
}

/*!
 * @brief Perform the setting of a status state
 *
 * Sets the account to a passed status state.  The account should set itself to best possible status given the return
 * values of statusState's accessors.  The passed statusMessage has been filtered; it should be used rather than
 * [statusState statusMessage], which returns an unfiltered statusMessage.
 *
 * @param statusState The state to enter
 * @param statusMessage The filtered status message to use.
 */
- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	NSString			*encodedStatusMessage;
	NSMutableDictionary	*arguments = [[NSMutableDictionary alloc] init];

	//Get the purple status type from this class or subclasses, which may also potentially modify or nullify our statusMessage
	const char *statusID = [self purpleStatusIDForStatus:statusState
											 arguments:arguments];

	if (![statusMessage length] &&
		([statusState statusType] == AIAwayStatusType) &&
		[statusState statusName] &&
		(!statusID || (strcmp(statusID, "away") == 0))) {
		/* If we don't have a status message, and the status type is away for a non-default away such as "Do Not Disturb", and we're only setting
		 * a default away state becuse we don't know a better one for this service, get a default
		 * description of this away state. This allows, for example, an AIM user to set the "Do Not Disturb" type provided by her ICQ account
		 * and have the away message be set appropriately.
		 */
		statusMessage = [NSAttributedString stringWithString:[[adium statusController] descriptionForStateOfStatus:statusState]];
	}

	BOOL isNowPlayingStatus = ([statusState specialStatusType] == AINowPlayingSpecialStatusType);
	if (isNowPlayingStatus && [statusMessage length]) {
		if ([self shouldAddMusicalNoteToNowPlayingStatus]) {
#define MUSICAL_NOTE_AND_SPACE [NSString stringWithUTF8String:"\xe2\x99\xab "]
			NSMutableAttributedString *temporaryStatusMessage;
			temporaryStatusMessage = [[[NSMutableAttributedString alloc] initWithString:MUSICAL_NOTE_AND_SPACE] autorelease];
			[temporaryStatusMessage appendAttributedString:statusMessage];
			
			statusMessage = temporaryStatusMessage;
		}
		
		if ([self shouldSetITMSLinkForNowPlayingStatus]) {
			//Grab the message's subtext, which is the song link if we're using the Current iTunes Track status
			NSString *itmsStoreLink	= [statusMessage attribute:@"AIMessageSubtext" atIndex:0 effectiveRange:NULL];
			if (itmsStoreLink) {
				[arguments setObject:itmsStoreLink
							  forKey:@"itmsurl"];
			}
		}
	}

	//Encode the status message if we have one
	encodedStatusMessage = (statusMessage ? 
							[self encodedAttributedString:statusMessage
										   forStatusState:statusState]  :
							nil);
	if (encodedStatusMessage) {
		[arguments setObject:encodedStatusMessage
					  forKey:@"message"];
	}

	[self setStatusState:statusState
				statusID:statusID
				isActive:[NSNumber numberWithBool:YES] /* We're only using exclusive states for now... I hope.  */
			   arguments:arguments];
	
	[arguments release];
}

/*!
 * @brief Perform the actual setting of a state
 *
 * This is called by setStatusState.  It allows subclasses to perform any other behaviors, such as modifying a display
 * name, which are called for by the setting of the state; most of the processing has already been done, however, so
 * most subclasses will not need to implement this.
 *
 * @param statusState The AIStatus which is being set
 * @param statusID The Purple-sepcific statusID we are setting
 * @param isActive An NSNumber with a bool YES if we are activating (going to) the passed state, NO if we are deactivating (going away from) the passed state.
 * @param arguments Purple-specific arguments specified by the account. It must contain only NSString objects and keys.
 */
- (void)setStatusState:(AIStatus *)statusState statusID:(const char *)statusID isActive:(NSNumber *)isActive arguments:(NSMutableDictionary *)arguments
{
	[purpleAdapter setStatusID:statusID
				   isActive:isActive
				  arguments:arguments
				  onAccount:self];
}

//Set our idle (Pass nil for no idle)
- (void)setAccountIdleSinceTo:(NSDate *)idleSince
{
	[purpleAdapter setIdleSinceTo:idleSince onAccount:self];
	
	//We now should update our idle property
	[self setValue:([idleSince timeIntervalSinceNow] ? idleSince : nil)
				   forProperty:@"IdleSince"
				   notify:NotifyNow];
}

//Set the profile, then invoke the passed invocation to return control to the target/selector specified
//by a configurePurpleAccountNotifyingTarget:selector: call.
- (void)setAccountProfileTo:(NSAttributedString *)profile configurePurpleAccountContext:(NSInvocation *)inInvocation
{
	[self setAccountProfileTo:profile];
	
	[inInvocation invoke];
}

//Set our profile immediately on the purpleAdapter
- (void)setAccountProfileTo:(NSAttributedString *)profile
{
	if (!profile || ![[profile string] isEqualToString:[[self valueForProperty:@"TextProfile"] string]]) {
		NSString 	*profileHTML = nil;
		
		//Convert the profile to HTML, and pass it to libpurple
		if (profile) {
			profileHTML = [self encodedAttributedString:profile forListObject:nil];
		}
		
		[purpleAdapter setInfo:profileHTML onAccount:self];
		
		//We now have a profile
		[self setValue:profile forProperty:@"TextProfile" notify:NotifyNow];
	}
}

/*!
 * @brief Set our user image
 *
 * Pass nil for no image. This resizes and converts the image as needed for our protocol.
 * After setting it with purple, it sets it within Adium; if this is not called, the image will
 * show up neither locally nor remotely.
 */
- (void)setAccountUserImageData:(NSData *)originalData
{
	NSImage	*image =  (originalData ? [[[NSImage alloc] initWithData:originalData] autorelease] : nil);

	if (account) {
		NSSize		imageSize = (image ? [image size] : NSZeroSize);
		NSData		*buddyIconData = nil;

		/* Now pass libpurple the new icon. Check to be sure our image doesn't have an NSZeroSize size,
		 * which would indicate currupt data */
		if (image && !NSEqualSizes(NSZeroSize, imageSize)) {
			PurplePlugin				*prpl;
			PurplePluginProtocolInfo  *prpl_info = ((prpl = purple_find_prpl(purple_account_get_protocol_id(account))) ?
												  PURPLE_PLUGIN_PROTOCOL_INFO(prpl) :
												  NULL);

			AILog(@"Original image of size %f %f",imageSize.width,imageSize.height);

			if (prpl_info && (prpl_info->icon_spec.format)) {
				BOOL		smallEnough, prplScales;
				unsigned	i;
				
				/* We need to scale it down if:
				 *	1) The prpl needs to scale before it sends to the server or other buddies AND
				 *	2) The image is larger than the maximum size allowed by the protocol
				 * We ignore the minimum required size, as scaling up just leads to pixellated images.
				 */
				smallEnough =  (prpl_info->icon_spec.max_width >= imageSize.width &&
								prpl_info->icon_spec.max_height >= imageSize.height);
					
				prplScales = (prpl_info->icon_spec.scale_rules & PURPLE_ICON_SCALE_SEND) || (prpl_info->icon_spec.scale_rules & PURPLE_ICON_SCALE_DISPLAY);

				if (prplScales && !smallEnough) {
					int width = imageSize.width;
					int height = imageSize.height;
					
					purple_buddy_icon_get_scale_size(&prpl_info->icon_spec, &width, &height);
					//Determine the scaled size.  If it's too big, scale to the largest permissable size
					image = [image imageByScalingToSize:NSMakeSize(width, height)];

					/* Our original data is no longer valid, since we had to scale to a different size */
					originalData = nil;
					AILog(@"%@: Scaled image to size %@", self, NSStringFromSize([image size]));
				}

				if (!buddyIconData) {
					char		**prpl_formats =  g_strsplit(prpl_info->icon_spec.format,",",0);

					//Look for gif first if the image is animated
					NSImageRep	*imageRep = [image bestRepresentationForDevice:nil] ;
					if ([imageRep isKindOfClass:[NSBitmapImageRep class]] &&
						[[(NSBitmapImageRep *)imageRep valueForProperty:NSImageFrameCount] intValue] > 1) {
						
						for (i = 0; prpl_formats[i]; i++) {
							if (strcmp(prpl_formats[i],"gif") == 0) {
								/* Try to use our original data.  If we had to scale, originalData will have been set
								* to nil and we'll continue below to convert the image. */
								AILog(@"l33t script kiddie animated GIF!!111");
								
								buddyIconData = originalData;
								if (buddyIconData)
									break;
							}
						}
					}
					
					if (!buddyIconData) {
						for (i = 0; prpl_formats[i]; i++) {
							if (strcmp(prpl_formats[i],"png") == 0) {
								buddyIconData = [image PNGRepresentation];
								if (buddyIconData)
									break;
								
							} else if ((strcmp(prpl_formats[i],"jpeg") == 0) || (strcmp(prpl_formats[i],"jpg") == 0)) {								
								buddyIconData = [image JPEGRepresentationWithCompressionFactor:1.0];
								if (buddyIconData)
									break;
								
							} else if ((strcmp(prpl_formats[i],"tiff") == 0) || (strcmp(prpl_formats[i],"tif") == 0)) {
								buddyIconData = [image TIFFRepresentation];
								if (buddyIconData)
									break;
								
							} else if (strcmp(prpl_formats[i],"gif") == 0) {
								buddyIconData = [image GIFRepresentation];
								if (buddyIconData)
									break;
								
							} else if (strcmp(prpl_formats[i],"bmp") == 0) {
								buddyIconData = [image BMPRepresentation];
								if (buddyIconData)
									break;
								
							}						
						}
						
						size_t maxSize = prpl_info->icon_spec.max_filesize;
						if (maxSize > 0 && ([buddyIconData length] > maxSize)) {
							AILog(@"Image %i is larger than %i!",[buddyIconData length],maxSize);
							for (i = 0; prpl_formats[i]; i++) {
								if ((strcmp(prpl_formats[i],"jpeg") == 0) || (strcmp(prpl_formats[i],"jpg") == 0)) {
									float compressionFactor;
									for (compressionFactor = 0.99; compressionFactor > 0.4; compressionFactor -= 0.01) {
										buddyIconData = [image JPEGRepresentationWithCompressionFactor:compressionFactor];
										
										if (buddyIconData && ([buddyIconData length] <= maxSize)) {
											AILog(@"Succeeded getting it down to %i with compressionFactor %f",[buddyIconData length],compressionFactor);
											break;
										}
									}
								}
							}
						}
					}	
					//Cleanup
					g_strfreev(prpl_formats);
				}
			}
		}

		AILogWithSignature(@"%@ setting icon data of length %i", self, [buddyIconData length]);
		[purpleAdapter setBuddyIcon:buddyIconData onAccount:self];
	}
	
	//We now have an icon
	[self setValue:image forProperty:KEY_USER_ICON notify:NotifyNow];
}

#pragma mark Group Chat
- (BOOL)inviteContact:(AIListContact *)inContact toChat:(AIChat *)inChat withMessage:(NSString *)inviteMessage
{
	[purpleAdapter inviteContact:inContact toChat:inChat withMessage:inviteMessage];
	
	return YES;
}

#pragma mark Buddy Menu Items
//Action of a dynamically-generated contact menu item
- (void)performContactMenuAction:(NSMenuItem *)sender
{
	NSDictionary		*dict = [sender representedObject];
	
	[purpleAdapter performContactMenuActionFromDict:dict forAccount:self];
}

/*!
 * @brief Utility method when generating buddy-specific menu items
 *
 * Adds the menu item for act to a growing array of NSMenuItems.  If act has children (a submenu), this method is used recursively
 * to generate the submenu containing each child menu item.
 */
- (void)addMenuItemForMenuAction:(PurpleMenuAction *)act forListContact:(AIListContact *)inContact purpleBuddy:(PurpleBuddy *)buddy toArray:(NSMutableArray *)menuItemArray withServiceIcon:(NSImage *)serviceIcon
{
	NSDictionary	*dict;
	NSMenuItem		*menuItem;
	NSString		*title;
				
	//If titleForContactMenuLabel:forContact: returns nil, we don't add the menuItem
	if (act &&
		act->label &&
		(title = [self titleForContactMenuLabel:act->label
									 forContact:inContact])) { 
		menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																		target:self
																		action:@selector(performContactMenuAction:)
																 keyEquivalent:@""];
		[menuItem setImage:serviceIcon];

		if (act->data) {
			dict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:act->callback],@"PurpleMenuActionCallback",
				/* act->data may be freed by purple_menu_action_free() before we use it, I'm afraid... */
				[NSValue valueWithPointer:act->data],@"PurpleMenuActionData",
				[NSValue valueWithPointer:buddy],@"PurpleBuddy",
				nil];
		} else {
			dict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithPointer:act->callback],@"PurpleMenuActionCallback",
				[NSValue valueWithPointer:buddy],@"PurpleBuddy",
				nil];			
		}
		
		[menuItem setRepresentedObject:dict];
		
		//If there is a submenu, generate and set it
		if (act->children) {
			NSMutableArray	*childrenArray = [NSMutableArray array];
			GList			*l, *ll;
			//Add a NSMenuItem for each child
			for (l = ll = act->children; l; l = l->next) {
				[self addMenuItemForMenuAction:(PurpleMenuAction *)l->data
								forListContact:inContact
									 purpleBuddy:buddy
									   toArray:childrenArray
							   withServiceIcon:serviceIcon];
			}
			g_list_free(act->children);

			if ([childrenArray count]) {
				NSEnumerator *enumerator = [childrenArray objectEnumerator];
				NSMenuItem	 *childMenuItem;
				NSMenu		 *submenu = [[NSMenu alloc] init];
				
				while ((childMenuItem = [enumerator nextObject])) {
					[submenu addItem:childMenuItem];
				}
				
				[menuItem setSubmenu:submenu];
				[submenu release];
			}
		}

		[menuItemArray addObject:menuItem];
		[menuItem release];
	}

	purple_menu_action_free(act);
}

//Returns an array of menuItems specific for this contact based on its account and potentially status
- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
	NSMutableArray			*menuItemArray = nil;

	if (account && purple_account_is_connected(account)) {
		PurplePlugin				*prpl;
		PurplePluginProtocolInfo  *prpl_info = ((prpl = purple_find_prpl(purple_account_get_protocol_id(account))) ?
											  PURPLE_PLUGIN_PROTOCOL_INFO(prpl) :
											  NULL);
		GList					*l, *ll;
		PurpleBuddy				*buddy;
		
		//Find the PurpleBuddy
		buddy = purple_find_buddy(account, [[inContact UID] UTF8String]);
		
		if (prpl_info && prpl_info->blist_node_menu && buddy) {
			NSImage	*serviceIcon = [AIServiceIcons serviceIconForService:[self service]
																	type:AIServiceIconSmall
															   direction:AIIconNormal];
			
			menuItemArray = [NSMutableArray array];

			//Add a NSMenuItem for each node action specified by the prpl
			for (l = ll = prpl_info->blist_node_menu((PurpleBlistNode *)buddy); l; l = l->next) {
				[self addMenuItemForMenuAction:(PurpleMenuAction *)l->data
								forListContact:inContact
									 purpleBuddy:buddy
									   toArray:menuItemArray
							   withServiceIcon:serviceIcon];
			}
			g_list_free(ll);
			
			//Don't return an empty array
			if (![menuItemArray count]) menuItemArray = nil;
		}
	}
	
	return menuItemArray;
}

//Subclasses may override to provide a localized label and/or prevent a specified label from being shown
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	return [NSString stringWithUTF8String:label];
}

/*!
* @brief Menu items for the account's actions
 *
 * Returns an array of menu items for account-specific actions.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.  It will only be queried if the account is online.
 * @return NSArray of NSMenuItem instances for this account
 */
- (NSArray *)accountActionMenuItems
{
	NSMutableArray			*menuItemArray = nil;
	
	if (account && purple_account_is_connected(account)) {
		PurplePlugin *plugin = purple_account_get_connection(account)->prpl;
		
		if (PURPLE_PLUGIN_HAS_ACTIONS(plugin)) {
			GList	*l, *actions;
			
			actions = PURPLE_PLUGIN_ACTIONS(plugin, purple_account_get_connection(account));

			//Avoid adding separators between nonexistant items (i.e. items which Purple shows but we don't)
			BOOL	addedAnAction = NO;
			for (l = actions; l; l = l->next) {
				
				if (l->data) {
					PurplePluginAction	*action;
					NSDictionary		*dict;
					NSMenuItem			*menuItem;
					NSString			*title;
					
					action = (PurplePluginAction *) l->data;
					
					//If titleForAccountActionMenuLabel: returns nil, we don't add the menuItem
					if (action &&
						action->label &&
						(title = [self titleForAccountActionMenuLabel:action->label])) {

						action->plugin = plugin;
						action->context = purple_account_get_connection(account);

						menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																						 target:self
																						 action:@selector(performAccountMenuAction:)
																				  keyEquivalent:@""] autorelease];
						dict = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSValue valueWithPointer:action->callback], @"PurplePluginActionCallback",
							[NSValue valueWithPointer:action->user_data], @"PurplePluginActionCallbackUserData",
							nil];
						
						[menuItem setRepresentedObject:dict];
						
						if (!menuItemArray) menuItemArray = [NSMutableArray array];
						
						[menuItemArray addObject:menuItem];
						addedAnAction = YES;
					} 
					
					purple_plugin_action_free(action);
					
				} else {
					if (addedAnAction) {
						[menuItemArray addObject:[NSMenuItem separatorItem]];
						addedAnAction = NO;
					}
				}
			} /* end for */
			
			g_list_free(actions);
		}
	}

	return menuItemArray;
}

//Action of a dynamically-generated contact menu item
- (void)performAccountMenuAction:(NSMenuItem *)sender
{
	NSDictionary		*dict = [sender representedObject];

	[purpleAdapter performAccountMenuActionFromDict:dict forAccount:self];
}

//Subclasses may override to provide a localized label and/or prevent a specified label from being shown
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if ((strcmp(label, _("Change Password...")) == 0) || (strcmp(label, _("Change Password")) == 0)) {
		return [[NSString stringWithFormat:AILocalizedString(@"Change Password", "Menu item title for changing the password of an account")] stringByAppendingEllipsis];
	} else {
		return [NSString stringWithUTF8String:label];
	}
}

/********************************/
/* AIAccount subclassed methods */
/********************************/
#pragma mark AIAccount Subclassed Methods
- (void)initAccount
{
	NSDictionary	*defaults = [NSDictionary dictionaryNamed:[NSString stringWithFormat:@"PurpleDefaults%@",[[self service] serviceID]]
													 forClass:[self class]];
	
	if (defaults) {
		[[adium preferenceController] registerDefaults:defaults
											  forGroup:GROUP_ACCOUNT_STATUS
												object:self];
	} else {
		AILog(@"Failed to load defaults for %@",[NSString stringWithFormat:@"PurpleDefaults%@",[[self service] serviceID]]);
	}
	
	//Defaults
	[self setLastDisconnectionError:nil];
	
	permittedContactsArray = [[NSMutableArray alloc] init];
	deniedContactsArray = [[NSMutableArray alloc] init];

	//We will create a purpleAccount the first time we attempt to connect
	account = NULL;

	//Observe preferences changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_ALIASES];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

- (BOOL)allowAccountUnregistrationIfSupportedByLibpurple
{
	return YES;
}

/*!
 * @brief The account will be deleted, we should ask the user for confirmation. If the prpl supports it, we can also remove
 * the account from the server (if the user wants us to do that)
 */
- (NSAlert*)alertForAccountDeletion
{
	PurplePlugin *prpl;
	PurplePluginProtocolInfo *prpl_info;

	//Ensure libpurple has been loaded, since we need to know whether we can unregister this account
	[self purpleAdapter];

	if ((prpl = purple_find_prpl([self protocolPlugin])) &&
		(prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(prpl)) &&
		(prpl_info->unregister_user) &&
		[self allowAccountUnregistrationIfSupportedByLibpurple]) {
		return [NSAlert alertWithMessageText:AILocalizedString(@"Delete Account",nil)
							   defaultButton:AILocalizedString(@"Delete",nil)
							 alternateButton:AILocalizedString(@"Cancel",nil)
								 otherButton:AILocalizedString(@"Delete & Unregister",nil)
				   informativeTextWithFormat:AILocalizedString(@"Delete the account %@? You can also optionally unregister the account on the server if possible.",nil), ([[self formattedUID] length] ? [self formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT)];		

	} else {
		return [super alertForAccountDeletion];
	}
}

- (void)alertForAccountDeletion:(id<AIAccountControllerRemoveConfirmationDialog>)dialog didReturn:(int)returnCode
{
	PurplePlugin *prpl;
	PurplePluginProtocolInfo *prpl_info;
	
	if ((prpl = purple_find_prpl([self protocolPlugin])) &&
		(prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(prpl)) &&
		(prpl_info->unregister_user)) {
		switch (returnCode) {
			case NSAlertOtherReturn:
				// delete & unregister
				if ([self online])
					[self unregister];
				else {
					unregisterAfterConnecting = YES;
					[self setShouldBeOnline:YES];
				}
			
				// further progress happens in -unregisteredAccount:
				break;
			case NSAlertDefaultReturn:
				// delete without unregistering
				[self performDelete];
				break;
			default:
				// cancel
				break;
		}
		
	} else {
		switch(returnCode) {
			case NSAlertDefaultReturn:
				[self performDelete];
				break;
			default:
				// cancel
				break;
		}
	}
	
	//Release dialog as required by AIAccount's documentation since we didn't call super's implementation.
	[dialog release];
}

- (void)unregisteredAccount:(BOOL)success {
	if (success) {
		/* We're not going to be online, but we *must* not disconnect within this run loop,
		 * as libpurple may still have Things To Do with the connection and it has no concept of reference
		 * counting with which to survive the disconnection. Performing a deletion would set us offline,
		 * so wait until the next run loop.
		 */
		[self performSelector:@selector(performDelete)
				   withObject:nil
				   afterDelay:0];
	}
}

/*!
 * @brief The account's UID changed
 */
- (void)didChangeUID
{
	//Only need to take action if we have a created PurpleAccount already
	if (account != NULL) {
		//Remove our current account
		[[self purpleAdapter] removeAdiumAccount:self];
		
		//Clear the reference to the PurpleAccount... it'll be created when needed
		account = NULL;
	}
}

/*!
 * @brief The account will be deleted; it has already been told to disconnect
 */
- (void)willBeDeleted
{	
	if ([self online]) {
		//Wait until we are finished disconnecting before removing ourselves from libpurple.
		deletePurpleAccountAfterDisconnecting = TRUE;

	} else {
		[[self purpleAdapter] removeAdiumAccount:self];
	}

	[super willBeDeleted];
}

- (void)dealloc
{	
	[[adium preferenceController] unregisterPreferenceObserver:self];

	[permittedContactsArray release];
	[deniedContactsArray release];
	
    [super dealloc];
}

- (NSString *)unknownGroupName {
    return (@"Unknown");
}

- (NSDictionary *)defaultProperties { return [NSDictionary dictionary]; }

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forStatusState:(AIStatus *)statusState
{
	return [self encodedAttributedString:inAttributedString forListObject:nil];	
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];

	if ([group isEqualToString:PREF_GROUP_ALIASES]) {
		//If the notification object is a listContact belonging to this account, update the serverside information
		if ((account != nil) && 
			([self shouldSetAliasesServerside]) &&
			([key isEqualToString:@"Alias"])) {

			NSString *alias = [object preferenceForKey:@"Alias"
												 group:PREF_GROUP_ALIASES 
								 ignoreInheritedValues:YES];

			if ([object isKindOfClass:[AIMetaContact class]]) {
				NSEnumerator	*enumerator = [[(AIMetaContact *)object containedObjects] objectEnumerator];
				AIListContact	*containedListContact;
				while ((containedListContact = [enumerator nextObject])) {
					if ([containedListContact account] == self) {
						[purpleAdapter setAlias:alias forUID:[containedListContact UID] onAccount:self];
					}
				}
				
			} else if ([object isKindOfClass:[AIListContact class]]) {
				if ([(AIListContact *)object account] == self) {
					[purpleAdapter setAlias:alias forUID:[object UID] onAccount:self];
				}
			}
		}
	}
	
	if ([group isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]) {
		openPsychicChats = [[prefDict objectForKey:KEY_PSYCHIC] boolValue];
	}
}

#pragma mark Actions for chats

/*!
 * @name Actions for chats
 * @brief This method returns an NSMenu containing the 
 * actions that are allowed for a given chat.
 * @params An AIChat for which the commands are fetched
 * @return NSMenu with the proper commands
 */
- (NSMenu*)actionsForChat:(AIChat*)chat
{
	NSMenu *actionsMenu = [[NSMenu alloc] initWithTitle:@"commandsmenu"];
	PurpleConversation *conv = existingConvLookupFromChat(chat);

	GList *list = purple_cmd_list(conv);
	GList *l;

	for (l = list; l != NULL; l = l->next) {
		const char  *cmdName = l->data;

		GList		*cmdDescription = purple_cmd_help(conv, cmdName);
		NSString	*name = [NSString stringWithUTF8String:cmdName];
		NSString *menuTitle;
		if (cmdDescription && cmdDescription->data)
			menuTitle = [[AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String:cmdDescription->data]] string];
		else
			menuTitle = name;

		[actionsMenu addItemWithTitle:menuTitle
							   target:self
							   action:@selector(doCommand:)
						keyEquivalent:@""
					representedObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   chat, @"associatedChat",
									   name, @"commandName",
									   nil]];
	} 

	g_list_free(list);

	return [actionsMenu autorelease]; 
}

-(void)doCommand:(id)sender
{
	NSDictionary *dict = [sender representedObject];
	[self verifyCommand:[dict objectForKey:@"commandName"]
				forChat:[dict objectForKey:@"associatedChat"]];
}

-(void)executeCommandWithParameters:(NSMutableDictionary*)parameters
{
	BOOL result = [purpleAdapter doCommand:[parameters objectForKey:@"totalCommandString"] fromAccount:self inChat:[parameters objectForKey:@"chat"]];
	if(result == FALSE)	{
#warning Incomplete
		// Either choice should be taken into account for various actions
		// or the panel should be modified to only present an OK button,
		// so there is no real choice for the user
		/* int choice = */NSRunAlertPanel(@"Command Failed!",@"command failed: %@ from Account: %@ in Chat: %@",@"Cancel",@"OK",nil,[parameters objectForKey:@"totalCommandString"],[parameters objectForKey:@"account"],[parameters objectForKey:@"chat"]); 
	}
}


- (BOOL)validateMenuItem:(NSMenuItem *)item 
{
	return YES;
}


/***************************/
/* Account private methods */
/***************************/
#pragma mark Private
- (void)setTypingFlagOfChat:(AIChat *)chat to:(NSNumber *)typingStateNumber
{
    AITypingState currentTypingState = [chat integerValueForProperty:KEY_TYPING];
	AITypingState newTypingState = [typingStateNumber intValue];
	
    if (currentTypingState != newTypingState) {
		if (newTypingState == AITyping && openPsychicChats && ![chat isOpen]) {
			[[adium interfaceController] openChat:chat];
			
			/*
			 * Use the Libpurple "psychic" tagline. If this is found to be confusing, we should switch to your own version.
			 * The upside of using theirs is that clever gimmicky translations already exist.
			 */
			NSMutableString *forceString = [[NSString stringWithUTF8String:_("You feel a disturbance in the force...")] mutableCopy];
			[forceString replaceOccurrencesOfString:@"..."
										 withString:[NSString ellipsis]
											options:NSLiteralSearch];
			AIContentStatus *statusMessage = [AIContentStatus statusInChat:chat
																withSource:[chat listObject]
															   destination:self
																	  date:[NSDate date]
																   message:[NSAttributedString stringWithString:forceString]
																  withType:@"psychic"];
			[forceString release];

			[[adium contentController] receiveContentObject:statusMessage];
		}
		
		[chat setValue:(newTypingState ? typingStateNumber : nil)
					   forProperty:KEY_TYPING
					   notify:NotifyNow];
    }
}

- (NSNumber *)shouldCheckMail
{
	return [self preferenceForKey:KEY_ACCOUNT_CHECK_MAIL group:GROUP_ACCOUNT_STATUS];
}

- (BOOL)shouldSetAliasesServerside
{
	return NO;
}


@end
