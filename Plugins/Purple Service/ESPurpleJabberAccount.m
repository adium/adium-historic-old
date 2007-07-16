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

#import "ESPurpleJabberAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#include <Libpurple/presence.h>
#include <Libpurple/si.h>
#include <SystemConfiguration/SystemConfiguration.h>
#import "AMXMLConsoleController.h"
#import "AMPurpleJabberMoodTooltip.h"
#import "AMPurpleJabberServiceDiscoveryBrowsing.h"
#import "ESPurpleJabberAccountViewController.h"
#import "AMPurpleJabberAdHocServer.h"
#import <Adium/AIService.h>

#define DEFAULT_JABBER_HOST @"@jabber.org"

extern void jabber_roster_request(JabberStream *js);

@implementation ESPurpleJabberAccount

/*!
 * @brief The UID will be changed. The account has a chance to perform modifications
 *
 * Upgrade old Jabber accounts stored with the host in a separate key to have the right UID, in the form
 * name@server.org
 *
 * Append @jabber.org to a proposed UID which has no domain name and does not need to be updated.
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	proposedUID = [proposedUID lowercaseString];
	NSString	*correctUID;
	
	if ((proposedUID && ([proposedUID length] > 0)) && 
	   ([proposedUID rangeOfString:@"@"].location == NSNotFound)) {
		
		NSString	*host;
		//Upgrade code: grab a previously specified Jabber host
		if ((host = [self preferenceForKey:@"Jabber:Host" group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:YES])) {
			//Determine our new, full UID
			correctUID = [NSString stringWithFormat:@"%@@%@",proposedUID, host];

			//Clear the preference and then set the UID so we don't perform this upgrade again
			[self setPreference:nil forKey:@"Jabber:Host" group:GROUP_ACCOUNT_STATUS];
			[self setPreference:correctUID forKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];

		} else {
			//Append [self serverSuffix] (e.g. @jabber.org) to a Jabber account with no server
			correctUID = [proposedUID stringByAppendingString:[self serverSuffix]];
		}
	} else {
		correctUID = proposedUID;
	}

	return correctUID;
}

- (const char*)protocolPlugin
{
   return "prpl-jabber";
}

- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"AvailableMessage",
			@"Invisible",
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
}

- (void)accountConnectionStep:(NSString*)msg step:(int)step totalSteps:(int)step_count {
	if(step == 6) { // Initializing SSL/TLS
		hasEncryption = YES;
	}
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	NSString	*connectServer;
	BOOL		forceOldSSL, allowPlaintext, requireTLS;

	purple_account_set_username(account, [self purpleAccountName]);

	//'Connect via' server (nil by default)
	connectServer = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	//XXX - As of libpurple 2.0.0, 'localhost' doesn't work properly by 127.0.0.1 does. Hack!
	if (connectServer && [connectServer isEqualToString:@"localhost"])
		connectServer = @"127.0.0.1";
	
	purple_account_set_string(account, "connect_server", (connectServer ?
														[connectServer UTF8String] :
														""));
	
	//Force old SSL usage? (off by default)
	forceOldSSL = [[self preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "old_ssl", forceOldSSL);

	//Require SSL or TLS? (off by default)
	requireTLS = [[self preferenceForKey:KEY_JABBER_REQUIRE_TLS group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "require_tls", requireTLS);

	//Allow plaintext authorization over an unencrypted connection? Purple will prompt if this is NO and is needed.
	allowPlaintext = [[self preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "auth_plain_in_clear", allowPlaintext);
}

- (NSString *)serverSuffix
{
	AILog(@"using jabber");
	return DEFAULT_JABBER_HOST;
}

/*!	@brief	Obtain the resource name for this Jabber account.
 *
 *	This could be extended in the future to perform keyword substitution (e.g. s/%computerName%/CSCopyMachineName()/).
 *
 *	@return	The resource name for the account.
 */
