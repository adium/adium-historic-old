//
//  ESGaimMSNAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESGaimMSNAccount.h"
#import "libgaim/state.h"

#define KEY_MSN_HOST	@"MSN:Host"
#define KEY_MSN_PORT	@"MSN:Port"

#define DEFAULT_MSN_PASSPORT_DOMAIN @"@hotmail.com"

@interface ESGaimMSNAccount (PRIVATE)
-(void)_setFriendlyNameTo:(NSAttributedString *)inAlias;
@end

@implementation ESGaimMSNAccount

static BOOL didInitMSN = NO;

//Intercept account creation to ensure the UID will have a domain ending -- the default is @hotmail.com
- (id)initWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID service:(AIService *)inService
{
	NSString	*correctUID;

	if((inUID) &&
	   ([inUID length] > 0) && 
	   ([inUID rangeOfString:@"@"].location == NSNotFound)){
		correctUID = [inUID stringByAppendingString:DEFAULT_MSN_PASSPORT_DOMAIN];
	}else{
		correctUID = inUID;
	}

	[super initWithUID:correctUID internalObjectID:inInternalObjectID service:inService];

	return(self);
}

- (void)initAccount
{
	[super initAccount];
	currentFriendlyName = nil;
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_MSN_SERVICE];
}

- (const char*)protocolPlugin
{
	[super initSSL];
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

- (NSString *)hostKey
{
	return KEY_MSN_HOST;
}
- (NSString *)portKey
{
	return KEY_MSN_PORT;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError){
		if (([disconnectionError rangeOfString:@"Type your e-mail address and password correctly"].location != NSNotFound)) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if (([disconnectionError rangeOfString:@"You have signed on from another location"].location != NSNotFound)) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return([AIHTMLDecoder encodeHTML:inAttributedString
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
					  bodyBackground:NO]);
}

//MSN (as of libgaim 1.1.0) tells us a buddy is away when they are merely idle.  Avoid passing that information on.
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data
{
	const char  *uidUTF8String = [[theContact UID] UTF8String];
	GaimBuddy   *buddy;
	BOOL		shouldUpdateAway = YES;

	if ((buddy = gaim_find_buddy(account, uidUTF8String)) &&
		(MSN_AWAY_TYPE(buddy->uc) == MSN_IDLE)){
			shouldUpdateAway = NO;
	}

	if(shouldUpdateAway){
		[super updateWentAway:theContact withData:data];
	}
}

#pragma mark Status
//Update our full name on connect
- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];
	[self updateStatusForKey:@"FullNameAttr"];
}	

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	[super updateStatusForKey:key];
	
    //Now look at keys which only make sense while online
	if([[self statusObjectForKey:@"Online"] boolValue]){

		if([key isEqualToString:@"FullNameAttr"]){
			
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(_setFriendlyNameTo:)];
		}
	}
}


/*
 gaim_connection_get_display_name(gc) will get the current display name... which is stored serverside so
 reflects changes made on other clients or other systems.  do we want to use this somehow?
 */
-(void)_setFriendlyNameTo:(NSAttributedString *)attributedFriendlyName
{
	NSString	*friendlyName = [attributedFriendlyName string];
	
	if (!friendlyName || ![friendlyName isEqualToString:[self statusObjectForKey:@"AccountServerDisplayName"]]){
		
		if (gaim_account_is_connected(account)){
			GaimDebug (@"Updating FullNameAttr to %@",friendlyName);
			
			msn_set_friendly_name(account->gc, [friendlyName UTF8String]);

			if([friendlyName length] == 0) friendlyName = nil;
			
			[[self displayArrayForKey:@"Display Name"] setObject:friendlyName
													   withOwner:self];
			//notify
			[[adium contactController] listObjectAttributesChanged:self
													  modifiedKeys:[NSSet setWithObject:@"Display Name"]];			
		}
	}
}

//Return YES if the display name (in the preference key @"FullNameAttr") should be managed by AIAccount.
//Return NO if a subclass will handle making it visible to the user (for example, if it should be filtered, first).
- (BOOL)superclassManagesDisplayName
{
	return NO;
}

- (BOOL)useDisplayNameAsStatusMessage
{
	return displayNamesAsStatus;
}

- (BOOL)displayConversationClosed
{
	return displayConversationClosed;
}

- (BOOL)displayConversationTimedOut
{
	return displayConversationTimedOut;
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
		
		return msn_xfer_new(account->gc,destsn);
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
	
	if([group isEqualToString:PREF_GROUP_MSN_SERVICE]){
		displayNamesAsStatus = [[prefDict objectForKey:KEY_MSN_DISPLAY_NAMES_AS_STATUS] boolValue];
		displayConversationClosed = [[prefDict objectForKey:KEY_MSN_CONVERSATION_CLOSED] boolValue];
		displayConversationTimedOut = [[prefDict objectForKey:KEY_MSN_CONVERSATION_TIMED_OUT] boolValue];
	}
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if(strcmp(label, "Initiate Chat") == 0){
		return([NSString stringWithFormat:AILocalizedString(@"Initiate Multiuser Chat with %@",nil),[inContact formattedUID]]);
	}
	
	return([super titleForContactMenuLabel:label forContact:inContact]);
}

/*
 //Added to msn.c
//**ADIUM
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

