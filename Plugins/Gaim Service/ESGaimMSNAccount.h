//
//  ESGaimMSNAccount.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimAccount.h"
#include <Libgaim/msn.h>

#define KEY_MSN_HTTP_CONNECT_METHOD		@"MSN:HTTP Connect Method"
#define	KEY_MSN_DISPLAY_NAMES_AS_STATUS	@"MSN:Display Names As Status"
#define	KEY_MSN_CONVERSATION_CLOSED		@"MSN:Conversation Closed"
#define	KEY_MSN_CONVERSATION_TIMED_OUT	@"MSN:Conversation Timed Out"

@interface ESGaimMSNAccount : CBGaimAccount <AIAccount_Files>{
	NSString	*currentFriendlyName;
	
	BOOL		displayNamesAsStatus;
	BOOL		displayConversationClosed;
	BOOL		displayConversationTimedOut;
}

@end
