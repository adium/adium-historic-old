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

#define	KEY_MEANWHILE_CONTACTLIST		@"Meanwhile:ContactList"

#define MW_PRPL_OPT_BLIST_ACTION		"/plugins/prpl/meanwhile/blist_action"

enum Meanwhile_CL_Choice {
	Meanwhile_CL_None = 1,
	Meanwhile_CL_Load = 2,
	Meanwhile_CL_Load_And_Save = 3
};

//From mwgaim.c
struct mw_plugin_data {
	struct mwSession *session;
	
	struct mwServiceAware *srvc_aware;
	
	struct mwServiceConf *srvc_conf;
	
	struct mwServiceIM *srvc_im;
	
	struct mwServiceStorage *srvc_store;
	
	GHashTable *list_map;
	GHashTable *convo_map;
	
	guint save_event;
};


//From libmeanwhile's common.h
enum mwAwareType {
	mwAware_USER  = 0x0002
};

struct mwAwareIdBlock {
	enum mwAwareType type;
	char *user;
	char *community;
};

@interface ESGaimMeanwhileAccount : CBGaimAccount {

}

@end