- (NSString *)resourceName
{
    NSString *resource = [self preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
    
    if(resource == nil || [resource length] == 0)
        resource = [(NSString*)SCDynamicStoreCopyLocalHostName(NULL) autorelease];
    
    NSLog(@"Resource = %@", resource);
	return resource;
}

- (const char *)purpleAccountName
{
	NSString	*userNameWithHost = nil, *completeUserName = nil;
	BOOL		serverAppendedToUID;
	
	/*
	 * Purple stores the username in the format username@server/resource.  We need to pass it a username in this format
	 *
	 * The user should put the username in username@server format, which is common for Jabber. If the user does
	 * not specify the server, use jabber.org.
	 */
	
	serverAppendedToUID = ([UID rangeOfString:@"@"].location != NSNotFound);
	
	if (serverAppendedToUID) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [UID stringByAppendingString:[self serverSuffix]];
	}

	completeUserName = [NSString stringWithFormat:@"%@/%@" ,userNameWithHost, [self resourceName]];

	return [completeUserName UTF8String];
}

/*!
 * @brief Connect Host
 *
 * Convenience method for retrieving the connect host for this account
 *
 * Rather than having a separate server field, Jabber uses the servername after the user name.
 * username@server.org
 *
 * The connect server, stored in KEY_JABBER_CONNECT_SERVER, overrides this to provide the connect host. It will
 * not be set in most cases.
 */
- (NSString *)host
{
	NSString	*host;
	
	if (!(host = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS])) {
		int location = [UID rangeOfString:@"@"].location;

		if ((location != NSNotFound) && (location + 1 < [UID length])) {
			host = [UID substringFromIndex:(location + 1)];

		} else {
			host = [self serverSuffix];
		}
	}
	
	return host;
}

/*!
 * @brief Should set aliases serverside?
 *
 * Jabber supports serverside aliases.
 */
- (BOOL)shouldSetAliasesServerside
{
	return YES;
}

/*!
 * @brief Supports offline messaging?
 *
 * Jabber supports offline messaging.
 */
- (BOOL)canSendOfflineMessageToContact:(AIListContact *)inContact
{
	return YES;
}

- (AIListContact *)contactWithUID:(NSString *)sourceUID
{
	AIListContact	*contact;
	
	contact = [[adium contactController] existingContactWithService:service
															account:self
																UID:sourceUID];
	if (!contact) {		
		contact = [[adium contactController] contactWithService:[self _serviceForUID:sourceUID]
														account:self
															UID:sourceUID];
	}
	
	return contact;
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	AIService	*contactService;
	NSString	*contactServiceID = nil;

	if ([contactUID hasSuffix:@"@gmail.com"] ||
		[contactUID hasSuffix:@"@googlemail.com"]) {
		contactServiceID = @"libpurple-jabber-gtalk";

	} else if([contactUID hasSuffix:@"@livejournal.com"]){
		contactServiceID = @"libpurple-jabber-livejournal";
		
	} else {
		contactServiceID = @"libpurple-Jabber";
	}

	contactService = [[adium accountController] serviceWithUniqueID:contactServiceID];
	
	return contactService;
}

- (id)authorizationRequestWithDict:(NSDictionary*)dict {
	id handle;
	switch([[self preferenceForKey:KEY_JABBER_SUBSCRIPTION_BEHAVIOR group:GROUP_ACCOUNT_STATUS] intValue]) {
		case 2: // always accept + add
			// add
			{
				NSString *groupname = [self preferenceForKey:KEY_JABBER_SUBSCRIPTION_GROUP group:GROUP_ACCOUNT_STATUS];
				if([groupname length] > 0) {
					AIListContact *contact = [[adium contactController] contactWithService:[self service] account:self UID:[dict objectForKey:@"Remote Name"]];
					AIListGroup *group = [[adium contactController] groupWithUID:groupname];
					[[adium contactController] addContacts:[NSArray arrayWithObject:contact] toGroup:group];
				}
			}
			// fallthrough
		case 1: // always accept
			[[self purpleThread] doAuthRequestCbValue:[[[dict objectForKey:@"authorizeCB"] retain] autorelease] withUserDataValue:[[[dict objectForKey:@"userData"] retain] autorelease]];
			handle = [[NSObject alloc] init];
			break;
		case 3: // always deny
			[[self purpleThread] doAuthRequestCbValue:[[[dict objectForKey:@"denyCB"] retain] autorelease] withUserDataValue:[[[dict objectForKey:@"userData"] retain] autorelease]];
			handle = [[NSObject alloc] init];
			break;
		default: // ask (should be 0)
			return [super authorizationRequestWithDict:dict];
	}
	
	// we can't execute this immediately, since libpurple doesn't know about the handle yet
	[self performSelector:@selector(closeAuthRequest:) withObject:handle afterDelay:0.0];
	return handle;
}

