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

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIStatusController.h"
#import "ESGaimMSNAccount.h"
#import "Libgaim/state.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIAccount.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#define DEFAULT_MSN_PASSPORT_DOMAIN @"@hotmail.com"

@interface ESGaimMSNAccount (PRIVATE)
- (void)updateFriendlyNameAfterConnect;
- (void)gotFilteredFriendlyName:(NSAttributedString *)filteredFriendlyName context:(NSDictionary *)infoDict;
- (void)_setFriendlyNameTo:(NSAttributedString *)inAlias;
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
	currentFriendlyName = nil;
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_MSN_SERVICE];
}

- (void)dealloc {
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[super dealloc];
}

gboolean gaim_init_msn_plugin(void);
- (const char*)protocolPlugin
{
	static BOOL didInitMSN = NO;

	[self initSSL];
	if (!didInitMSN) didInitMSN = gaim_init_msn_plugin();
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
	  attachmentImagesOnlyForSending:NO
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

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	//We'll handle FullNameAttr, the rest we let AIAccount handle for us
	if ([key isEqualToString:@"FullNameAttr"]) {
		if ([[self statusObjectForKey:@"Online"] boolValue]) {
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(_setFriendlyNameTo:)];
		}
	} else {
		[super updateStatusForKey:key];
	}
}

/*
 * @brief Update our friendly name to match the server friendly name if appropriate
 *
 * Well behaved MSN clients respect the serverside display name so that an update on one client is reflected on another.
 * 
 * If our display name is static, we should update to the serverside one if they aren't the same.
 *
 * However, if our display name is dynamic, most likely we're looking at the filtered version of our dynamic
 * name, so we shouldn't update to the filtered one.
 */
- (void)updateFriendlyNameAfterConnect
{
	const char *displayName = gaim_connection_get_display_name(gaim_account_get_connection(account));
	BOOL		invokedFilter = NO;
	
	//If the friendly name changed since the last time we connected, set it serverside and clear the flag
	if ([[self preferenceForKey:KEY_MSN_DISPLAY_NAMED_CHANGED
						  group:GROUP_ACCOUNT_STATUS] boolValue]) {
		[self updateStatusForKey:@"FullNameAttr"];
		[self setPreference:nil
					 forKey:KEY_MSN_DISPLAY_NAMED_CHANGED
					  group:GROUP_ACCOUNT_STATUS];

	} else {
		/* If our locally set friendly name didn't change since the last time we connected, we want to update
		 * to the serverside settings as appropriate.
		 */
		if (displayName &&
			strcmp(displayName, [[self UID] UTF8String]) &&
			strcmp(displayName, [[self formattedUID] UTF8String])) {
			/* There is a serverside display name, and it's not the same as our UID. */
			NSAttributedString	*ourPreference = [[self preferenceForKey:@"FullNameAttr" group:GROUP_ACCOUNT_STATUS] attributedString];
			const char			*ourPreferenceUTF8String = [[ourPreference string] UTF8String];
			
			if (!ourPreferenceUTF8String ||
				strcmp(ourPreferenceUTF8String, displayName)) {
				/* The display name is different from our preference. Check if our preference is static. */
				[[adium contentController] filterAttributedString:ourPreference
												  usingFilterType:AIFilterContent
														direction:AIFilterOutgoing
													filterContext:self
												  notifyingTarget:self
														 selector:@selector(gotFilteredFriendlyName:context:)
														  context:[NSDictionary dictionaryWithObjectsAndKeys:
															  ourPreference, @"ourPreference",
															  [NSString stringWithUTF8String:displayName], @"displayName",
															  nil]];
				invokedFilter = YES;
			}
		}
		
		if (!invokedFilter) {
			[self gotFilteredFriendlyName:nil
								  context:nil];
		}
	}
}

- (void)gotFilteredFriendlyName:(NSAttributedString *)filteredFriendlyName context:(NSDictionary *)infoDict
{
	if ((!filteredFriendlyName && [infoDict objectForKey:@"displayName"]) ||
	   ([[filteredFriendlyName string] isEqualToString:[[infoDict objectForKey:@"ourPreference"] string]])) {
		/* Filtering made no changes to the string, so we're static. If we make it here, update to match the server. */
		NSAttributedString	*newPreference;
		
		newPreference = [[NSAttributedString alloc] initWithString:[infoDict objectForKey:@"displayName"]];

		[self setPreference:[newPreference dataRepresentation]
					 forKey:@"FullNameAttr"
					  group:GROUP_ACCOUNT_STATUS];
		[newPreference release];
	}

	[self updateStatusForKey:@"FullNameAttr"];
}

/*
 * @brief Set our serverside 'friendly name'
 *
 * There is a rate limit on how quickly we can set our friendly name.
 *
 * @param attributedFriendlyName The new friendly name.  This is used as plaintext; it is an NSAttributedString for generic useage with the autoupdating filtering system.
 */
-(void)_setFriendlyNameTo:(NSAttributedString *)attributedFriendlyName
{
	NSString	*friendlyName = [attributedFriendlyName string];
	
	if (!friendlyName || ![friendlyName isEqualToString:[self statusObjectForKey:@"AccountServerDisplayName"]]) {
		
		if (gaim_account_is_connected(account)) {
			GaimDebug (@"Updating FullNameAttr to %@",friendlyName);

#warning XXX - friendly name setting is broken
			//msn_set_friendly_name(account->gc, [friendlyName UTF8String]);

			if ([friendlyName length] == 0) friendlyName = nil;
			
			[[self displayArrayForKey:@"Display Name"] setObject:friendlyName
													   withOwner:self];

			//Keep track of the friendly name so we can avoid doing duplicate sets on the same name
			[self setStatusObject:friendlyName
						   forKey:@"AccountServerDisplayName"
						   notify:NotifyNever];
			
			//notify
			[[adium contactController] listObjectAttributesChanged:self
													  modifiedKeys:[NSSet setWithObject:@"Display Name"]];			
		}
	}
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

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)) {
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];

