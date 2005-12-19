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

#import "AIAbstractAccount.h"
#import "AIAccount.h"
#import "AIContactController.h"
#import "AIListContact.h"

/*!
 * @class AIAccount
 * @brief An account
 *
 * This abstract class represents an account the user has setup in Adium.  Subclass this for every service.
 */
@implementation AIAccount

/*!
 * @brief Init Account
 *
 * Init this account instance
 */
- (void)initAccount
{
	
}

/*!
 * @brief Connect
 *
 * Connect the account, transitioning it into an online state.
 */
- (void)connect
{
	//We are connecting
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:NotifyNow];
}

/*!
 * @brief Disconnect
 *
 * Disconnect the account, transitioning it into an offline state.
 */
- (void)disconnect
{
	[self setStatusObject:nil forKey:@"Connecting" notify:NotifyLater];
	[self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:NotifyLater];

	[self notifyOfChangedStatusSilently:NO];
}

/*!
 * @brief Register an account
 *
 * Register an account on this service using the currently entered information.  This is for services which support
 * in-client registration such as jabber.
 */
- (void)performRegisterWithPassword:(NSString *)inPassword
{

}

/*!
 * @brief The UID will be changed. The account has a chance to perform modifications
 *
 * For example, MSN adds @hotmail.com to the proposedUID and returns the new value
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	return proposedUID;
}

/*!
 * @brief The account's UID changed
 */
- (void)didChangeUID
{

}

/*!
 * @brief The account will be deleted
 *
 * The default implementation disconnects the account.  Subclasses should call super's implementation.
 */
- (void)willBeDeleted
{
	[self setShouldBeOnline:NO];

	//Remove our contacts immediately.
	[self removeAllContacts];
}


//Properties -----------------------------------------------------------------------------------------------------------
#pragma mark Properties
/*!
 * @brief Send Autoresponses while away
 *
 * Subclass to alter the behavior of this account with regards to autoresponses.  Certain services expect the client to
 * auto-respond with away messages.  Adium will provide this behavior automatically if desired.
 */
- (BOOL)shouldSendAutoresponsesWhileAway
{
	return NO;
}

/*!
 * @brief Disconnect on fast user switch
 *
 * It may be required for a service to disconnect when logged in users change.  If this is the case, subclass this
 * method to return YES and Adium will automatically disconnect and reconnect on FUS events.
 */
- (BOOL)disconnectOnFastUserSwitch
{
	return NO;
}

/*!
 * @brief Connectivity based on network reachability
 *
 * By default, accounts are automatically disconnected and reconnected when network reachability changes.  Accounts
 * that do not require persistent network connections can choose to disable this by returning NO from this method.
 */
- (BOOL)connectivityBasedOnNetworkReachability
{
	return YES;
}

/*!
 * @brief Suppress typing notifications after send
 *
 * Some protocols require a 'Stopped typing' notification to be sent along with an instant message.  Other protocols
 * implicitly assume that typing has stopped with an incoming message and the extraneous typing notification may cause
 * strange behavior.  Return YES from this method to suppress the sending of a stopped typing notification along with
 * messages.
 */
- (BOOL)suppressTypingNotificationChangesAfterSend
{
	return NO;
}

/*!
 * @brief Support server-side storing of messages to offline users
 *
 * Some protocols store messages to offline contacts on the server. Subclasses may return YES if their service supports 
 * this. Adium will not store the message as an Event, and will just send it along to the server. This may cause a Gaim
 * error on Jabber if the Jabber server they are using is down.
 */
- (BOOL)supportsOfflineMessaging
{
	return NO;
}

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
/*!
 * @brief Supported status keys
 *
 * Returns an array of status keys supported by this account.  This account will not be informed of changes to keys
 * it does not support.  Available keys are:
 *   @"Display Name", @"Online", @"Offline", @"IdleSince", @"IdleManuallySet", @"User Icon"
 *   @"TextProfile", @"DefaultUserIconFilename", @"StatusState"
 * @return NSSet of supported keys
 */