- (void)closeAuthRequest:(id)handle {
	purple_account_request_close(handle);
}

- (void)purpleAccountRegistered:(BOOL)success {
	if(success && [[self service] accountViewController]) {
		const char *usernamestr = account->username;
		NSString *username;
		if(usernamestr) {
			NSString *userwithresource = [NSString stringWithUTF8String:usernamestr];
			NSRange slashrange = [userwithresource rangeOfString:@"/"];
			if(slashrange.location != NSNotFound)
				username = [userwithresource substringToIndex:slashrange.location];
			else
				username = userwithresource;
		} else
			username = (id)[NSNull null];
		NSString *pw = account->password?[NSString stringWithUTF8String:account->password]:[NSNull null];
		
		[[adium notificationCenter] postNotificationName:ESPurpleAccountUsernameAndPasswortRegisteredNotification
												  object:self
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													username, @"username",
													pw, @"password",
													nil]];
	}
}

#pragma mark Contacts
- (void)updateSignon:(AIListContact *)theContact withData:(void *)data
{
	[super updateSignon:theContact withData:data];
	
	//We only get user icons in Jabber when we request info. Do that now!
	[self delayedUpdateContactStatus:theContact];
}

#pragma mark Status

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	static AIHTMLDecoder *jabberHtmlEncoder = nil;
	if (!jabberHtmlEncoder) {
		jabberHtmlEncoder = [[AIHTMLDecoder alloc] init];
		[jabberHtmlEncoder setIncludesHeaders:NO];
		[jabberHtmlEncoder setIncludesFontTags:YES];
		[jabberHtmlEncoder setClosesFontTags:YES];
		[jabberHtmlEncoder setIncludesStyleTags:YES];
		[jabberHtmlEncoder setIncludesColorTags:YES];
		[jabberHtmlEncoder setEncodesNonASCII:NO];
		[jabberHtmlEncoder setPreservesAllSpaces:NO];
		[jabberHtmlEncoder setUsesAttachmentTextEquivalents:YES];
	}
	
	return [jabberHtmlEncoder encodeHTML:inAttributedString imagesPath:nil];
}

- (NSString *)_UIDForAddingObject:(AIListContact *)object
{
	NSString	*objectUID = [object UID];
	NSString	*properUID;
	
	if ([objectUID rangeOfString:@"@"].location != NSNotFound) {
		properUID = objectUID;
	} else {
		properUID = [NSString stringWithFormat:@"%@@%@",objectUID,[self host]];
	}
	
	return [properUID lowercaseString];
}

- (NSString *)unknownGroupName {
    return (AILocalizedString(@"Roster","Roster - the Jabber default group"));
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step) {
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data",nil);
			break;			
		case 3:
			return AILocalizedString(@"Authenticating",nil);
			break;
		case 5:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 6:
			return AILocalizedString(@"Authenticating",nil);
			break;
	}
	return nil;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	BOOL shouldReconnect = YES;
	
	if (disconnectionError && *disconnectionError) {
		if (([*disconnectionError rangeOfString:@"401"].location != NSNotFound) ||
			([*disconnectionError rangeOfString:@"Authentication Failure"].location != NSNotFound) ||
			([*disconnectionError rangeOfString:@"Not Authorized"].location != NSNotFound)) {
			shouldReconnect = NO;

			/* Automatic registration attempt */
			//Display no error message
			[*disconnectionError release];
			*disconnectionError = nil;

			[[adium interfaceController] displayQuestion:AILocalizedString(@"Would you like to register a new Jabber account?", nil)
										 withDescription:AILocalizedString(@"Jabber was unable to connect due to an invalid Jabber ID or password.  This may be because you do not yet have an account on this Jabber server.  Would you like to register now?",nil)
										 withWindowTitle:AILocalizedString(@"Invalid Jabber ID or Password",nil)
										   defaultButton:AILocalizedString(@"Register",nil)
										 alternateButton:AILocalizedString(@"Cancel",nil)
											 otherButton:nil
												  target:self
												selector:@selector(answeredShouldReigsterNewJabberAccount:userInfo:)
												userInfo:nil];

		} else if ([*disconnectionError rangeOfString:@"Stream Error"].location != NSNotFound) {
			shouldReconnect = NO;

		} else if ([*disconnectionError rangeOfString:@"requires plaintext authentication over an unencrypted stream"].location != NSNotFound) {
			shouldReconnect = NO;
			
		} else if ([*disconnectionError rangeOfString:@"Resource Conflict"].location != NSNotFound) {
			shouldReconnect = NO;
		}
	}
	
	return shouldReconnect;
}

