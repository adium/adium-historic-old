//
//  ESGaimGaduGaduAccount.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "CBGaimAccount.h"
#import "libgg.h"

#define KEY_GADU_GADU_HOST		@"Gadu-Gadu:Host"
#define KEY_GADU_GADU_PORT		@"Gadu-Gadu:Port"

struct agg_data {
	struct gg_session *sess;
	int own_status;
};

@interface ESGaimGaduGaduAccount : CBGaimAccount {
    
}

@end