//
//  ESGaimMeanwhileAccount.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.

#import "CBGaimAccount.h"

#define KEY_MEANWHILE_HOST				@"Meanwhile:Host"
#define KEY_MEANWHILE_PORT				@"Meanwhile:Port"

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