#warning xfer
//		return msn_xfer_new(account->gc,destsn);
	}
	
	return nil;
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
- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)b
{
	NSAttributedString  *statusMessage = nil;

	/*
	NSString			*statusMessageString = nil;
	
	MsnAwayType		gaimMsnAwayType = MSN_AWAY_TYPE(b->uc);
	
	switch (gaimMsnAwayType) {
		case MSN_BRB:
			statusMessageString = STATUS_DESCRIPTION_BRB;
			break;
		case MSN_BUSY:
			statusMessageString = STATUS_DESCRIPTION_BUSY;
			break;
			
		case MSN_PHONE:
			statusMessageString = STATUS_DESCRIPTION_PHONE;
			break;
			
		case MSN_LUNCH:
			statusMessageString = STATUS_DESCRIPTION_LUNCH;
			break;
		
		case MSN_HIDDEN:
			statusMessageString = STATUS_DESCRIPTION_INVISIBLE;
			break;
		
		case MSN_IDLE:
		case MSN_AWAY:
		case MSN_ONLINE:
		case MSN_OFFLINE:
			break;
	}
	
	if (statusMessageString && [statusMessageString length]) {
		statusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
														 attributes:nil] autorelease];
	}
	*/
	return (statusMessage);
}

- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)b
{
	NSString			*statusName = nil;
	/*
	
	MsnAwayType		gaimMsnAwayType = MSN_AWAY_TYPE(b->uc);
	
	switch (gaimMsnAwayType) {
		case MSN_BRB:
			statusName = STATUS_NAME_BRB;
			break;
		case MSN_BUSY:
			statusName = STATUS_NAME_BUSY;
			break;
			
		case MSN_PHONE:
			statusName = STATUS_NAME_PHONE;
			break;
			
		case MSN_LUNCH:
			statusName = STATUS_NAME_LUNCH;
			break;
			
		case MSN_HIDDEN:
			statusName = STATUS_NAME_INVISIBLE;
			break;
			
		case MSN_IDLE:
		case MSN_AWAY:
		case MSN_ONLINE:
		case MSN_OFFLINE:
			break;
	}
	*/
	return (statusName);
}


/*!
 * @brief Update the status message and away state of the contact
 */
- (void)updateStatusForContact:(AIListContact *)theContact toStatusType:(NSNumber *)statusTypeNumber statusName:(NSString *)statusName statusMessage:(NSAttributedString *)statusMessage
{
//	const char  *uidUTF8String = [[theContact UID] UTF8String];
//	GaimBuddy   *buddy;
	BOOL		shouldUpdateAway = YES;

	/*
	if ((buddy = gaim_find_buddy(account, uidUTF8String)) &&
		(MSN_AWAY_TYPE(buddy->uc) == MSN_IDLE)) {
		shouldUpdateAway = NO;
	}
	*/
	if (shouldUpdateAway) {
		[super updateStatusForContact:theContact
						 toStatusType:statusTypeNumber
						   statusName:statusName
						statusMessage:statusMessage];
	}	
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

	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			break;

		case AIAwayStatusType:
			if (([statusName isEqualToString:STATUS_NAME_BRB]) ||
				([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BRB] == NSOrderedSame))
				statusID = "brb";
			else if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BUSY] == NSOrderedSame))
				statusID = "busy";
			else if (([statusName isEqualToString:STATUS_NAME_PHONE]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_PHONE] == NSOrderedSame))
				statusID = "phone";
			else if (([statusName isEqualToString:STATUS_NAME_LUNCH]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_LUNCH] == NSOrderedSame))
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
	if (strcmp(label, "Set Friendly Name") == 0) {
//		return [AILocalizedString(@"Set Display Name","Action menu item for setting the display name") stringByAppendingEllipsis];
		return nil;

	} else if (strcmp(label, "Set Home Phone Number") == 0) {
		return AILocalizedString(@"Set Home Phone Number",nil);
		
	} else if (strcmp(label, "Set Work Phone Number") == 0) {
		return AILocalizedString(@"Set Work Phone Number",nil);
		
	} else if (strcmp(label, "Set Mobile Phone Number") == 0) {
		return AILocalizedString(@"Set Mobile Phone Number",nil);
		
	} else if (strcmp(label, "Allow/Disallow Mobile Pages") == 0) {
		return AILocalizedString(@"Allow/Disallow Mobile Pages","Action menu item for MSN accounts to toggle whether Mobile pages [forwarding messages to a mobile device] are enabled");
	}

	return [super titleForAccountActionMenuLabel:label];
}

/*
 //Added to msn.c
// **ADIUM
void msn_set_friendly_name(GaimConnection *gc, const char *entry)
{
	msn_act_id(gc, entry);
}

GaimXfer *msn_xfer_new(GaimConnection *gc, char *who)
{
	session = gc->proto_data;
	
	xfer = gaim_xfer_new(gc->account, GAIM_XFER_SEND, who);
	
	slplink = msn_session_get_slplink(session, who);
	
	xfer->data = slplink;
	
	gaim_xfer_set_init_fnc(xfer, t_msn_xfer_init);
	
	return xfer;
}
*/
 
@end

