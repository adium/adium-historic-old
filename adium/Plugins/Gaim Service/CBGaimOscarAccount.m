//
//  CBGaimOscarAccount.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 06 2003.
//

#import "CBGaimOscarAccount.h"

#define KEY_OSCAR_HOST  @"Oscar:Host"
#define KEY_OSCAR_PORT  @"Oscar:Port"

#define	PREF_GROUP_NOTES			@"Notes"                //Preference group to store notes in

static NSString *ICQServiceID = nil;
static NSString *MobileServiceID = nil;

@interface CBGaimOscarAccount (PRIVATE)
-(NSString *)serversideCommentForContact:(AIListContact *)theContact;
-(NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding;
@end

@implementation CBGaimOscarAccount

static BOOL didInitOscar = NO;

- (const char*)protocolPlugin
{
	if (!didInitOscar) didInitOscar = gaim_init_oscar_plugin();
    return "prpl-oscar";
}

- (void)initAccount
{
	[super initAccount];
	
	if ([UID length]){
		char firstCharacter = [UID characterAtIndex:0];
		if (firstCharacter >= '0' && firstCharacter <= '9') {
			if (!ICQServiceID) ICQServiceID = @"ICQ";
			[self setStatusObject:ICQServiceID forKey:@"DisplayServiceID" notify:YES];
		}
	}
	
	//Observe preferences changes
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];	
}

- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];
	[super dealloc];
}

/*
//AIM doesn't require we close our tags, so don't waste the characters
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	BOOL	noHTML = NO;
	
	//We don't want to send HTML to ICQ users, or mobile phone users
	if(inListObject){
		char	firstCharacter = [[inListObject UID] characterAtIndex:0];
	    noHTML = ((firstCharacter >= '0' && firstCharacter <= '9') || firstCharacter == '+');
	}
	
	return((noHTML ? [inAttributedString string] : [AIHTMLDecoder encodeHTML:inAttributedString
																	 headers:YES
																	fontTags:YES
														  includingColorTags:YES
															   closeFontTags:NO
																   styleTags:YES
												  closeStyleTagsOnFontChange:NO
															  encodeNonASCII:NO
																  imagesPath:nil
														   attachmentsAsText:YES]));
}
*/
//Override _contactWithUID to mark mobile and ICQ users as such via the displayServiceID
- (AIListContact *)_contactWithUID:(NSString *)sourceUID
{
	AIListContact   *contact;
	
	contact = [super _contactWithUID:sourceUID];
	
	if (![contact statusObjectForKey:@"DisplayServiceID"]){
		BOOL			isICQ, isMobile;
		char			firstCharacter;
		firstCharacter = [sourceUID characterAtIndex:0];
		if ( (isICQ = (firstCharacter >= '0' && firstCharacter <= '9')) || (isMobile = (firstCharacter == '+')) ) {
			if (isICQ){
				if (!ICQServiceID) ICQServiceID = @"ICQ";
				[contact setStatusObject:ICQServiceID forKey:@"DisplayServiceID" notify:NO];
			}else{
				if (!MobileServiceID) MobileServiceID = @"Mobile";
				[contact setStatusObject:MobileServiceID forKey:@"DisplayServiceID" notify:NO];
			}
			
			//Apply any changes
			[contact notifyOfChangedStatusSilently:silentAndDelayed];
			
		}else {
			[contact setStatusObject:[contact serviceID] forKey:@"DisplayServiceID" notify:NO];
		}
	}
	
	return contact;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError) {
		if ([disconnectionError rangeOfString:@"Incorrect nickname or password."].location != NSNotFound) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if ([disconnectionError rangeOfString:@"signed on with this screen name at another location"].location != NSNotFound) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
}

#pragma mark Account Connection

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Screen name sent",nil);
			break;
		case 2:
			return AILocalizedString(@"Password sent",nil);
			break;			
		case 3:
			return AILocalizedString(@"Received authorization",nil);
			break;
		case 4:
			return AILocalizedString(@"Connection established",nil);
			break;
		case 5:
			return AILocalizedString(@"Finalizing connection",nil);
			break;
	}
	return nil;
}

- (NSString *)hostKey
{
	return KEY_OSCAR_HOST;
}
- (NSString *)portKey
{
	return KEY_OSCAR_PORT;
}

#pragma mark Buddy updates
- (oneway void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	[super updateContact:theContact forEvent:event];
	
	SEL updateSelector = nil;
	
	switch([event intValue]){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
		case GAIM_BUDDY_INFO_UPDATED: {
			updateSelector = @selector(updateInfo:);
			break;
		}
		case GAIM_BUDDY_MISCELLANEOUS: {  
			updateSelector = @selector(updateMiscellaneous:);
			break;
		}
	}
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
}
	
