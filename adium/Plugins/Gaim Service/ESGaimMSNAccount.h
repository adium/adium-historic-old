//
//  ESGaimMSNAccount.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimAccount.h"
#include "msn.h"

@interface ESGaimMSNAccount : CBGaimAccount {

}

extern void msn_set_friendly_name(GaimConnection *gc, const char *entry);

@end
