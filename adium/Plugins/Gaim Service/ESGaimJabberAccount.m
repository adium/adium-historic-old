//
//  ESGaimJabberAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimJabberAccountViewController.h"
#import "ESGaimJabberAccount.h"

#include <Libgaim/buddy.h>
#include <Libgaim/presence.h>
#include <Libgaim/si.h>

@implementation ESGaimJabberAccount

static BOOL				didInitJabber = NO;
static NSDictionary		*presetStatusesDictionary = nil;

- (const char*)protocolPlugin
{
	[super initSSL];
	if (!didInitJabber) didInitJabber = gaim_init_jabber_plugin();
    return "prpl-jabber";
}

- (void)initAccount
{
	if (!presetStatusesDictionary){
		presetStatusesDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
			AILocalizedString(@"Away",nil),				[NSNumber numberWithInt:JABBER_STATE_AWAY],
			AILocalizedString(@"Chatty",nil),			[NSNumber numberWithInt:JABBER_STATE_CHAT],
			AILocalizedString(@"Extended Away",nil),	[NSNumber numberWithInt:JABBER_STATE_XA],
			AILocalizedString(@"Do Not Disturb",nil),	[NSNumber numberWithInt:JABBER_STATE_DND],nil] retain];
	}
	
	[super initAccount];
}
- (void)dealloc
{
	[super dealloc];
}

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	NSString	*connectServer;
	BOOL		forceOldSSL, useTLS, allowPlaintext;
	
	//'Connect via' server (nil by default)
	connectServer = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	if (connectServer){
		gaim_account_set_string(account, "connect_server", [connectServer UTF8String]);
	}
	
	//Force old SSL usage? (off by default)
	forceOldSSL = [[self preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "old_ssl", forceOldSSL);

	//Allow TLS useage? (on by default)
	useTLS = [[self preferenceForKey:KEY_JABBER_USE_TLS group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "use_tls", useTLS);

	//Allow plaintext authorization over an unencrypted connection? Gaim will prompt if this is NO and is needed.
	allowPlaintext = [[self preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "auth_plain_in_clear", allowPlaintext);
}

- (void)createNewGaimAccount
{
	[super createNewGaimAccount];
	
	NSString	 *resource, *userNameWithHost = nil, *completeUserName = nil;
	BOOL		serverAppendedToUID;
	
	//Gaim stores the username in the format username@server/resource.  We need to pass it a username in this format
	//createNewGaimAccount gets called on every connect, so we need to make sure we don't append the information more
	//than once.
	//If the user puts the uesrname in username@server format, which is common for Jabber, we should
	//handle this gracefully, ignoring the server preference entirely.
	serverAppendedToUID = ([UID rangeOfString:@"@"].location != NSNotFound);
	
	if (serverAppendedToUID){
		userNameWithHost = UID;
	}else{
		userNameWithHost = [NSString stringWithFormat:@"%@@%@",UID,[self host]];
	}
	
	resource = [self preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
	completeUserName = [NSString stringWithFormat:@"%@/%@",userNameWithHost,resource];
	
	gaim_account_set_username(account, [completeUserName UTF8String]);
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return([AIHTMLDecoder encodeHTML:inAttributedString
							 headers:YES
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:NO
						  imagesPath:nil
				   attachmentsAsText:YES
	  attachmentImagesOnlyForSending:YES
					  simpleTagsOnly:NO]);
}

//Make sure the server is appended if something attempts to access the formattedUID
- (NSString *)formattedUID
{
	if ([UID rangeOfString:@"@"].location != NSNotFound){
		return UID;
	}else{
		return ([NSString stringWithFormat:@"%@@%@",UID,[self host]]);
	}
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

- (NSString *)hostKey
{
	return KEY_JABBER_HOST;
}

- (NSString *)portKey
{
	return KEY_JABBER_PORT;
}

- (void)accountConnectionConnected
{
	[super accountConnectionConnected];
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldReconnect = YES;
	
	if (disconnectionError){
		if ([disconnectionError rangeOfString:@"401"].location != NSNotFound) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if ([disconnectionError rangeOfString:@"Stream Error"].location != NSNotFound){
			shouldReconnect = NO;
		}
	}
	
	return shouldReconnect;
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)){
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
		
		return jabber_outgoing_xfer_new(account->gc,destsn);
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

#pragma mark Status Messages
- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	SEL updateSelector = nil;
	
	switch ([event intValue]){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
	}
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	if (gaim_account_is_connected(account)){
		const char  *uidUTF8String = [[theContact UID] UTF8String];
		GaimBuddy   *buddy;
		JabberBuddy *jb;
		
		if ((buddy = gaim_find_buddy(account, uidUTF8String)) &&
			(jb = jabber_buddy_find(account->gc->proto_data, uidUTF8String, FALSE))){	
			
			//Retrieve the current status string
			NSString		*oldStatusMsgString = [theContact statusObjectForKey:@"StatusMessageString"];
			NSString		*statusMsgString = nil;
			
			//Get the custom jabber status message if one is set
			const char		*msg = jabber_buddy_get_status_msg(jb);
			if (msg){
				statusMsgString = [NSString stringWithUTF8String:msg];
			}
			//If no custom status message, but the buddy's uc matches the UC_UNAVAILABLE mask, lookup the preset string for the status
			if (!statusMsgString && (buddy->uc & UC_UNAVAILABLE)){
				statusMsgString = [presetStatusesDictionary objectForKey:[NSNumber numberWithInt:buddy->uc]];
			}
			
			//Update as necessary
			if ([statusMsgString length] && ![statusMsgString isEqualToString:@"Online"]) {
				if (![statusMsgString isEqualToString:oldStatusMsgString]) {
					NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString:statusMsgString] autorelease];
					
					[theContact setStatusObject:statusMsgString forKey:@"StatusMessageString" notify:NO];
					[theContact setStatusObject:attrStr forKey:@"StatusMessage" notify:NO];
					
					//apply changes
					[theContact notifyOfChangedStatusSilently:silentAndDelayed];
				}
				
			} else if ([oldStatusMsgString length]) {
				//If we had a message before, remove it
				[theContact setStatusObject:nil forKey:@"StatusMessageString" notify:NO];
				[theContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
				
				//apply changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];
			}
		}
	}
}

- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data
{
	[super updateWentAway:theContact withData:data];
	[self updateStatusMessage:theContact];
}
- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data
{
	[super updateAwayReturn:theContact withData:data];
	[self updateStatusMessage:theContact];	
}
@end