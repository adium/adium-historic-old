//
//  ESGaimGaduGaduAccount.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "CBGaimAccount.h"
#import "libgg.h"

struct agg_data {
	struct gg_session *sess;
	int own_status;
};

@interface ESGaimGaduGaduAccount : CBGaimAccount {
    
}

@end