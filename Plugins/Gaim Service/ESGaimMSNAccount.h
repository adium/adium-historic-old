//
//  ESGaimMSNAccount.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimAccount.h"
#import "ESMSNService.h"
#include <Libgaim/msn.h>

#define KEY_MSN_HTTP_CONNECT_METHOD		@"MSN:HTTP Connect Method"


@interface ESGaimMSNAccount : CBGaimAccount <AIAccount_Files>{
	NSString	*currentFriendlyName;
	
	BOOL		displayNamesAsStatus;
	BOOL		displayConversationClosed;
	BOOL		displayConversationTimedOut;
}

@end