- (BOOL)answeredShouldReigsterNewJabberAccount:(NSNumber *)returnCodeNumber userInfo:(id)userInfo
{
	AITextAndButtonsReturnCode returnCode = [returnCodeNumber intValue];

	switch (returnCode) {
		case AITextAndButtonsDefaultReturn:
			[self performSelector:@selector(performRegisterWithPassword:)
					   withObject:password
					   afterDelay:1];
			break;

		case AITextAndButtonsAlternateReturn:
		case AITextAndButtonsOtherReturn:
		case AITextAndButtonsClosedWithoutResponse:
			[self serverReportedInvalidPassword];
			break;
	}
	
	return YES;
}

- (void)disconnectFromDroppedNetworkConnection
{
	/* Before we disconnect from a dropped network connection, set gc->disconnect_timeout to a non-0 value.
	 * This will let the prpl know that we are disconnecting with no backing ssl connection and that therefore
	 * the ssl connection is has should not be messaged in the process of disconnecting.
	 */
	PurpleConnection *gc = purple_account_get_connection(account);
	if (PURPLE_CONNECTION_IS_VALID(gc) &&
		!gc->disconnect_timeout) {
		gc->disconnect_timeout = -1;
		AILog(@"%@: Disconnecting from a dropped network connection", self);
	}

	[super disconnectFromDroppedNetworkConnection];
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

#pragma mark Status Messages
- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)b
{
	NSAttributedString  *statusMessage = nil;

	if (purple_account_is_connected(account)) {		
		char	*normalized = g_strdup(purple_normalize(b->account, b->name));
		JabberBuddy	*jb;
		
		if ((jb = jabber_buddy_find(account->gc->proto_data, normalized, FALSE))) {
			NSString	*statusMessageString = nil;
			const char	*msg = jabber_buddy_get_status_msg(jb);
			
			if (msg) {
				//Get the custom jabber status message if one is set
				statusMessageString = [NSString stringWithUTF8String:msg];
			}
			
			if (statusMessageString && [statusMessageString length]) {
				statusMessage = [AIHTMLDecoder decodeHTML:statusMessageString];
			}
		}
		
		g_free(normalized);
	}
	
	return statusMessage;
}

- (NSString *)statusNameForPurpleBuddy:(PurpleBuddy *)buddy
{
	NSString		*statusName = nil;
	PurplePresence	*presence = purple_buddy_get_presence(buddy);
	PurpleStatus		*status = purple_presence_get_active_status(presence);
	const char		*purpleStatusID = purple_status_get_id(status);
	
	if (!purpleStatusID) return nil;

	if (!strcmp(purpleStatusID, jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_CHAT))) {
		statusName = STATUS_NAME_FREE_FOR_CHAT;
		
	} else if (!strcmp(purpleStatusID, jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_XA))) {
		statusName = STATUS_NAME_EXTENDED_AWAY;
		
	} else if (!strcmp(purpleStatusID, jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_DND))) {
		statusName = STATUS_NAME_DND;
		
	}
	
	return statusName;
}

