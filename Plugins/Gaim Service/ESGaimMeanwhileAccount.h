//
//  ESGaimMeanwhileAccount.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

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
