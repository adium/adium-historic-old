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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import "ESGaimMSNAccount.h"
#import <Libgaim/state.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIAccount.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#import <Libgaim/msn.h>

#define DEFAULT_MSN_PASSPORT_DOMAIN				@"@hotmail.com"
#define SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES	10

@interface ESGaimMSNAccount (PRIVATE)
- (void)updateFriendlyNameAfterConnect;
- (void)setServersideDisplayName:(NSString *)friendlyName;
@end

@implementation ESGaimMSNAccount

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
	NSString	*correctUID;
	
	if (([proposedUID length] > 0) && 
	   ([proposedUID rangeOfString:@"@"].location == NSNotFound)) {
		correctUID = [proposedUID stringByAppendingString:DEFAULT_MSN_PASSPORT_DOMAIN];
	} else {
		correctUID = proposedUID;
	}
	
	return correctUID;
}

- (void)initAccount
{
	[super initAccount];
	lastFriendlyNameChange = nil;

	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_MSN_SERVICE];
}

- (void)dealloc {
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[lastFriendlyNameChange release];
	[queuedFriendlyName release];

	[super dealloc];
}

- (const char*)protocolPlugin
{
    return "prpl-msn";
}

#pragma mark Connection
- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	BOOL HTTPConnect = [[self preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "http_method", HTTPConnect);
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 2:
			return AILocalizedString(@"Syncing with server",nil);
			break;			
		case 3:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 4:
			return AILocalizedString(@"Syncing with server",nil);
			break;
		case 5:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 6:
			return AILocalizedString(@"Password sent",nil);
			break;
		case 7:
			return AILocalizedString(@"Retrieving buddy list",nil);
			break;
			
	}
	return nil;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError && *disconnectionError) {
		if (([*disconnectionError rangeOfString:@"Type your e-mail address and password correctly"].location != NSNotFound) ||
			([*disconnectionError rangeOfString:@"Unable to authenticate"].location != NSNotFound)) {
			[self serverReportedInvalidPassword];
		} else if (([*disconnectionError rangeOfString:@"You have signed on from another location"].location != NSNotFound)) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [AIHTMLDecoder encodeHTML:inAttributedString
							 headers:NO
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:NO
						encodeSpaces:NO
						  imagesPath:nil
				   attachmentsAsText:YES
		   onlyIncludeOutgoingImages:NO
					  simpleTagsOnly:YES
					  bodyBackground:NO];
}

#pragma mark Status
//Update our full name on connect
- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];
	
	[self updateFriendlyNameAfterConnect];
}	

/*
 * @brief Update our friendly name to match the server friendly name if appropriate
 *
 * Well behaved MSN clients respect the serverside display name so that an update on one client is reflected on another.
 * 
 * If our display name is static and specified specifically for our account, we should update to the serverside one if they aren't the same.
 *
 * However, if our display name is dynamic, most likely we're looking at the filtered version of our dynamic
 * name, so we shouldn't update to the filtered one.  Furthermore, if our display name is set at the Aduim-global level,
 * we should use that name, not whatever is specified by the last client to connect.
 */
- (void)updateFriendlyNameAfterConnect
{
	const char			*displayName = gaim_connection_get_display_name(gaim_account_get_connection(account));
	NSAttributedString	*accountDisplayName = [[self preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
														   group:GROUP_ACCOUNT_STATUS
										   ignoreInheritedValues:YES] attributedString];
	NSAttributedString	*globalPreference = [[self preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
															  group:GROUP_ACCOUNT_STATUS
											  ignoreInheritedValues:NO] attributedString];
	BOOL				accountDisplayNameChanged = NO;
	BOOL				shouldUpdateDisplayNameImmediately= NO;

	/* If the friendly name changed since the last time we connected (the user changed it while offline)
	 * set it serverside and clear the flag.
	 */
	if ((accountDisplayName && (accountDisplayNameChanged = [[self preferenceForKey:KEY_MSN_DISPLAY_NAMED_CHANGED group:GROUP_ACCOUNT_STATUS] boolValue])) ||
		(!accountDisplayName && globalPreference)) {
		shouldUpdateDisplayNameImmediately = YES;

		if (accountDisplayNameChanged) {
			[self setPreference:nil
						 forKey:KEY_MSN_DISPLAY_NAMED_CHANGED
						  group:GROUP_ACCOUNT_STATUS];
		}

	} else {
		/* If our locally set friendly name didn't change since the last time we connected but one is set,
		 * we want to update to the serverside settings as appropriate.
		 *
		 * An important exception is if our per-account display name is dynamic (i.e. a 'Now Playing in iTunes' name).
		 */
		if (displayName &&
			strcmp(displayName, [[self UID] UTF8String]) &&
			strcmp(displayName, [[self formattedUID] UTF8String])) {
			/* There is a serverside display name, and it's not the same as our UID. */
			const char			*accountDisplayNameUTF8String = [[accountDisplayName string] UTF8String];
			
			if (accountDisplayNameUTF8String &&
				strcmp(accountDisplayNameUTF8String, displayName)) {
				/* The display name is different from our per-account preference, which exists. Check if our preference is static.
				 * If the if() above got FALSE, we don't need to do anything; the serverside preference should stand as-is. */
				[[adium contentController] filterAttributedString:accountDisplayName
												  usingFilterType:AIFilterContent
														direction:AIFilterOutgoing
													filterContext:self
												  notifyingTarget:self
														 selector:@selector(gotFilteredFriendlyName:context:)
														  context:[NSDictionary dictionaryWithObjectsAndKeys:
															  accountDisplayName, @"accountDisplayName",
															  [NSString stringWithUTF8String:displayName], @"displayName",
															  nil]];
			} else {
				NSLog(@"Not updating the display naame; it's %s and the display name is %s, mine is %@",
					  accountDisplayNameUTF8String,displayName, 
					  [self displayName]);
			}

		} else {
			shouldUpdateDisplayNameImmediately = YES;
		}
	}
	
	if (shouldUpdateDisplayNameImmediately) {
		[self updateStatusForKey:KEY_ACCOUNT_DISPLAY_NAME];
	}
}