- (void)updateStatusMessage:(AIListContact *)theContact
{
	NSString			*statusMsgString = nil;
	NSString			*oldStatusMsgString = [theContact statusObjectForKey:@"StatusMessageString"];
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	struct buddyinfo	*bi;
	GaimBuddy			*buddy;
	
	const char				*buddyName = [[theContact UID] UTF8String];
	
	if (gc &&
		(od = gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, buddyName))){
	
		bi = g_hash_table_lookup(od->buddyinfo, buddyName);
		
		if ((bi != NULL) && (bi->availmsg != NULL) && !(userinfo->flags & AIM_FLAG_AWAY)) {
			
			//Available status message
			statusMsgString = [NSString stringWithUTF8String:(bi->availmsg)];
			
		} else if ((userinfo->flags & AIM_FLAG_AWAY) && (userinfo->away_len > 0) && 
				   (userinfo->away != NULL) && (userinfo->away_encoding != NULL)) {
			
			//Away message
			statusMsgString = [self stringWithBytes:userinfo->away
											 length:userinfo->away_len
										   encoding:userinfo->away_encoding];
			
			//If the away message changed, make sure the contact is marked as away
			/*
			BOOL		newAway;
			NSNumber	*storedValue;
			
			newAway =  ((buddy->uc & UC_UNAVAILABLE) != 0);
			storedValue = [theContact statusObjectForKey:@"Away"];
			if((!newAway && (storedValue == nil)) || newAway != [storedValue boolValue]) {
				[theContact setStatusObject:[NSNumber numberWithBool:newAway] forKey:@"Away" notify:NO];
			}
			 */
		}
		
		//Update the status message if necessary
		if (statusMsgString && [statusMsgString length]) {
			if (![statusMsgString isEqualToString:oldStatusMsgString]) {
				[theContact setStatusObject:statusMsgString forKey:@"StatusMessageString" notify:NO];
				[theContact setStatusObject:[AIHTMLDecoder decodeHTML:statusMsgString]
									 forKey:@"StatusMessage"
									 notify:NO];
			}
		} else if (oldStatusMsgString) {
			[theContact setStatusObject:nil forKey:@"StatusMessageString" notify:NO];
			[theContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
		}
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}
- (void)updateInfo:(AIListContact *)theContact
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	GaimBuddy			*buddy;
	
	if (gc &&
		(od = gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, [[theContact UID] UTF8String]))){
			
		//Update the profile if necessary - length must be greater than one since we get "" with info_len 1
		//when attempting to retrieve the profile of an AOL member (which can't be done via AIM).
		if ((userinfo->info_len > 1) && (userinfo->info != NULL) && (userinfo->info_encoding != NULL)) {
			
			//Away message
			NSString *profileString = [self stringWithBytes:userinfo->info
													 length:userinfo->info_len
												   encoding:userinfo->info_encoding];
			
			NSString *oldProfileString = [theContact statusObjectForKey:@"TextProfileString"];
			
			if (profileString && [profileString length]) {
				if (![profileString isEqualToString:oldProfileString]) {
					[theContact setStatusObject:profileString
										 forKey:@"TextProfileString" 
										 notify:NO];
					[theContact setStatusObject:[AIHTMLDecoder decodeHTML:profileString]
										 forKey:@"TextProfile" 
										 notify:NO];
				}
			} else if (oldProfileString) {
				[theContact setStatusObject:nil forKey:@"TextProfileString" notify:NO];
				[theContact setStatusObject:nil forKey:@"TextProfile" notify:NO];	
			}
		}
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}	