/*!
 * @brief Jabber status messages are plaintext
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forStatusState:(AIStatus *)statusState
{
	return [[inAttributedString attributedStringByConvertingLinksToStrings] string];
}

#pragma mark Menu items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, "Un-hide From") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Un-hide From %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "Temporarily Hide From") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Temporarily Hide From %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "Unsubscribe") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Unsubscribe %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "(Re-)Request authorization") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Re-request Authorization from %@",nil),[inContact formattedUID]];

	} else if (strcmp(label,  "Cancel Presence Notification") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Cancel Presence Notification to %@",nil),[inContact formattedUID]];	
	}
	
	return [super titleForContactMenuLabel:label forContact:inContact];
}

#pragma mark Multiuser chat

//Multiuser chats come in with just the contact's name as contactName, but we want to actually do it right.
- (NSString *)uidForContactWithUID:(NSString *)inUID inChat:(AIChat *)chat
{
	return [NSString stringWithFormat:@"%@/%@",[chat name],inUID];
}

#pragma mark Status
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
	const char		*statusID = NULL;
	NSString		*statusName = [statusState statusName];
	NSString		*statusMessageString = [statusState statusMessageString];
	NSNumber		*priority = nil;
	
	if (!statusMessageString) statusMessageString = @"";

	switch ([statusState statusType]) {
		case AIAvailableStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) ||
			   ([statusMessageString caseInsensitiveCompare:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_FREE_FOR_CHAT]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_CHAT);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AVAILABLE group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
			   ([statusMessageString caseInsensitiveCompare:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_DND]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_DND);
			else if (([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY]) ||
					 ([statusMessageString caseInsensitiveCompare:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_XA);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIInvisibleStatusType:
			AILog(@"Warning: Invisibility is not yet supported in libpurple 2.0.0 jabber");
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_AWAY);
//			statusID = "Invisible";
			break;
			
		case AIOfflineStatusType:
			break;
	}

	//Set our priority, which is actually set along with the status...Default is 0.
	[arguments setObject:(priority ? priority : [NSNumber numberWithInt:0])
				  forKey:@"priority"];
	
	NSNumber *disableBuzz = [self preferenceForKey:KEY_JABBER_DISABLE_BUZZ group:GROUP_ACCOUNT_STATUS];
	[arguments setObject:[NSNumber numberWithBool:![disableBuzz boolValue]] forKey:@"buzz"];

	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* XXX All Jabber account actions depend upon adiumPurpleRequestFields */
    return [NSString stringWithCString:label encoding:NSISOLatin1StringEncoding]; // only temporary
	return nil;
}

- (void)accountMenuDidUpdate:(NSMenuItem*)menuItem {
	if(hasEncryption) {
		NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[menuItem title] attributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont menuFontOfSize:14.0f], NSFontAttributeName, // for some reason, the default font size seems to be slightly smaller than the real font, seems to be an AppKit bug
			nil]];
		NSFileWrapper *fwrap = [[NSFileWrapper alloc] initRegularFileWithContents:
			[[NSImage imageNamed:@"Lock_Black"] TIFFRepresentation]];
		[fwrap setFilename:@"Lock_Black.tif"];
		[fwrap setPreferredFilename:@"Lock_Black.tif"];
		
		NSTextAttachment * ta = [[NSTextAttachment alloc] initWithFileWrapper:fwrap];
		
		[title appendAttributedString:[[[NSAttributedString alloc] initWithString:@"   "] autorelease]];
		[title appendAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];
		
		[ta release];
		[fwrap release];

		[menuItem setAttributedTitle:title];
		[title release];
	} else {
		[menuItem setAttributedTitle:nil];
	}
}

#pragma mark Gateway Tracking

