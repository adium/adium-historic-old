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
#import "AIStatusController.h"
#import "ESGaimMSNAccount.h"
#import "libgaim/state.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIAccount.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>

#define DEFAULT_MSN_PASSPORT_DOMAIN @"@hotmail.com"

@interface ESGaimMSNAccount (PRIVATE)
-(void)_setFriendlyNameTo:(NSAttributedString *)inAlias;
@end

@implementation ESGaimMSNAccount

/*!
* @brief The UID will be change. The account has a chance to perform modifications
 *
 * For example, MSN adds @hotmail.com to the proposedUID and returns the new value
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	NSString	*correctUID;
	
	if(([proposedUID length] > 0) && 
	   ([proposedUID rangeOfString:@"@"].location == NSNotFound)){
		correctUID = [proposedUID stringByAppendingString:DEFAULT_MSN_PASSPORT_DOMAIN];
	}else{
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
	//We'll handle FullNameAttr, the rest we let AIAccount handle for us
	if([key isEqualToString:@"FullNameAttr"]){
		if([[self statusObjectForKey:@"Online"] boolValue]){
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(_setFriendlyNameTo:)];
		}
	}else{
		[super updateStatusForKey:key];
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

#pragma mark Status messages
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
	GaimBuddy	*buddy;
	const char	*uidUTF8String = [[theContact UID] UTF8String];

	if ((gaim_account_is_connected(account)) &&
		(buddy = gaim_find_buddy(account, uidUTF8String))) {

		//Retrieve the current status string
		NSString		*statusName = nil;
		NSString		*statusMessage = nil;
		AIStatusType	statusType = ((buddy->uc & UC_UNAVAILABLE) ? AIAwayStatusType : AIAvailableStatusType);		
		MsnAwayType		gaimMsnAwayType = MSN_AWAY_TYPE(buddy->uc);

		switch(gaimMsnAwayType){
			case MSN_BRB:
				statusName = STATUS_NAME_BRB;
				statusMessage = STATUS_DESCRIPTION_BRB;
				break;
			case MSN_BUSY:
				statusName = STATUS_NAME_BUSY;
				statusMessage = STATUS_DESCRIPTION_BUSY;
				break;
				
			case MSN_PHONE:
				statusName = STATUS_NAME_PHONE;
				statusMessage = STATUS_DESCRIPTION_PHONE;
				break;
				
			case MSN_LUNCH:
				statusName = STATUS_NAME_LUNCH;
				statusMessage = STATUS_DESCRIPTION_LUNCH;
				break;
		}
		
		[theContact setStatusWithName:statusName
						   statusType:statusType
						statusMessage:(statusMessage ?
									   [[[NSAttributedString alloc] initWithString:statusMessage] autorelease]:
									   nil)
							   notify:NotifyLater];
		
		//Apply the change
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}

- (void)_updateAwayOfContact:(AIListContact *)theContact toAway:(BOOL)newAway
{
	[self updateStatusMessage:theContact];
}

/*!
 * @brief Return the gaim status type to be used for a status
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status equivalent
 * @param statusMessage A pointer to the statusMessage.  Set *statusMessage to nil if it should not be used directly for this status.
 *
 * @result The gaim status equivalent
 */
- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage
{
	NSString		*statusName = [statusState statusName];
	AIStatusType	statusType = [statusState statusType];
	char			*gaimStatusType = NULL;
	
	switch(statusType){
		case AIAvailableStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_AVAILABLE])
				gaimStatusType = "Available";
			break;
		}

		case AIAwayStatusType:
		{
			NSString	*statusMessageString = (*statusMessage ? [*statusMessage string] : @"");

			if (([statusName isEqualToString:STATUS_NAME_BRB]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BRB] == NSOrderedSame))
				gaimStatusType = "Be Right Back";
			else if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_BUSY] == NSOrderedSame))
				gaimStatusType = "Busy";
			else if (([statusName isEqualToString:STATUS_NAME_PHONE]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_PHONE] == NSOrderedSame))
				gaimStatusType = "On The Phone";
			else if (([statusName isEqualToString:STATUS_NAME_LUNCH]) ||
					 ([statusMessageString caseInsensitiveCompare:STATUS_DESCRIPTION_LUNCH] == NSOrderedSame))
				gaimStatusType = "Out To Lunch";
			else if([statusName isEqualToString:STATUS_NAME_AWAY]) /* Check last so statusMessageString has been properly checked. */
				gaimStatusType = "Away From Computer";

			break;
		}
			
		case AIInvisibleStatusType:
			gaimStatusType = "Hidden";
			break;
	}
	
	//If we are setting one of our custom statuses, don't use a status message
	if(gaimStatusType != NULL) 	*statusMessage = nil;

	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];

	return gaimStatusType;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if((strcmp(label, "Initiate Chat") == 0) || (strcmp(label, "Initiate _Chat") == 0)){
		return([NSString stringWithFormat:AILocalizedString(@"Initiate Multiuser Chat with %@",nil),[inContact formattedUID]]);
	}
	
	return([super titleForContactMenuLabel:label forContact:inContact]);
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if(strcmp(label, "Set Friendly Name") == 0){
		return(nil);
	}

	return([super titleForAccountActionMenuLabel:label]);
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