- (void)updateMiscellaneous:(AIListContact *)theContact
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	GaimBuddy			*buddy;
	
	if (gc &&
		(od = gc->proto_data) && 
		(userinfo = aim_locate_finduserinfo(od->sess, [[theContact UID] UTF8String]))){
	
	/*
	 userinfo->membersince;
	 userinfo->capabilities;
	 */
		
		//Client
		NSString *storedString = [theContact statusObjectForKey:@"Client"];
		NSString *client = nil;
		
		if (userinfo->present & AIM_USERINFO_PRESENT_FLAGS) {
			if (userinfo->capabilities & AIM_CAPS_HIPTOP) {
				client = @"AIM via Hiptop";
			} else if (userinfo->flags & AIM_FLAG_WIRELESS) {
				client = @"AOL Mobile Device";
			} else if (userinfo->flags & AIM_FLAG_ADMINISTRATOR) {
				client = @"AOL Administrator";
			} else if (userinfo->flags & AIM_FLAG_AOL) {
				client = @"America Online";
			}/* else if ((userinfo->flags & AIM_FLAG_FREE) || (userinfo->flags & AIM_FLAG_UNCONFIRMED)) {
							client = @"AOL Instant Messenger";
			}*/
		}
		
		/*
		 if (b->name && (b->uc & 0xffff0000) && isdigit(b->name[0])) {
			 
			 //ICQ
			 int uc = b->uc >> 16;
			 if (uc & AIM_ICQ_STATE_INVISIBLE)
				 emblems[i++] = "invisible";
			 else if (uc & AIM_ICQ_STATE_CHAT)
				 emblems[i++] = "freeforchat";
			 else if (uc & AIM_ICQ_STATE_DND)
				 emblems[i++] = "dnd";
			 else if (uc & AIM_ICQ_STATE_OUT)
				 emblems[i++] = "na";
			 else if (uc & AIM_ICQ_STATE_BUSY)
				 emblems[i++] = "occupied";
			 else if (uc & AIM_ICQ_STATE_AWAY)
				 emblems[i++] = "away";
		 } else {
			 if (b->uc & UC_UNAVAILABLE) 
				 emblems[i++] = "away";
		 }
		 
		 if (b->uc & UC_WIRELESS)
		 emblems[i++] = "wireless";
		 if (b->uc & UC_AOL)
		 emblems[i++] = "aol";
		 if (b->uc & UC_ADMIN)
		 emblems[i++] = "admin";
		 if (b->uc & UC_AB && i < 4)
		 emblems[i++] = "activebuddy";
		 
		 if ((i < 4) && (userinfo != NULL) && (userinfo->capabilities & AIM_CAPS_HIPTOP))
		 emblems[i++] = "hiptop";
		 
		 if ((i < 4) && (userinfo != NULL) && (userinfo->capabilities & AIM_CAPS_SECUREIM))
		 emblems[i++] = "secure";
		 */
		
		if(client) {
			//Set the client if necessary
			if (storedString == nil || ![client isEqualToString:storedString]){
				[theContact setStatusObject:client forKey:@"Client" notify:NO];
				
				//Apply any changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];
			}
		} else {
			//Clear the client value if one was present before
			if (storedString){
				[theContact setStatusObject:nil forKey:@"Client" notify:NO];
				
				//Apply any changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];	
			}
		}
	}
}

- (void)gotGroupForContact:(AIListContact *)theContact
{
	[theContact setStatusObject:[self serversideCommentForContact:theContact]
						 forKey:@"Notes"
						 notify:YES];
}

- (NSArray *)contactStatusFlags
{
	static NSArray *contactStatusFlagsArray = nil;
	
	if (!contactStatusFlagsArray)
		contactStatusFlagsArray = [[[NSArray arrayWithObjects:@"StatusMessage",@"StatusMessageString",@"TextProfile",@"TextProfileString",nil] arrayByAddingObjectsFromArray:[super contactStatusFlags]] retain];
	
	return contactStatusFlagsArray;
}

/* Setting available message
struct oscar_data *od = gc->proto_data;
aim_srv_setavailmsg(od->sess, text);
*/

//This check is against the attributed string, not the HTML it creates... so it's worthless. :)
/*- (void)setProfile:(NSAttributedString *)profile
{
    if (profile){
        int length = [profile length];
        if (length > 1024){
            [[adium interfaceController] handleErrorMessage:@"Error Setting Profile"
                                            withDescription:[NSString stringWithFormat:@"Your info is too large, and could not be set.\r\rAIM and ICQ limit profiles to 1024 characters (Your current profile is %i characters)",length]];
        }else{
            [super setProfile:profile];
        }
    }else{
        [super setProfile:profile];
    }
}*/

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
	
	return oscar_xfer_new(gc,destsn);
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}


//Only return YES if the user's capabilities include AIM_CAPS_SENDFILE indicating support for file transfer
- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	GaimBuddy			*buddy;
	
	if (gc &&
		(od = gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, [[inListObject UID] UTF8String]))){
		
		return (userinfo->capabilities & AIM_CAPS_SENDFILE);
	}
	
	return NO;
}

#pragma mark Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type
{
    return [super addListObject:inObject toPrivacyList:type];
}
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type
{
    return [super removeListObject:inObject fromPrivacyList:type]; 
}

#pragma mark Contact notes