- (NSSet *)supportedPropertyKeys
{
	static	NSSet	*supportedPropertyKeys = nil;
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSSet alloc] initWithObjects:
			@"FormattedUID",
			@"FullNameAttr",
			@"Display Name",
			@"StatusState",
			KEY_USER_ICON,
			@"Enabled",
			nil];
	}

	return supportedPropertyKeys;
}

/*!
 * @brief Status for key
 *
 * Returns the status this account should be for a specific key
 * @param key Status key
 * @return id Status value
 */
- (id)statusForKey:(NSString *)key
{
	return [self preferenceForKey:key group:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Update account status
 *
 * Update account status for the changed key.  This is called when account status changes Adium-side and the account
 * code should update status account/server side in response.  The new value for the key can be accessed using
 * the statusForKey method.
 * @param key The updated status key
 */
- (void)updateStatusForKey:(NSString *)key
{
	[self updateCommonStatusForKey:key];
}

/*!
 * @brief Update contact status
 *
 * Adium is requesting that the account update a contact's status.  This method is primarily called by the get info
 * window.  Since this is called sparsely, accounts may choose to look up additional information such as profiles
 * in response to this.  Adium guards this method to prevent it from being called too rapidly, so expensive lookups
 * are not a problem if the delayedUpdateStatusInterval is set correctly.
 */
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
	
}

/*!
 * @brief Update contact interval
 *
 * Specifies the mininum interval at which delayedUpdateContactStatus will be called.  If the account code is performing
 * expensive operations (such as profile or web lookups) in response to updateContactStatus, it can guard against
 * the lookups being performed too frequently by returning an interval here.
 */
- (float)delayedUpdateStatusInterval
{
	return 3.0;
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
	
}

//Messaging, Chatting, Strings -----------------------------------------------------------------------------------------
#pragma mark Messaging, Chatting, Strings
/*!
 * @brief Available for sending content
 *
 * Returns YES if the contact is available for receiving content of the specified type.  If contact is nil, instead
 * check for the availiability to send any content of the given type.
 * @param inType A string content type
 * @param inContact The destination contact, or nil to check global availability
 */
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
	return NO;
}

/*!
 * @brief Open a chat
 *
 * Open the passed chat account-side.  Depending on the protocol, account code may need to establish a connection in
 * response to this method or perhaps make no actions at all.  This method is used by both one-on-one chats and
 * multi-user chats.
 * @param chat The chat to open
 * @return YES on success
 */
- (BOOL)openChat:(AIChat *)chat
{
	return NO;
}

/*!
 * @brief Close a chat
 *
 * Close the passed chat account-side.  Depending on the protocol, account code may need to close a connection in
 * response to this method or perhaps make no actions at all.  This method is used by both one-on-one chats and
 * multi-user chats.
 * @param chat The chat to close
 * @return YES on success
 */
- (BOOL)closeChat:(AIChat *)chat
{
	return NO;
}

/*!
 * @brief Invite a contact to an open chat
 *
 * Invite a contact to the passed chat, if supported by the protocol and the specific chat instance.  An invite
 * message is provided as a convenience to protocols that require or support one.
 * @param contact AIListObject to invite
 * @param chat AIChat they are being invited to
 * @param inviteMessage NSString invite message for the invited contact
 * @return YES on success
 */
