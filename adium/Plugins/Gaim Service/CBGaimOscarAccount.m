//
//  CBGaimOscarAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Thu Nov 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimOscarAccount.h"
#import "aim.h"

#define OSCAR_DELAYED_UPDATE_INTERVAL   2

//From oscar.c
struct oscar_data {
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

@implementation CBGaimOscarAccount

- (void)initAccount
{
    [super initAccount];
}

- (const char*)protocolPlugin
{
    return "prpl-oscar";
}

- (NSArray *)supportedPropertyKeys
{
/*
 return ([[super supportedPropertyKeys] arrayByAddingObjectsFromArray:
        [NSArray arrayWithObjects:
            @"TextProfile",
            nil]] );
*/
    return [super supportedPropertyKeys];
}

- (id <AIAccountViewController>)accountView
{
    return nil;
}

/*
 - (void)accountBlistNewNode:(GaimBlistNode *)node 
 {
     [super accountBlistNewNode:node];
 }
 */
 

- (void)accountUpdateBuddy:(GaimBuddy*)buddy
{
    //General updates
    [super accountUpdateBuddy:buddy];
    
        [NSTimer scheduledTimerWithTimeInterval:OSCAR_DELAYED_UPDATE_INTERVAL target:self selector:@selector(_delayedBlistUpdate:) userInfo:[NSValue valueWithPointer:buddy] repeats:NO];
}

- (void)_delayedBlistUpdate:(NSTimer *)inTimer
{
    GaimBlistNode * node = [[inTimer userInfo] pointerValue];
    
    //AIM-specific updates
    
    if(node)
    {
        //extract the GaimBuddy from whatever we were passed - we should always get buddies, not contacts, in curent code
        //but it pays to be safe
        GaimBuddy *buddy = nil;
        if(GAIM_BLIST_NODE_IS_BUDDY(node)) {
            buddy = (GaimBuddy *)node;
        } else if(GAIM_BLIST_NODE_IS_CONTACT(node)) {
            buddy = ((GaimContact *)node)->priority;
        }
        
        if (buddy != nil) {
            int online = (GAIM_BUDDY_IS_ONLINE(buddy) ? 1 : 0);
            
            NSMutableArray *modifiedKeys = [NSMutableArray array];
            AIHandle *theHandle = (AIHandle *)node->ui_data;
            NSMutableDictionary * statusDict = [theHandle statusDictionary];
            
            if (online) {
                struct oscar_data *od = gc->proto_data;
                //            struct buddyinfo *bi = g_hash_table_lookup(od->buddyinfo, gaim_normalize(buddy->name));
                if (od != NULL) {
                    aim_userinfo_t *userinfo = aim_locate_finduserinfo(od->sess, buddy->name);
                    
                    if (userinfo != NULL) {
                        //Update the away message and status if the contact is away (userinfo->flags & AIM_FLAG_AWAY)
                        //EDS - optimize by keeping track of the string forms separately and comparing them rather than encoding/decoding html
                        if ((userinfo->flags & AIM_FLAG_AWAY) && (userinfo->away_len > 0) && (userinfo->away != NULL) && (userinfo->away_encoding != NULL)) {
                            //                    NSLog(@"%s",userinfo->away);
                            gchar *away_utf8 = oscar_encoding_to_utf8(userinfo->away_encoding, userinfo->away, userinfo->away_len);
                            if (away_utf8 != NULL) {
                                NSString * awayMessageString = [NSString stringWithUTF8String:away_utf8];
                                NSAttributedString * statusMsgDecoded = [AIHTMLDecoder decodeHTML:awayMessageString];
                                if (![statusMsgDecoded isEqualToAttributedString:[statusDict objectForKey:@"StatusMessage"]]) {
                                    [statusDict setObject:statusMsgDecoded forKey:@"StatusMessage"];
                                    [modifiedKeys addObject:@"StatusMessage"];
                                    [statusDict setObject:[NSNumber numberWithBool:YES] forKey:@"Away"];
                                    [modifiedKeys addObject:@"Away"];
                                }
                                g_free(away_utf8);
                            }
                        }else{ //remove any away message
                            if ([statusDict objectForKey:@"StatusMessage"]) {
                                [statusDict removeObjectForKey:@"StatusMessage"];
                                [modifiedKeys addObject:@"StatusMessage"];
                                [statusDict setObject:[NSNumber numberWithBool:NO] forKey:@"Away"];
                                [modifiedKeys addObject:@"Away"];
                            }
                        }
                        
                        //Update the profile if necessary
                        //EDS - optimize by keeping track of the string forms separately and comparing them rather than encoding/decoding html
                        if ((userinfo->info_len > 0) && (userinfo->info != NULL) && (userinfo->info_encoding != NULL)) {
                            gchar *info_utf8 = oscar_encoding_to_utf8(userinfo->info_encoding, userinfo->info, userinfo->info_len);
                            if (info_utf8 != NULL) {
                                NSAttributedString * profileDecoded = [AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String:info_utf8]];
                                if (![profileDecoded isEqualToAttributedString:[statusDict objectForKey:@"TextProfile"]]) {
                                    [statusDict setObject:profileDecoded forKey:@"TextProfile"];
                                    [modifiedKeys addObject:@"TextProfile"];
                                }
                                g_free(info_utf8);
                            }
                        }
                        
                        //Set the signon date if one hasn't already been set
                        if ( (![statusDict objectForKey:@"Signon Date"]) && ((userinfo->onlinesince) != 0) ) {
                            [statusDict setObject:[NSDate dateWithTimeIntervalSince1970:(userinfo->onlinesince)] forKey:@"Signon Date"];
                            [modifiedKeys addObject:@"Signon Date"];
                        }
                    }
                }
            }
            
            //if anything changed
            if([modifiedKeys count] > 0)
            {
                //tell the contact controller, silencing if necessary
                [[adium contactController] handleStatusChanged:theHandle
                                            modifiedStatusKeys:modifiedKeys
                                                        silent:silentAndDelayed];
            }
        }
    }
}

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

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type
{
    return [super addListObject:inObject toPrivacyList:type];
}
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type
{
    return [super removeListObject:inObject fromPrivacyList:type]; 
}
/*
//Creates the oscar xfer object, the ESFileTransfer object, and informs
- (void)initiateSendOfFile:(NSString *)filename toContact:(AIListContact *)inContact
{
    NSString * destination = [[inContact UID] compactedString];
    
    //gaim will do a g_free of xferFileName while executing gaim_xfer_request_accepted
    //so we need to malloc to prevent errors
    char * destsn = g_malloc(strlen([destination UTF8String]) * 4 + 1);
    [destination getCString:destsn];
     
    [filesToSendArray addObject:filename];
    
    oscar_ask_sendfile(gc,destsn);
}
*/


@end
/*if (isdigit(b->name[0])) {
char *status;
status = gaim_icq_status((b->uc & 0xffff0000) >> 16);
tmp = ret;
ret = g_strconcat(tmp, _("<b>Status:</b> "), status, "\n", NULL);
g_free(tmp);
g_free(status);
}

if (userinfo != NULL) {
    char *tstr = gaim_str_seconds_to_string(time(NULL) - userinfo->onlinesince +
                                            (gc->login_time_official ? gc->login_time_official - gc->login_time : 0));
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>Logged In:</b> "), tstr, "\n", NULL);
    g_free(tmp);
    g_free(tstr);
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
