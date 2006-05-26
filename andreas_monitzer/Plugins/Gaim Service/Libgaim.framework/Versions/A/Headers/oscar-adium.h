#include "internal.h"

#include "account.h"
#include "accountopt.h"
#include "buddyicon.h"
#include "cipher.h"
#include "conversation.h"
#include "core.h"
#include "debug.h"
#include "ft.h"
#include "imgstore.h"
#include "network.h"
#include "notify.h"
#include "privacy.h"
#include "prpl.h"
#include "proxy.h"
#include "request.h"
#include "util.h"
#include "version.h"

#include "oscar.h"

typedef struct _OscarData OscarData;
struct _OscarData {
	OscarSession *sess;
	OscarConnection *conn;
	
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
	guint getinfotimer;
	gint timeoffset;
	
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

void oscar_reformat_screenname(GaimConnection *gc, const char *nick);