- (void)gotFilteredFriendlyName:(NSAttributedString *)filteredFriendlyName context:(NSDictionary *)infoDict
{
	if ((!filteredFriendlyName && [infoDict objectForKey:@"displayName"]) ||
	   ([[filteredFriendlyName string] isEqualToString:[[infoDict objectForKey:@"accountDisplayName"] string]])) {
		/* Filtering made no changes to the string, so we're static. If we make it here, update to match the server. */
		NSAttributedString	*newPreference;

		newPreference = [[NSAttributedString alloc] initWithString:[infoDict objectForKey:@"displayName"]];

		[self setPreference:[newPreference dataRepresentation]
					 forKey:KEY_ACCOUNT_DISPLAY_NAME
					  group:GROUP_ACCOUNT_STATUS];
		[newPreference release];

		[self updateStatusForKey:KEY_ACCOUNT_DISPLAY_NAME];

	} else {
		//Set it serverside
		[self setServersideDisplayName:[filteredFriendlyName string]];
	}
}

extern void msn_set_friendly_name(GaimConnection *gc, const char *entry);

- (void)doQueuedSetServersideDisplayName
{
	[self setServersideDisplayName:queuedFriendlyName];
	[queuedFriendlyName release]; queuedFriendlyName = nil;
}

- (void)setServersideDisplayName:(NSString *)friendlyName
{
	if (gaim_account_is_connected(account)) {		
		NSDate *now = [NSDate date];

		if (!lastFriendlyNameChange ||
			[now timeIntervalSinceDate:lastFriendlyNameChange] > SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES) {
			/*
			 * The MSN display name will be URL encoded via gaim_url_encode().  The maximum length of the _encoded_ string is
			 * BUDDY_ALIAS_MAXLEN (387 characters as of gaim 2.0.0). We can't simply encode and truncate as we might end up with
			 * part of an encoded character being cut off, so we instead truncate to smaller and smaller strings and encode, until it fits
			 */
			const char *friendlyNameUTF8String = [friendlyName UTF8String];
			int currentMaxLength = BUDDY_ALIAS_MAXLEN;

			while (friendlyNameUTF8String &&
				   strlen(gaim_url_encode(friendlyNameUTF8String)) > currentMaxLength) {
				friendlyName = [friendlyName stringWithEllipsisByTruncatingToLength:currentMaxLength];				
				friendlyNameUTF8String = [friendlyName UTF8String];
				currentMaxLength -= 10;
			}
			AILog(@"%@: Updating serverside display name to %s", self, friendlyNameUTF8String);
			msn_set_friendly_name(gaim_account_get_connection(account), friendlyNameUTF8String);

			[lastFriendlyNameChange release];
			lastFriendlyNameChange = [now retain];

		} else {
			[NSObject cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(doQueuedSetServersideDisplayName)
													   object:nil];
			if (queuedFriendlyName != friendlyName) {
				[queuedFriendlyName release];
				queuedFriendlyName = [friendlyName retain];
			}
			[self performSelector:@selector(doQueuedSetServersideDisplayName)
					   withObject:nil
					   afterDelay:(SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES - [now timeIntervalSinceDate:lastFriendlyNameChange])];

			AILog(@"%@: Queueing serverside display name change to %@ for %d seconds", self, queuedFriendlyName, (SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES - [now timeIntervalSinceDate:lastFriendlyNameChange]));
		}
	}
}

/*
 * @brief Set our serverside 'friendly name'
 *
 * There is a rate limit on how quickly we can set our friendly name.
 *
 * @param attributedFriendlyName The new friendly name.  This is used as plaintext; it is an NSAttributedString for generic useage with the autoupdating filtering system.
 *
 */