- (void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName contactName:(NSString *)contactName {
	NSRange atsign = [[theContact UID] rangeOfString:@"@"];
	if(atsign.location != NSNotFound)
		[super updateContact:theContact toGroupName:groupName contactName:contactName];
	else {
		NSEnumerator *e = [gateways objectEnumerator];
		AIListContact *gateway;
		// avoid duplicates!
		while((gateway = [e nextObject])) {
			if([[gateway UID] isEqualToString:[theContact UID]]) {
				[gateways removeObjectIdenticalTo:gateway];
				break;
			}
		}
		[gateways addObject:theContact];
	}
}

- (void)removeContact:(AIListContact *)theContact {
	NSRange atsign = [[theContact UID] rangeOfString:@"@"];
	if(atsign.location != NSNotFound)
		[super removeContact:theContact];
	else {
		NSEnumerator *e = [gateways objectEnumerator];
		AIListContact *gateway;
		while((gateway = [e nextObject])) {
			if([[gateway UID] isEqualToString:[theContact UID]]) {
				[gateways removeObjectIdenticalTo:gateway];
				break;
			}
		}
	}
}

#pragma mark XML Console, Tooltip, AdHoc Server Integration and Gateway Integration

- (void)didConnect {
	gateways = [[NSMutableArray alloc] init];
	if(adhocServer)
		[adhocServer release];
	adhocServer = [[AMPurpleJabberAdHocServer alloc] initWithAccount:self];
	[adhocServer addCommand:@"ping" delegate:[AMPurpleJabberAdHocPing class] name:@"Ping"];
	
    [super didConnect];
	
    xmlConsoleController = [[AMXMLConsoleController alloc] initWithPurpleConnection:account->gc];
	
	moodTooltip = [[AMPurpleJabberMoodTooltip alloc] initWithAccount:self];

	[[adium interfaceController] registerContactListTooltipEntry:moodTooltip secondaryEntry:YES];
	discoveryBrowserController = [[AMPurpleJabberServiceDiscoveryBrowsing alloc] initWithAccount:self purpleConnection:purple_account_get_connection(account)];
}

- (void)didDisconnect {
	hasEncryption = NO;
    [xmlConsoleController release];
    xmlConsoleController = nil;
	[[adium interfaceController] unregisterContactListTooltipEntry:moodTooltip secondaryEntry:YES];
	[moodTooltip release];
	moodTooltip = nil;
	[discoveryBrowserController release];
	discoveryBrowserController = nil;
	[adhocServer release];
	adhocServer = nil;
	[super didDisconnect];
	[gateways release];
	gateways = nil;
}

- (IBAction)showXMLConsole:(id)sender {
    if(xmlConsoleController)
        [xmlConsoleController showWindow:sender];
    else
        NSBeep();
}

- (IBAction)showDiscoveryBrowser:(id)sender {
	[discoveryBrowserController browse:sender];
}

- (NSArray *)accountActionMenuItems {
	NSMutableArray *menu = [[NSMutableArray alloc] init];
	
	if([gateways count] > 0) {
		NSEnumerator *e = [gateways objectEnumerator];
		AIListContact *gateway;
		while((gateway = [e nextObject])) {
			NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:[gateway UID] action:@selector(registerGateway:) keyEquivalent:@""];
			NSMenu *submenu = [[NSMenu alloc] initWithTitle:[gateway UID]];
			
			NSArray *menuitemarray = [self menuItemsForContact:gateway];
			NSEnumerator *e2 = [menuitemarray objectEnumerator];
			NSMenuItem *m2item;
			while((m2item = [e2 nextObject]))
				[submenu addItem:m2item];
			
			[mitem setSubmenu:submenu];
			[submenu release];
			[mitem setRepresentedObject:gateway];
			[mitem setImage:[gateway displayArrayObjectForKey:@"Tab Status Icon"]];
			[mitem setTarget:self];
			[menu addObject:mitem];
			[mitem release];
		}
        [menu addObject:[NSMenuItem separatorItem]];
	}
	
    NSArray *supermenu = [super accountActionMenuItems];
    if(supermenu) {
		[menu addObjectsFromArray:supermenu];
        [menu addObject:[NSMenuItem separatorItem]];
	}
    	
    NSMenuItem *xmlConsoleMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"XML Console",nil) action:@selector(showXMLConsole:) keyEquivalent:@""];
    [xmlConsoleMenuItem setTarget:self];
    [menu addObject:xmlConsoleMenuItem];
    [xmlConsoleMenuItem release];

	NSMenuItem *discoveryBrowserMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Discovery Browser",nil) action:@selector(showDiscoveryBrowser:) keyEquivalent:@""];
    [discoveryBrowserMenuItem setTarget:self];
    [menu addObject:discoveryBrowserMenuItem];
    [discoveryBrowserMenuItem release];
	
    return [menu autorelease];
}

- (void)registerGateway:(NSMenuItem*)mitem {
	if(mitem && [mitem representedObject])
		jabber_register_gateway((JabberStream*)[self purpleAccount]->gc->proto_data, [[[mitem representedObject] UID] UTF8String]);
	else
		NSBeep();
}

- (AMPurpleJabberAdHocServer*)adhocServer {
	return adhocServer;
}

@end
