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

#import "CBGaimAccount.h"
#import <Libgaim/oscar.h>

@class AIHTMLDecoder;

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

//From oscar.c
#define OSCAR_STATUS_ID_INVISIBLE	"invisible"
#define OSCAR_STATUS_ID_OFFLINE		"offline"
#define OSCAR_STATUS_ID_AVAILABLE	"available"
#define OSCAR_STATUS_ID_AWAY		"away"
#define OSCAR_STATUS_ID_DND			"dnd"
#define OSCAR_STATUS_ID_NA			"na"
#define OSCAR_STATUS_ID_OCCUPIED	"occupied"
#define OSCAR_STATUS_ID_FREE4CHAT	"free4chat"
#define OSCAR_STATUS_ID_CUSTOM		"custom"

@class AIHTMLDecoder;

@interface CBGaimOscarAccount : CBGaimAccount  <AIAccount_Files> {
	AIHTMLDecoder	*oscarGaimThreadHTMLDecoder;
	
	NSTimer			*delayedSignonUpdateTimer;
	NSMutableArray  *arrayOfContactsForDelayedUpdates;
}

@end
