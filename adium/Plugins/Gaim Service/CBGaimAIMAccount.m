//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "CBGaimAIMAccount.h"
#import "aim.h"

#warning change this to your SN to connect :-)
#define SCREEN_NAME "tekjew"

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

@implementation CBGaimAIMAccount

- (void)initAccount
{
    NSLog(@"CBGaimAIMAccount initAccount");
    screenName = [NSString stringWithUTF8String:SCREEN_NAME];
    [super initAccount];
}

- (const char*)protocolPlugin
{
    return "prpl-oscar";
}

- (NSString *)UID{
    return([NSString stringWithUTF8String:SCREEN_NAME]);
}
    
- (NSString *)serviceID{
    return @"AIM";
}

- (NSString *)UIDAndServiceID{
    return [NSString stringWithFormat:@"%@.%@", [self serviceID], [self UID]]; 
}

- (NSString *)accountDescription
{
    return [self UIDAndServiceID];
}

- (NSArray *)supportedPropertyKeys
{
    return ([[super supportedPropertyKeys] arrayByAddingObjectsFromArray:
        [NSArray arrayWithObjects:
            @"TextProfile",
            nil]] );
}

/*
 - (void)accountBlistNewNode:(GaimBlistNode *)node 
 {
     [super accountBlistNewNode:node];
 }
 */
 

- (void)accountBlistUpdate:(GaimBuddyList *)list withNode:(GaimBlistNode *)node
{
    //General updates
    [super accountBlistUpdate:list withNode:node];
    
    if (node) {
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_delayedBlistUpdate:) userInfo:[NSValue valueWithPointer:node] repeats:NO];
    }
}

- (void)_delayedBlistUpdate:(NSTimer *)inTimer
{
    GaimBlistNode * node = [[inTimer userInfo] pointerValue];

    //AIM-specific updates
    
    if(node)
    {
        //extract the GaimBuddy from whatever we were passed
        GaimBuddy *buddy = nil;
        if(GAIM_BLIST_NODE_IS_BUDDY(node))
            buddy = (GaimBuddy *)node;
        else if(GAIM_BLIST_NODE_IS_CONTACT(node))
            buddy = ((GaimContact *)node)->priority;
        
        int online = (GAIM_BUDDY_IS_ONLINE(buddy) ? 1 : 0);
        
        NSMutableArray *modifiedKeys = [NSMutableArray array];
        AIHandle *theHandle = (AIHandle *)node->ui_data;
        NSMutableDictionary * statusDict = [theHandle statusDictionary];
//        NSLog(@"delayed for %@",[statusDict objectForKey:@"Display Name"]);
        if (online) {
            struct oscar_data *od = gc->proto_data;
            //            struct buddyinfo *bi = g_hash_table_lookup(od->buddyinfo, gaim_normalize(buddy->name));
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
                    }
                }
                
                //Set the signon date if one hasn't already been set
                if ( (![statusDict objectForKey:@"Signon Date"]) && ((userinfo->onlinesince) != 0) ) {
                    [statusDict setObject:[NSDate dateWithTimeIntervalSince1970:(userinfo->onlinesince)] forKey:@"Signon Date"];
                    [modifiedKeys addObject:@"Signon Date"];
                 }
            }
        }
        
        //if anything changed
        if([modifiedKeys count] > 0)
        {
            //NSLog(@"Changed %@", modifiedKeys);
            
            //tell the contact controller
            [[owner contactController] handleStatusChanged:theHandle
                                        modifiedStatusKeys:modifiedKeys
                                                   delayed:NO
                                                    silent:NO];
        }
    }
}

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