- (BOOL)inviteContact:(AIListObject *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage
{
	return NO;
}

/*!
 * @brief Join a group chat
 *
 * Join a group chat by name
 * @param contact AIListObject to invite
 * @param chat AIChat they are being invited to
 * @param inviteMessage NSString invite message for the invited contact
 * @return YES on success
 */
- (BOOL)joinGroupChatNamed:(NSString *)name
{
	// XXX - Do we need this method?  All chats are supposed to be treated equally and assuming a 'name' seems protocol specific -ai
	return NO;
}

/*!
 * @brief Send a content object
 *
 * Send a content object, such as a message.  The content object contains all the necessary information for sending,
 * including the destination contact.
 * @param object AIContentObject to send
 * @return YES on success
 */
- (BOOL)sendContentObject:(AIContentObject *)object
{
	return NO;
}

/*!
 * @brief Encode attributed string
 *
 * Encode an NSAttributedString into a NSString for this account.  Accounts that support formatted text or require
 * special encoding on strings should do that work here.  For example, HTML based accounts should convert the 
 * NSAttributedString to HTML appropriate for their protocol (Adium can help with this).
 * @param inAttributedString String to encode
 * @param inListObject List object associated with the string
 * @return NSString result from encoding
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
    return [inAttributedString string];
}


//Presence Tracking ----------------------------------------------------------------------------------------------------
#pragma mark Presence Tracking
/*!
 * @brief Contact list editable?
 *
 * Returns YES if the contact list is currently editable
 * @param object AIContentObject to send
 * @return YES on success
 */
- (BOOL)contactListEditable
{
	return NO;
}

/*!
 * @brief Add contacts
 *
 * Add contacts to a group on this account.  Create the group if it doesn't already exist.
 * @param objects NSArray of AIListContact objects to add
 * @param group AIListGroup destination for contacts
 */
- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group
{
	//XXX - Our behavior for duplicate contacts isn't specified here.  Should we handle that adium-side automatically? -ai
}

/*!
 * @brief Remove contacts
 *
 * Remove contacts from this account.
 * @param objects NSArray of AIListContact objects to remove
 */
- (void)removeContacts:(NSArray *)objects
{
	
}

/*!
 * @brief Remove a group
 *
 * Remove a group from this account.
 * @param group AIListGroup to remove
 */
- (void)deleteGroup:(AIListGroup *)group
{
	//XXX - Adium's current behavior is to delete all the contacts within a group, and then delete the group.  This is innefficient on protocols which support deleting groups. -ai
}

/*!
 * @brief Move contacts
 *
 * Move existing contacts to a specific group on this account.  The passed contacts should already exist somewhere on
 * this account.
 * @param objects NSArray of AIListContact objects to remove
 * @param group AIListGroup destination for contacts
 */
- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	
}

/*!
 * @brief Rename a group
 *
 * Rename a group on this account.
 * @param group AIListGroup to rename
 * @param newName NSString name for the group
 */
- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName
{
	
}

/*!
 * @brief Menu items for contact
 *
 * Returns an array of menu items for a contact on this account.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.
 * @param inContact AIListContact for menu items
 * @return NSArray of NSMenuItem instances for the passed contact
 */
- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
	return nil;
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
	return nil;
}

#pragma mark Secure messsaging

/*!
 * @brief Allow secure messaging toggling on a chat?
 *
 * Returns YES if secure (encrypted) messaging's status for this chat should be able to be changed.
 * This allows the account to determine on a per-chat basis whether the chat's initial security setting should be permanently
 * maintained.  If it returns NO, the user can not request for the chat to become encrypted or unencrypted.
 * This is currently implemented by Gaim accounts to return YES for one-on-one chats and NO for group chats to indicate
 * the functionality provided by Off-the-Record Messaging (OTR).
 *
 * @param inChat The query chat 
 * @result Should the state of secure messaging be allowed to change?
 */
- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat
{
	return NO;
}

/*!
 * @brief Provide a localized description of the encryption this account provides
 *
 * Returns a localized string which describes the encryption this account supports.
 *
 * @result An <tt>NSString</tt> describing the encryption offerred by this account, if any.
 */
- (NSString *)aboutEncryption
{
	return nil;
}

/*!
 * @brief Start or stop secure messaging in a chat
 *
 * @param inSecureMessaging The desired state of the chat in terms of encryption
 * @param inChat The chat to change
 */
- (void)requestSecureMessaging:(BOOL)inSecureMessaging
						inChat:(AIChat *)inChat
{
	
}

/*!
 * @brief Allow the user to verify (or unverify) the identity being used for encryption in a chat
 *
 * It is an error to call this on a chat which is not current encrypted.
 *
 * @param The chat
 */
- (void)promptToVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	
}

#pragma mark Image sending
- (BOOL)canSendImagesForChat:(AIChat *)inChat
{
	return NO;
}


//Display Name Convenience Methods -------------------------------------------------------------------------------------
#pragma mark Display Name Convenience Methods
- (NSImage *)userIcon
{
	NSData	*iconData = [self userIconData];
	return (iconData ? [[[NSImage alloc] initWithData:iconData] autorelease] : nil);
}


@end