-(NSString *)serversideCommentForContact:(AIListContact *)theContact
{	
	NSString *serversideComment = nil;
	
	if (gc){
		const char  *uidUTF8String = [[theContact UID] UTF8String];
		GaimBuddy   *buddy = gaim_find_buddy(account, uidUTF8String);
		GaimGroup   *g;
		char		*comment;
		OscarData   *od;
		
		if (!(g = gaim_find_buddys_group(buddy)))
			return nil;

		od = gc->proto_data;

		comment = aim_ssi_getcomment(od->sess->ssi.local, g->name, buddy->name);
		if (comment){
			gchar		*comment_utf8;

			comment_utf8 = gaim_utf8_try_convert(comment);
			serversideComment = [NSString stringWithUTF8String:comment_utf8];
			g_free(comment_utf8);
		}
		free(comment);
	}
	
	return serversideComment;
}
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_NOTES]){
		AIListObject *listObject = [notification object];
		
		//If the notification object is a listContact belonging to this account, update the serverside notes
		if ([listObject isKindOfClass:[AIListContact class]] && 
			[[(AIListContact *)listObject accountID] isEqualToString:[self uniqueObjectID]]){
			
			if (gc){
				const char  *uidUTF8String = [[listObject UID] UTF8String];
				GaimBuddy   *buddy = gaim_find_buddy(account, uidUTF8String);
				GaimGroup   *g;
				OscarData   *od;
				const char  *comment;
				
				if ((g = gaim_find_buddys_group(buddy)) && (od = gc->proto_data)){
					comment = [[listObject preferenceForKey:@"Notes" group:PREF_GROUP_NOTES] UTF8String];
					
					aim_ssi_editcomment(od->sess, g->name, uidUTF8String, comment);	
				}
				
			}
		}
	}
}

-(NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding
{
	//Default to ASCII
	NSStringEncoding	desiredEncoding = NSUTF8StringEncoding;

	//Only attempt to check encoding if we were passed one
	if (encoding && (encoding[0] != '\0')){
		NSString			*encodingString = [NSString stringWithUTF8String:encoding];
		
		if (encodingString){
			if ([encodingString rangeOfString:@"unicode-2-0"].location != NSNotFound){
				desiredEncoding = NSUnicodeStringEncoding;
			}else if ([encodingString rangeOfString:@"iso-8859-1"].location != NSNotFound){
				desiredEncoding = NSISOLatin1StringEncoding;
			}
		}
		
	}
	
	//NSLog(@"[%s] [%i] [%i - %s]",bytes,length,desiredEncoding,encoding);

	return [[[NSString alloc] initWithBytes:bytes length:length encoding:desiredEncoding] autorelease];
}

@end
#pragma mark Notes

/*if (isdigit(b->name[0])) {
char *status;
status = gaim_icq_status((b->uc & 0xffff0000) >> 16);
tmp = ret;
ret = g_strconcat(tmp, _("<b>Status:</b> "), status, "\n", NULL);
g_free(tmp);
g_free(status);
}

if ((bi != NULL) && (bi->ipaddr)) {
    char *tstr =  g_strdup_printf("%hhd.%hhd.%hhd.%hhd",
                                  (bi->ipaddr & 0xff000000) >> 24,
                                  (bi->ipaddr & 0x00ff0000) >> 16,
                                  (bi->ipaddr & 0x0000ff00) >> 8,
                                  (bi->ipaddr & 0x000000ff));
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>IP Address:</b> "), tstr, "\n", NULL);
    g_free(tmp);
    g_free(tstr);
}

if ((userinfo != NULL) && (userinfo->capabilities)) {
    char *caps = caps_string(userinfo->capabilities);
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>Capabilities:</b> "), caps, "\n", NULL);
    g_free(tmp);
}
*/

#if 0
//**Adium
GaimXfer *oscar_xfer_new(GaimConnection *gc, const char *destsn) {
	OscarData *od = (OscarData *)gc->proto_data;
	GaimXfer *xfer;
	struct aim_oft_info *oft_info;
	
	/* You want to send a file to someone else, you're so generous */
	
	/* Build the file transfer handle */
	xfer = gaim_xfer_new(gaim_connection_get_account(gc), GAIM_XFER_SEND, destsn);
	xfer->local_port = 5190;
	
	/* Create the oscar-specific data */
	oft_info = aim_oft_createinfo(od->sess, NULL, destsn, xfer->local_ip, xfer->local_port, 0, 0, NULL);
	xfer->data = oft_info;
	
	/* Setup our I/O op functions */
	gaim_xfer_set_init_fnc(xfer, oscar_xfer_init);
	gaim_xfer_set_start_fnc(xfer, oscar_xfer_start);
	gaim_xfer_set_end_fnc(xfer, oscar_xfer_end);
	gaim_xfer_set_cancel_send_fnc(xfer, oscar_xfer_cancel_send);
	gaim_xfer_set_cancel_recv_fnc(xfer, oscar_xfer_cancel_recv);
	gaim_xfer_set_ack_fnc(xfer, oscar_xfer_ack);
	
	/* Keep track of this transfer for later */
	od->file_transfers = g_slist_append(od->file_transfers, xfer);
	
	return xfer;
}
#endif