//
//  CBGaimOscarAccount.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 06 2003.
//

#import "CBGaimOscarAccount.h"
#import <Libgaim/aim.h>

#define OSCAR_DELAYED_UPDATE_INTERVAL   3

#define KEY_OSCAR_HOST  @"Oscar:Host"
#define KEY_OSCAR_PORT  @"Oscar:Port"

//From oscar.c
typedef struct _OscarData OscarData;
struct _OscarData {
	aim_session_t *sess;
	aim_conn_t *conn;
	
	guint cnpa;
	guint paspa;
	guint emlpa;
	guint icopa;
	
	gboolean iconconnecting;
	gboolean set_icon;
	
	GSList *create_rooms;
	
	gboolean conf;
	gboolean reqemail;
	gboolean setemail;
	char *email;
	gboolean setnick;
	char *newsn;
	gboolean chpass;
	char *oldp;
	char *newp;
	
	GSList *oscar_chats;
	GSList *direct_ims;
	GSList *file_transfers;
	GHashTable *buddyinfo;
	GSList *requesticon;
	
	gboolean killme;
	gboolean icq;
	guint icontimer;
	guint getblisttimer;
	
	struct {
		guint maxwatchers; /* max users who can watch you */
		guint maxbuddies; /* max users you can watch */
		guint maxgroups; /* max groups in server list */
		guint maxpermits; /* max users on permit list */
		guint maxdenies; /* max users on deny list */
		guint maxsiglen; /* max size (bytes) of profile */
		guint maxawaymsglen; /* max size (bytes) of posted away message */
	} rights;
};

struct buddyinfo {
	gboolean typingnot;
	gchar *availmsg;
	fu32_t ipaddr;
	
	unsigned long ico_me_len;
	unsigned long ico_me_csum;
	time_t ico_me_time;
	gboolean ico_informed;
	
	unsigned long ico_len;
	unsigned long ico_csum;
	time_t ico_time;
	gboolean ico_need;
	gboolean ico_sent;
};

@interface CBGaimOscarAccount (PRIVATE)
-(NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding;
@end

@implementation CBGaimOscarAccount

- (const char*)protocolPlugin
{
    return "prpl-oscar";
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
- (void)accountUpdateBuddy:(GaimBuddy*)buddy forEvent:(GaimBuddyEvent)event
{
	[super accountUpdateBuddy:buddy forEvent:event];
	
	AIListContact           *theContact;
	OscarData				*od;
	aim_userinfo_t			*userinfo;
	
	if (buddy != nil) {
		//Get the node's ui_data
		theContact = (AIListContact *)buddy->node.ui_data;
		
		if (theContact &&
			GAIM_BUDDY_IS_ONLINE(buddy) && 
			(od = gc->proto_data) &&
			(userinfo = aim_locate_finduserinfo(od->sess, buddy->name))) {
			
			switch(event)
			{
				case GAIM_BUDDY_STATUS_MESSAGE:
				{
					NSString			*statusMsgString = nil;
					NSString			*oldStatusMsgString = [theContact statusObjectForKey:@"StatusMessageString"];
					
					struct buddyinfo	*bi = g_hash_table_lookup(od->buddyinfo, gaim_normalize(buddy->account, buddy->name));
					
					if ((bi != NULL) && (bi->availmsg != NULL) && !(buddy->uc & UC_UNAVAILABLE)) {
						
						//Available status message
						statusMsgString = [NSString stringWithUTF8String:(bi->availmsg)];
						
					} else if ((userinfo->flags & AIM_FLAG_AWAY) && (userinfo->away_len > 0) && 
							   (userinfo->away != NULL) && (userinfo->away_encoding != NULL)) {
						
						//Away message
						statusMsgString = [self stringWithBytes:userinfo->away
														 length:userinfo->away_len
													   encoding:userinfo->away_encoding];
						
						//If the away message changed, make sure the contact is marked as away
						BOOL		newAway;
						NSNumber	*storedValue;
						
						newAway =  ((buddy->uc & UC_UNAVAILABLE) != 0);
						storedValue = [theContact statusObjectForKey:@"Away"];
						if((!newAway && (storedValue == nil)) || newAway != [storedValue boolValue]) {
							[theContact setStatusObject:[NSNumber numberWithBool:newAway] forKey:@"Away" notify:NO];
						}
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
				}	break;
					
				case GAIM_BUDDY_INFO_UPDATED:
				{
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
				} break;
			
				case GAIM_BUDDY_MISCELLANEOUS:
				{  
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
						}
					} else {
						//Clear the client value if one was present before
						if (storedString)
							[theContact setStatusObject:nil forKey:@"Client" notify:NO];
					}
					
				}	break;
			}
		}
		
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
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
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
	//See if the super account can handle it
	BOOL returnValue = [super availableForSendingContentType:inType toListObject:inListObject];
	
	//If not, check if we can
	if (!returnValue) {
		BOOL	weAreOnline = [[self statusObjectForKey:@"Online"] boolValue];
		
		//Check their capabilities here?
		if([inType compare:FILE_TRANSFER_TYPE] == 0){
			if(weAreOnline && (inListObject == nil || [[inListObject statusObjectForKey:@"Online"] boolValue])){ 
				returnValue  = YES;
			}
		}
	}
	
	return returnValue;
}
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];

	GaimXfer *xfer = oscar_xfer_new(gc,destsn);
	
	//Associate the fileTransfer and the xfer with each other
	[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
    xfer->ui_data = [fileTransfer retain];
	
	//Set the filename
	gaim_xfer_set_local_filename(xfer, [[fileTransfer localFilename] UTF8String]);
		
    //request that the transfer begins
	gaim_xfer_request(xfer);

    //tell the fileTransferController to display appropriately
    [[adium fileTransferController] beganFileTransfer:fileTransfer];
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
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

-(NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding
{
	//Default to UTF8
	NSStringEncoding	desiredEncoding = NSUTF8StringEncoding;

	//Only attempt to check encoding if we were passed one
	if (encoding && (encoding[0] != '\0')){
		NSString			*encodingString = [NSString stringWithUTF8String:encoding];
				
		if ([encodingString rangeOfString:@"unicode-2-0"].location != NSNotFound){
			desiredEncoding = NSUnicodeStringEncoding;
		}else if ([encodingString rangeOfString:@"iso-8859-1"].location != NSNotFound){
			desiredEncoding = NSISOLatin1StringEncoding;
		}
	}
	
	//NSLog(@"[%s] [%i] [%s]",bytes,length,encoding);
	
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

if ((bi != NULL) && (bi->availmsg != NULL) && !(b->uc & UC_UNAVAILABLE)) {
    gchar *escaped = g_markup_escape_text(bi->availmsg, strlen(bi->availmsg));
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>Available:</b> "), escaped, "\n", NULL);
    g_free(tmp);
    g_free(escaped);
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