- (void)gotFilteredDisplayName:(NSAttributedString *)attributedDisplayName
{
	NSString	*friendlyName = [attributedDisplayName string];
	
	if (!friendlyName || ![friendlyName isEqualToString:[self currentDisplayName]]) {		
		[self setServersideDisplayName:friendlyName];
	}
	
	[super gotFilteredDisplayName:attributedDisplayName];
}

- (BOOL)useDisplayNameAsStatusMessage
{
	return displayNamesAsStatus;
}

#pragma mark File transfer
- (BOOL)canSendFolders
{
	return NO;
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
	if ([group isEqualToString:PREF_GROUP_MSN_SERVICE]) {
		displayNamesAsStatus = [[prefDict objectForKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS] boolValue];
	}
}

#pragma mark Status messages

- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)buddy
{
	NSString		*statusName = nil;
	GaimPresence	*presence = gaim_buddy_get_presence(buddy);
	GaimStatus		*status = gaim_presence_get_active_status(presence);
	const char		*gaimStatusID = gaim_status_get_id(status);

	if (!gaimStatusID) return nil;

	if (!strcmp(gaimStatusID, "brb")) {
		statusName = STATUS_NAME_BRB;
		
	} else if (!strcmp(gaimStatusID, "busy")) {
		statusName = STATUS_NAME_BUSY;
		
	} else if (!strcmp(gaimStatusID, "phone")) {
		statusName = STATUS_NAME_PHONE;
		
	} else if (!strcmp(gaimStatusID, "lunch")) {
		statusName = STATUS_NAME_LUNCH;
		
	} else if (!strcmp(gaimStatusID, "invisible")) {
		statusName = STATUS_NAME_INVISIBLE;		
	}
	
	return statusName;
}

/*!
 * @brief Return the gaim status ID to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status ID
 * @param arguments Prpl-specific arguments which will be passed with the state. Message is handled automatically.
 *
 * @result The gaim status ID
 */
- (char *)gaimStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	char			*statusID = NULL;
	NSString		*statusName = [statusState statusName];
	NSString		*statusMessageString = [statusState statusMessageString];

	if (!statusMessageString) statusMessageString = @"";

	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			break;

		case AIAwayStatusType:
			if (([statusName isEqualToString:STATUS_NAME_BRB]) ||
				([statusMessageString caseInsensitiveCompare:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_BRB]] == NSOrderedSame))
				statusID = "brb";
			else if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
					 ([statusMessageString caseInsensitiveCompare:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_BUSY]] == NSOrderedSame))
				statusID = "busy";
			else if (([statusName isEqualToString:STATUS_NAME_PHONE]) ||
					 ([statusMessageString caseInsensitiveCompare:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_PHONE]] == NSOrderedSame))
				statusID = "phone";
			else if (([statusName isEqualToString:STATUS_NAME_LUNCH]) ||
					 ([statusMessageString caseInsensitiveCompare:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_LUNCH]] == NSOrderedSame))
				statusID = "lunch";

			break;
			
		case AIInvisibleStatusType:
		case AIOfflineStatusType:
			break;
	}
	
	//If we didn't get a gaim status ID, request one from super
	if (statusID == NULL) statusID = [super gaimStatusIDForStatus:statusState arguments:arguments];

	return statusID;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if ((strcmp(label, "Initiate Chat") == 0) || (strcmp(label, "Initiate _Chat") == 0)) {
		return [NSString stringWithFormat:AILocalizedString(@"Initiate Multiuser Chat with %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "Send to Mobile") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Send to %@'s Mobile",nil),[inContact formattedUID]];
	}
	
	return [super titleForContactMenuLabel:label forContact:inContact];
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{	
	if (strcmp(label, "Set Friendly Name...") == 0) {
//		return [AILocalizedString(@"Set Display Name","Action menu item for setting the display name") stringByAppendingEllipsis];
		return nil;

	} else if (strcmp(label, "Set Home Phone Number...") == 0) {
		return [AILocalizedString(@"Set Home Phone Number",nil) stringByAppendingEllipsis];
		
	} else if (strcmp(label, "Set Work Phone Number...") == 0) {
		return [AILocalizedString(@"Set Work Phone Number",nil) stringByAppendingEllipsis];
		
	} else if (strcmp(label, "Set Mobile Phone Number...") == 0) {
		return [AILocalizedString(@"Set Mobile Phone Number",nil) stringByAppendingEllipsis];
		
	} else if (strcmp(label, "Allow/Disallow Mobile Pages...") == 0) {
		return [AILocalizedString(@"Allow/Disallow Mobile Pages","Action menu item for MSN accounts to toggle whether Mobile pages [forwarding messages to a mobile device] are enabled") stringByAppendingEllipsis];

	} else if (strcmp(label, "Open Hotmail Inbox") == 0) {
		return AILocalizedString(@"Open Hotmail Inbox", "Action menu item for MSN accounts to open the hotmail inbox");
	}

	return [super titleForAccountActionMenuLabel:label];
}

@end

