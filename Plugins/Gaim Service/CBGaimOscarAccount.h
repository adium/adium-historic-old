/*
 *  CBGaimOscarAccount.h
 *  Adium
 *
 *  Created by Colin Barrett on Thu Nov 06 2003.
 *
 */

#import "CBGaimAccount.h"
#import <Libgaim/aim.h>

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

struct oscar_direct_im {
	GaimConnection *gc;
	char name[80];
	int watcher;
	aim_conn_t *conn;
	gboolean connected;
	gboolean gpc_pend;
	gboolean killme;
	gboolean donttryagain;
};

@interface CBGaimOscarAccount : CBGaimAccount <AIAccount_Files>
{
	NSTimer			*delayedSignonUpdateTimer;
	NSMutableArray  *arrayOfContactsForDelayedUpdates;

	AIHTMLDecoder *encoderCloseFontTagsAttachmentsAsText;
	AIHTMLDecoder *encoderCloseFontTags;
	AIHTMLDecoder *encoderAttachmentsAsText;
}

- (BOOL)useGaimUserInfo;

@end
